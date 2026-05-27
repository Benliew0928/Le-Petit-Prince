extends CharacterBody3D

## Fox NPC — The taming/patience mechanic.
##
## 5 Bond Stages: STRANGER → CURIOUS → FAMILIAR → FRIEND → TAMED
## Player must sit still (C key) nearby to build trust.
## Moving too close too fast makes the fox flee.

enum BondStage { STRANGER, CURIOUS, FAMILIAR, FRIEND, TAMED }
enum AIState { IDLE, ALERT, FLEEING, APPROACHING, FOLLOWING, TAMED_IDLE }

# ── Bond System ──
var bond_stage: BondStage = BondStage.STRANGER
var bond_points: float = 0.0
var _patience_timer: float = 0.0
var _patience_shown_line: bool = false

# ── AI ──
var ai_state: AIState = AIState.IDLE
var _home_position: Vector3 = Vector3.ZERO
var _flee_target: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _alert_timer: float = 0.0

# ── Stage thresholds ──
const STAGE_THRESHOLDS: Array = [20.0, 40.0, 60.0, 80.0, 100.0]

# ── Distance thresholds per stage (fox flees if player closer than this) ──
const FLEE_DISTANCES: Array = [8.0, 6.0, 4.0, 2.5, 0.0]

# ── Patience required per stage (seconds of sitting still) ──
const PATIENCE_REQUIRED: Array = [15.0, 20.0, 25.0, 30.0, 0.0]

# ── Movement ──
const WANDER_SPEED: float = 1.5
const FLEE_SPEED: float = 8.0
const FOLLOW_SPEED: float = 3.0
const APPROACH_SPEED: float = 1.0
const GRAVITY_STRENGTH: float = 25.0


func _ready() -> void:
	add_to_group("fox")
	add_to_group("interactable")
	_home_position = global_position
	# Orient to parent planet, not origin
	var pc: Vector3 = _get_nearest_planet_center()
	PlanetGravity.orient_to_surface(self, pc)


func _physics_process(delta: float) -> void:
	# ── Gravity — find nearest planet ──
	var planet_center: Vector3 = _get_nearest_planet_center()
	var gravity_dir: Vector3 = (planet_center - global_position).normalized()
	up_direction = -gravity_dir
	if not is_on_floor():
		velocity += gravity_dir * GRAVITY_STRENGTH * delta

	# ── Get player info ──
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		_do_wander(delta)
		move_and_slide()
		return

	var dist: float = global_position.distance_to(player.global_position)
	var player_sitting: bool = player.get("is_sitting") != null and player.is_sitting
	var flee_dist: float = FLEE_DISTANCES[bond_stage]

	# ── State machine ──
	match ai_state:
		AIState.IDLE:
			_do_wander(delta)
			# Check if player is close enough to trigger alert
			if dist < flee_dist + 5.0 and bond_stage < BondStage.TAMED:
				ai_state = AIState.ALERT
				_alert_timer = 0.0

		AIState.ALERT:
			_face_target(player.global_position, delta)
			_alert_timer += delta

			# Player too close → flee
			if dist < flee_dist and not player_sitting:
				_start_flee(player)
			# Player sitting nearby → start patience
			elif player_sitting and dist < flee_dist + 5.0:
				_patience_timer += delta
				if not _patience_shown_line and _patience_timer > 2.0:
					_patience_shown_line = true
					DialogueManager.show_dialogue([FoxDialogue.get_patience_line(bond_stage)])

				# Stage 2+: fox approaches sitting player
				if bond_stage >= BondStage.FAMILIAR and dist > flee_dist + 1.0:
					ai_state = AIState.APPROACHING

				# Check if patience requirement met
				var required: float = PATIENCE_REQUIRED[bond_stage]
				if required > 0.0 and _patience_timer >= required:
					_advance_bond()
			# Player walked away
			elif dist > flee_dist + 8.0:
				ai_state = AIState.IDLE
				_reset_patience()
			# Player stood up
			elif not player_sitting and _patience_timer > 0.0:
				_reset_patience()

		AIState.FLEEING:
			var flee_dir: Vector3 = (_flee_target - global_position)
			flee_dir = _project_on_surface(flee_dir)
			if flee_dir.length() > 0.5:
				var tangent_vel: Vector3 = flee_dir.normalized() * FLEE_SPEED
				velocity = tangent_vel + up_direction * velocity.dot(up_direction)
				_orient_to_direction(flee_dir, delta)
			else:
				ai_state = AIState.IDLE
				_reset_patience()

		AIState.APPROACHING:
			if not player_sitting:
				ai_state = AIState.ALERT
				_reset_patience()
			else:
				var approach_dist: float = flee_dist + 1.0
				if dist > approach_dist:
					var to_player: Vector3 = (player.global_position - global_position)
					to_player = _project_on_surface(to_player).normalized()
					var tangent_vel: Vector3 = to_player * APPROACH_SPEED
					velocity = tangent_vel + up_direction * velocity.dot(up_direction)
					_orient_to_direction(to_player, delta)
				else:
					_face_target(player.global_position, delta)
					# Stop tangential movement
					velocity = up_direction * velocity.dot(up_direction)

				# Keep building patience
				_patience_timer += delta
				var required: float = PATIENCE_REQUIRED[bond_stage]
				if required > 0.0 and _patience_timer >= required:
					_advance_bond()

		AIState.FOLLOWING:
			if dist > 5.0:
				var to_player: Vector3 = (player.global_position - global_position)
				to_player = _project_on_surface(to_player).normalized()
				var tangent_vel: Vector3 = to_player * FOLLOW_SPEED
				velocity = tangent_vel + up_direction * velocity.dot(up_direction)
				_orient_to_direction(to_player, delta)
			elif dist > 2.5:
				var to_player: Vector3 = (player.global_position - global_position)
				to_player = _project_on_surface(to_player).normalized()
				var tangent_vel: Vector3 = to_player * WANDER_SPEED
				velocity = tangent_vel + up_direction * velocity.dot(up_direction)
				_orient_to_direction(to_player, delta)
			else:
				_face_target(player.global_position, delta)
				velocity = up_direction * velocity.dot(up_direction)

		AIState.TAMED_IDLE:
			# Follow player closely
			if dist > 3.0:
				var to_player: Vector3 = (player.global_position - global_position)
				to_player = _project_on_surface(to_player).normalized()
				var tangent_vel: Vector3 = to_player * FOLLOW_SPEED
				velocity = tangent_vel + up_direction * velocity.dot(up_direction)
				_orient_to_direction(to_player, delta)
			else:
				_face_target(player.global_position, delta)
				velocity = up_direction * velocity.dot(up_direction)

	move_and_slide()


## Called when player presses E near the fox.
func interact() -> void:
	match bond_stage:
		BondStage.STRANGER, BondStage.CURIOUS:
			DialogueManager.show_dialogue([FoxDialogue.get_approach_line(bond_stage)])
		BondStage.FAMILIAR:
			DialogueManager.show_dialogue([FoxDialogue.get_approach_line(bond_stage)])
		BondStage.FRIEND:
			if _patience_timer >= PATIENCE_REQUIRED[bond_stage]:
				# Final taming moment
				bond_stage = BondStage.TAMED
				bond_points = 100.0
				ai_state = AIState.TAMED_IDLE
				DialogueManager.show_dialogue(FoxDialogue.farewell_speech)
			else:
				DialogueManager.show_dialogue([FoxDialogue.get_approach_line(bond_stage)])
		BondStage.TAMED:
			DialogueManager.show_dialogue([FoxDialogue.get_tamed_line()])


func get_interact_text() -> String:
	match bond_stage:
		BondStage.STRANGER:
			return "???"
		BondStage.CURIOUS:
			return "Press E to observe the fox"
		BondStage.FAMILIAR:
			return "Press E to talk to the fox"
		BondStage.FRIEND:
			if _patience_timer >= PATIENCE_REQUIRED[bond_stage]:
				return "Press E to tame the fox"
			return "Press E to talk to the fox"
		BondStage.TAMED:
			return "Press E to talk to the fox"
	return ""


func _advance_bond() -> void:
	if bond_stage >= BondStage.TAMED:
		return

	var old_stage := bond_stage
	bond_points = minf(100.0, bond_points + 20.0)

	# Check stage advancement
	for i in range(STAGE_THRESHOLDS.size()):
		if bond_points >= STAGE_THRESHOLDS[i]:
			bond_stage = i + 1 as BondStage

	if bond_stage != old_stage:
		_reset_patience()
		DialogueManager.show_dialogue([FoxDialogue.get_approach_line(bond_stage)])

		# Update AI behavior for new stage
		if bond_stage == BondStage.FRIEND:
			ai_state = AIState.FOLLOWING
		elif bond_stage == BondStage.TAMED:
			ai_state = AIState.TAMED_IDLE


func _start_flee(player: Node3D) -> void:
	ai_state = AIState.FLEEING
	_reset_patience()

	# Flee to opposite side of planet from player
	var pc: Vector3 = _get_nearest_planet_center()
	var away: Vector3 = (global_position - player.global_position).normalized()
	_flee_target = pc + away * 12.0  # planet radius offset from center

	# Show flee line (occasionally)
	if randf() < 0.4:
		DialogueManager.show_dialogue([FoxDialogue.get_flee_line()])


func _reset_patience() -> void:
	_patience_timer = 0.0
	_patience_shown_line = false


func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 5.0)
		# Random tangent direction on sphere surface
		var random_dir := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		_wander_dir = _project_on_surface(random_dir).normalized()

	if _wander_dir.length() > 0.1:
		var tangent_vel: Vector3 = _wander_dir * WANDER_SPEED
		velocity = tangent_vel + up_direction * velocity.dot(up_direction)
		_orient_to_direction(_wander_dir, delta)
	else:
		velocity = up_direction * velocity.dot(up_direction)


func _face_target(target_pos: Vector3, delta: float) -> void:
	var to_target: Vector3 = target_pos - global_position
	to_target = _project_on_surface(to_target)
	if to_target.length() > 0.1:
		_orient_to_direction(to_target, delta)


func _orient_to_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.01:
		return
	var look_pos := global_position + dir.normalized()
	look_at(look_pos, up_direction)
	global_basis = global_basis.orthonormalized()


func _project_on_surface(vec: Vector3) -> Vector3:
	return vec - up_direction * vec.dot(up_direction)


func _get_nearest_planet_center() -> Vector3:
	var best_dist: float = 9999.0
	var best_center: Vector3 = Vector3.ZERO
	for planet in get_tree().get_nodes_in_group("planet"):
		var dist: float = global_position.distance_to(planet.global_position)
		if dist < best_dist:
			best_dist = dist
			best_center = planet.global_position
	return best_center

extends CharacterBody3D

## Player Controller — Spherical Planet Movement + Multi-Planet Gravity
##
## WASD to move, Space to jump, E to interact, Q to drop, C to sit, V to toggle camera.
## Automatically gravitates toward the nearest planet.

@export var speed: float = 7.2
@export var jump_force: float = 8.8
@export var gravity_strength: float = 42.0
@export var turn_speed: float = 16.0
@export var ground_acceleration: float = 58.0
@export var ground_deceleration: float = 72.0
@export var air_acceleration: float = 18.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1
@export var grounded_snap_force: float = 3.5

## Planet center for spherical gravity — auto-detected from nearest planet.
var planet_center: Vector3 = Vector3.ZERO

## Indoor mode — set by house enter/exit scripts.
var is_indoors: bool = false

## Sitting — used by fox taming mechanic.
var is_sitting: bool = false

## Airplane state — set by airplane script.
var is_in_airplane: bool = false

## Interaction system
const INTERACT_RANGE := 2.5
var nearest_interactable: Node3D = null
var _hud = null
var _jump_buffer_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_was_down: bool = false


func _ready() -> void:
	add_to_group("player")
	await get_tree().process_frame
	_hud = get_tree().get_first_node_in_group("hud")


func _unhandled_input(event: InputEvent) -> void:
	if is_in_airplane or NavigationManager.is_map_open:
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		# ── Sit / Stand (C key) ──
		if event.keycode == KEY_C and not DialogueManager.is_active:
			get_viewport().set_input_as_handled()
			is_sitting = not is_sitting
			if is_sitting:
				var body := get_node_or_null("Body") as MeshInstance3D
				if body:
					var tween := create_tween()
					tween.tween_property(body, "scale:y", 0.5, 0.2)
					tween.parallel().tween_property(body, "position:y", 0.2, 0.2)
			else:
				var body := get_node_or_null("Body") as MeshInstance3D
				if body:
					var tween := create_tween()
					tween.tween_property(body, "scale:y", 1.0, 0.2)
					tween.parallel().tween_property(body, "position:y", 0.4, 0.2)
			return

		# ── Interact (E key) ──
		if event.keycode == KEY_E:
			if DialogueManager.is_active:
				return
			if is_sitting:
				is_sitting = false
				var body := get_node_or_null("Body") as MeshInstance3D
				if body:
					body.scale.y = 1.0
					body.position.y = 0.4
			if nearest_interactable == null and HeldItem.is_holding("wheat"):
				get_viewport().set_input_as_handled()
				HeldItem.consume()
				Hunger.eat()
				DialogueManager.show_dialogue([
					{"speaker": "", "text": "You ate the wheat. Hunger restored!"}
				])
				return
			if nearest_interactable != null:
				get_viewport().set_input_as_handled()
				nearest_interactable.interact()
				return

		# ── Drop held item (Q key) ──
		if event.keycode == KEY_Q and not HeldItem.is_empty():
			get_viewport().set_input_as_handled()
			var drop_pos := global_position
			if not is_indoors:
				var surface_dir := global_position.normalized()
				drop_pos = global_position - surface_dir * 0.3
			HeldItem.drop_at(drop_pos)


func _physics_process(delta: float) -> void:
	if is_in_airplane:
		return

	# ── Auto-detect nearest planet for gravity ──
	if not is_indoors:
		_update_planet_center()

	# ── Gravity ──
	var to_planet: Vector3 = planet_center - global_position
	if to_planet.length_squared() < 0.001:
		return
	var gravity_dir: Vector3 = to_planet.normalized()
	up_direction = -gravity_dir
	var grounded := is_on_floor()

	if grounded:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	var jump_down := Input.is_key_pressed(KEY_SPACE)
	if jump_down and not _jump_was_down and not DialogueManager.is_active and not is_sitting:
		_jump_buffer_timer = jump_buffer_time
	_jump_was_down = jump_down
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	if not grounded:
		velocity += gravity_dir * gravity_strength * delta
	else:
		var into_ground_speed := velocity.dot(gravity_dir)
		if into_ground_speed < grounded_snap_force:
			velocity += gravity_dir * grounded_snap_force

	# ── Input (frozen during dialogue, sitting, or map open) ──
	var raw_input := Vector2.ZERO
	if not DialogueManager.is_active and not is_sitting and not NavigationManager.is_map_open:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			raw_input.y += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			raw_input.y -= 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			raw_input.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			raw_input.x += 1.0
	raw_input = raw_input.limit_length(1.0)

	# ── Camera-relative movement on sphere surface ──
	var wish_dir := Vector3.ZERO
	var cam := get_viewport().get_camera_3d()

	if cam != null and raw_input.length_squared() > 0.001:
		var cam_fwd := -cam.global_basis.z
		var cam_right := cam.global_basis.x

		cam_fwd = _project_on_plane(cam_fwd, up_direction)
		cam_right = _project_on_plane(cam_right, up_direction)

		if cam_fwd.length_squared() > 0.001 and cam_right.length_squared() > 0.001:
			cam_fwd = cam_fwd.normalized()
			cam_right = cam_right.normalized()
			wish_dir = (cam_fwd * raw_input.y + cam_right * raw_input.x).normalized()

	# ── Apply movement with hunger speed modifier ──
	var v_normal := up_direction * velocity.dot(up_direction)
	var v_tangent := velocity - v_normal
	var current_speed := speed * Hunger.get_speed_multiplier()

	if wish_dir.length_squared() > 0.001:
		var accel := ground_acceleration if grounded else air_acceleration
		v_tangent = v_tangent.move_toward(wish_dir * current_speed, accel * delta)
	else:
		var decel := ground_deceleration if grounded else air_acceleration
		v_tangent = v_tangent.move_toward(Vector3.ZERO, decel * delta)

	velocity = v_tangent + v_normal

	# ── Jump (not while sitting or map open) ──
	if not DialogueManager.is_active and not is_sitting and not NavigationManager.is_map_open:
		if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
			_jump_buffer_timer = 0.0
			_coyote_timer = 0.0
			var downward_speed := velocity.dot(up_direction)
			if downward_speed < 0.0:
				velocity -= up_direction * downward_speed
			velocity += up_direction * jump_force

	# ── Orient ──
	_orient(wish_dir, delta)

	# ── Move ──
	move_and_slide()

	# ── Interaction ──
	_update_interaction()


## Find the nearest planet and set planet_center to its position.
func _update_planet_center() -> void:
	var best_dist: float = 9999.0
	var best_center: Vector3 = Vector3.ZERO
	for planet in get_tree().get_nodes_in_group("planet"):
		var dist: float = global_position.distance_to(planet.global_position)
		if dist < best_dist:
			best_dist = dist
			best_center = planet.global_position
	if best_dist < 9999.0:
		planet_center = best_center


func _project_on_plane(vec: Vector3, normal: Vector3) -> Vector3:
	return vec - normal * vec.dot(normal)


func _orient(wish_dir: Vector3, delta: float) -> void:
	var target_forward: Vector3
	if wish_dir.length_squared() > 0.001:
		target_forward = wish_dir
	else:
		target_forward = -global_basis.z
		target_forward = _project_on_plane(target_forward, up_direction)
		if target_forward.length_squared() < 0.001:
			return
		target_forward = target_forward.normalized()

	var look_pos := global_position + target_forward
	var old_basis := global_basis
	look_at(look_pos, up_direction)
	var target_basis := global_basis

	var blend: float
	if wish_dir.length_squared() > 0.001:
		blend = minf(1.0, turn_speed * delta)
	else:
		blend = minf(1.0, 15.0 * delta)

	global_basis = old_basis.slerp(target_basis, blend).orthonormalized()


func _update_interaction() -> void:
	nearest_interactable = null
	var best_dist := INTERACT_RANGE

	for node in get_tree().get_nodes_in_group("interactable"):
		var dist: float = global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			nearest_interactable = node

	if _hud != null:
		if nearest_interactable != null and not DialogueManager.is_active:
			if nearest_interactable.has_method("get_interact_text"):
				_hud.show_prompt(nearest_interactable.get_interact_text())
			else:
				_hud.show_prompt("Press E to interact")
		elif is_sitting:
			_hud.show_prompt("Sitting... (C to stand)")
		elif not HeldItem.is_empty() and not DialogueManager.is_active:
			if HeldItem.is_holding("wheat"):
				_hud.show_prompt("Press E to eat  |  Press Q to drop")
			else:
				_hud.show_prompt("Press Q to drop " + HeldItem.current_item_id.replace("_", " "))
		else:
			_hud.hide_prompt()

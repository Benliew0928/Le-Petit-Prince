extends CharacterBody3D

## Airplane — Fly between planets in the unified world.
##
## Controls:
##   W / S — accelerate / decelerate
##   A / D — turn left / right
##   Mouse — controls pitch and yaw (look direction = flight direction)
##   E — board (when parked) / land (when flying near a planet)

enum State { PARKED, FLYING }

var state: State = State.PARKED
var _pilot: Node3D = null

# ── Flight physics ──
@export var max_speed: float = 250.0
@export var acceleration: float = 100.0
@export var deceleration: float = 75.0
@export var mouse_yaw_speed: float = 0.002
@export var mouse_pitch_speed: float = 0.002
@export var key_turn_speed: float = 1.8
@export var drag: float = 0.1

var _current_speed: float = 0.0
var _yaw_input: float = 0.0
var _pitch_input: float = 0.0


func _ready() -> void:
	add_to_group("airplane")
	add_to_group("interactable")


func _physics_process(delta: float) -> void:
	match state:
		State.PARKED:
			_parked_physics(delta)
		State.FLYING:
			_flying_physics(delta)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.FLYING:
		# Mouse look → controls airplane direction
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_yaw_input -= event.relative.x * mouse_yaw_speed
			_pitch_input -= event.relative.y * mouse_pitch_speed

		# E to land
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_E:
				get_viewport().set_input_as_handled()
				_try_land()


func interact() -> void:
	if state == State.PARKED:
		_board()


func get_interact_text() -> String:
	if state == State.PARKED:
		return "Press E to board airplane"
	return ""


func _board() -> void:
	_pilot = get_tree().get_first_node_in_group("player")
	if _pilot == null:
		return

	state = State.FLYING
	_current_speed = 10.0  # Start with some speed
	_yaw_input = 0.0
	_pitch_input = 0.0

	# Hide player, disable player physics
	_pilot.set_physics_process(false)
	_pilot.visible = false
	_pilot.set("is_in_airplane", true)

	# Remove from interactable while flying
	remove_from_group("interactable")

	# Launch upward from planet surface
	var up_dir: Vector3 = (global_position - _get_nearest_planet_center()).normalized()
	global_position += up_dir * 3.0

	# Orient airplane to fly outward from planet
	var forward := up_dir
	var ref := Vector3.RIGHT
	if absf(forward.dot(ref)) > 0.9:
		ref = Vector3.FORWARD
	var right := forward.cross(ref).normalized()
	var true_up := right.cross(forward).normalized()
	global_basis = Basis(right, true_up, -forward).orthonormalized()

	DialogueManager.show_dialogue([
		{"speaker": "", "text": "W/S to speed up/slow down. A/D to turn. Mouse to steer. E to land."}
	])


func _try_land() -> void:
	var nearest := _find_nearest_planet()
	if nearest == null:
		return

	var dist: float = global_position.distance_to(nearest.global_position)
	var planet_radius: float = _get_planet_radius(nearest)

	if dist > planet_radius + 50.0:
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Too far from any planet to land."}
		])
		return

	# Land
	state = State.PARKED
	_current_speed = 0.0

	# Position airplane on planet surface
	var surface_dir: Vector3 = (global_position - nearest.global_position).normalized()
	global_position = nearest.global_position + surface_dir * (planet_radius + 0.5)

	# Orient flat on surface
	up_direction = surface_dir
	var ref := Vector3.FORWARD
	if absf(surface_dir.dot(ref)) > 0.9:
		ref = Vector3.RIGHT
	var right: Vector3 = surface_dir.cross(ref).normalized()
	var forward: Vector3 = right.cross(surface_dir).normalized()
	global_basis = Basis(right, surface_dir, -forward)

	# Show player next to airplane
	if _pilot != null:
		_pilot.global_position = global_position + surface_dir * 1.5 + forward * 1.0
		_pilot.visible = true
		_pilot.set_physics_process(true)
		_pilot.set("is_in_airplane", false)
		_pilot.set("planet_center", nearest.global_position)
		_pilot.velocity = Vector3.ZERO

		# Snap camera near player
		var cam := get_viewport().get_camera_3d()
		if cam != null:
			cam.global_position = _pilot.global_position + surface_dir * 12.0

	add_to_group("interactable")


func _parked_physics(delta: float) -> void:
	var nearest := _find_nearest_planet()
	if nearest == null:
		return
	var up_dir: Vector3 = (global_position - nearest.global_position).normalized()
	up_direction = up_dir
	if not is_on_floor():
		velocity = -up_dir * 10.0 * delta
	else:
		velocity = Vector3.ZERO
	move_and_slide()


func _flying_physics(delta: float) -> void:
	# ── Throttle: W accelerate, S decelerate ──
	if Input.is_key_pressed(KEY_W):
		_current_speed = minf(max_speed, _current_speed + acceleration * delta)
	elif Input.is_key_pressed(KEY_S):
		_current_speed = maxf(0.0, _current_speed - deceleration * delta)
	else:
		# Gentle drag when no input
		_current_speed = maxf(0.0, _current_speed - drag * delta)

	# ── Turning: A/D yaw, mouse also contributes ──
	var key_yaw: float = 0.0
	if Input.is_key_pressed(KEY_A):
		key_yaw += key_turn_speed * delta
	if Input.is_key_pressed(KEY_D):
		key_yaw -= key_turn_speed * delta

	# Apply yaw (keys + mouse)
	var total_yaw: float = key_yaw + _yaw_input
	if absf(total_yaw) > 0.0001:
		rotate(global_basis.y, total_yaw)

	# Apply pitch (mouse only)
	if absf(_pitch_input) > 0.0001:
		rotate(global_basis.x, _pitch_input)

	# Consume mouse input
	_yaw_input = 0.0
	_pitch_input = 0.0

	# ── Move forward ──
	var forward: Vector3 = -global_basis.z
	global_position += forward * _current_speed * delta

	# ── Keep pilot at airplane position ──
	if _pilot != null:
		_pilot.global_position = global_position

	# ── Spin propeller visual ──
	var prop := get_node_or_null("Propeller") as MeshInstance3D
	if prop and _current_speed > 1.0:
		prop.rotate_z(_current_speed * 0.5 * delta)

	# ── Banking animation (tilt wings into turns) ──
	var target_roll: float = -total_yaw * 15.0  # Bank into turn
	var fuselage := get_node_or_null("Fuselage") as MeshInstance3D
	if fuselage:
		fuselage.rotation.z = lerpf(fuselage.rotation.z, clampf(target_roll, -0.4, 0.4), 5.0 * delta)
	var wing_upper := get_node_or_null("WingUpper") as MeshInstance3D
	if wing_upper:
		wing_upper.rotation.z = lerpf(wing_upper.rotation.z, clampf(target_roll, -0.4, 0.4), 5.0 * delta)
	var wing_lower := get_node_or_null("WingLower") as MeshInstance3D
	if wing_lower:
		wing_lower.rotation.z = lerpf(wing_lower.rotation.z, clampf(target_roll, -0.4, 0.4), 5.0 * delta)


func _find_nearest_planet() -> Node3D:
	var best_node: Node3D = null
	var best_dist: float = 9999.0
	for planet in get_tree().get_nodes_in_group("planet"):
		var dist: float = global_position.distance_to(planet.global_position)
		if dist < best_dist:
			best_dist = dist
			best_node = planet
	return best_node


func _get_nearest_planet_center() -> Vector3:
	var nearest := _find_nearest_planet()
	if nearest != null:
		return nearest.global_position
	return Vector3.ZERO


func _get_planet_radius(planet: Node3D) -> float:
	if planet.has_meta("radius"):
		return planet.get_meta("radius")
	for child in planet.get_children():
		if child is CollisionShape3D and child.shape is SphereShape3D:
			return child.shape.radius
	return 8.0

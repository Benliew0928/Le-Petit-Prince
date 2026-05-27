extends Camera3D

## Orbit Camera — Third-person / First-person / Airplane chase camera.
##
## V key toggles between first-person and third-person (on foot).
## When in airplane, switches to a locked chase camera behind the plane.
## First-person uses player's facing direction as base, with mouse pitch offset.

enum ViewMode { THIRD_PERSON, FIRST_PERSON }

@export var target_path: NodePath
@export var distance: float = 8.5
@export var height: float = 1.35
@export var mouse_sensitivity: float = 0.003
@export var follow_speed: float = 9.5
@export var auto_follow_speed: float = 2.2
@export var manual_orbit_grace: float = 1.4
@export var collision_radius: float = 0.35
@export var min_collision_distance: float = 2.4

var view_mode: ViewMode = ViewMode.THIRD_PERSON
var _target: Node3D
var _yaw_delta: float = 0.0
var _pitch: float = 0.35
var _manual_orbit_timer: float = 0.0

# First-person: track look direction as a persistent vector
var _fp_look_dir: Vector3 = Vector3.FORWARD
var _fp_pitch_angle: float = 0.0

# Keep track of state transitions to dynamically update airplane mesh visibility
var _last_is_in_airplane: bool = false
var _last_view_mode: ViewMode = ViewMode.THIRD_PERSON


func _ready() -> void:
	_target = get_node_or_null(target_path)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	top_level = true


func _unhandled_input(event: InputEvent) -> void:
	# Don't process camera input when in airplane (except escape and view toggle)
	if _target and _target.get("is_in_airplane") and _target.is_in_airplane:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_ESCAPE:
				_toggle_mouse_capture()
			elif event.keycode == KEY_V:
				if view_mode == ViewMode.THIRD_PERSON:
					view_mode = ViewMode.FIRST_PERSON
				else:
					view_mode = ViewMode.THIRD_PERSON
		return

	# ── Toggle view mode (V key) ──
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_V:
			get_viewport().set_input_as_handled()
			if view_mode == ViewMode.THIRD_PERSON:
				view_mode = ViewMode.FIRST_PERSON
				# Initialize FP look from current player facing
				if _target:
					_fp_look_dir = -_target.global_basis.z
					_fp_pitch_angle = 0.0
					for child in _target.get_children():
						if child is MeshInstance3D:
							child.visible = false
			else:
				view_mode = ViewMode.THIRD_PERSON
				if _target:
					for child in _target.get_children():
						if child is MeshInstance3D:
							child.visible = true

	# ── Mouse input ──
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		match view_mode:
			ViewMode.THIRD_PERSON:
				_yaw_delta -= event.relative.x * mouse_sensitivity
				_pitch = clampf(_pitch + event.relative.y * mouse_sensitivity, -0.3, 1.2)
				_manual_orbit_timer = manual_orbit_grace
			ViewMode.FIRST_PERSON:
				# Rotate look direction around player's up (yaw)
				var up: Vector3 = _get_up(_target) if _target else Vector3.UP
				var yaw_amount: float = -event.relative.x * mouse_sensitivity
				_fp_look_dir = _fp_look_dir.rotated(up, yaw_amount).normalized()
				# Pitch
				_fp_pitch_angle = clampf(_fp_pitch_angle - event.relative.y * mouse_sensitivity, -1.2, 1.2)

	# ── Scroll zoom (third-person only) ──
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				distance = maxf(5.0, distance - 1.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = minf(30.0, distance + 1.0)

	# ── Toggle mouse capture ──
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_mouse_capture()


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	_manual_orbit_timer = maxf(0.0, _manual_orbit_timer - delta)

	# ── Track state transitions to update airplane mesh visibility ──
	var current_in_airplane: bool = _target.get("is_in_airplane") == true
	if current_in_airplane != _last_is_in_airplane or view_mode != _last_view_mode:
		_last_is_in_airplane = current_in_airplane
		_last_view_mode = view_mode
		_update_airplane_mesh_visibility()

	# ── Airplane mode: locked chase camera or cockpit view ──
	if _target.get("is_in_airplane") != null and _target.is_in_airplane:
		if view_mode == ViewMode.FIRST_PERSON:
			_process_first_person_airplane(delta)
		else:
			_process_airplane_camera(delta)
		return

	# ── On-foot modes ──
	match view_mode:
		ViewMode.THIRD_PERSON:
			_process_third_person(delta)
		ViewMode.FIRST_PERSON:
			_process_first_person(delta)


func _process_first_person_airplane(delta: float) -> void:
	var airplane = get_tree().get_first_node_in_group("airplane")
	if airplane == null:
		return
	
	var cockpit = airplane.get_node_or_null("CockpitCameraPos")
	if cockpit:
		# Snap directly to cockpit position to prevent drifting/lagging behind when the plane is moving fast
		global_position = cockpit.global_position
		
		var plane_up: Vector3 = airplane.global_basis.y
		var plane_back: Vector3 = airplane.global_basis.z
		var look_target: Vector3 = global_position - plane_back * 5.0
		
		look_at(look_target, plane_up)


func _process_airplane_camera(delta: float) -> void:
	var airplane = get_tree().get_first_node_in_group("airplane")
	if airplane == null:
		return
	var plane_back: Vector3 = airplane.global_basis.z
	var plane_up: Vector3 = airplane.global_basis.y

	var desired_pos: Vector3 = airplane.global_position + plane_back * 8.0 + plane_up * 3.0
	global_position = global_position.lerp(desired_pos, 8.0 * delta)

	var look_target: Vector3 = airplane.global_position - plane_back * 5.0
	look_at(look_target, plane_up)


func _process_third_person(delta: float) -> void:
	var player_pos: Vector3 = _target.global_position
	var up: Vector3 = _get_up(_target)

	var to_cam: Vector3 = global_position - player_pos
	var to_cam_tangent: Vector3 = to_cam - up * to_cam.dot(up)

	var ref_back: Vector3
	var ref_right: Vector3

	if to_cam_tangent.length() > 0.5:
		ref_back = to_cam_tangent.normalized()
		ref_right = up.cross(ref_back).normalized()
	else:
		var fallback := Vector3.FORWARD
		if absf(up.dot(fallback)) > 0.9:
			fallback = Vector3.RIGHT
		ref_back = (fallback - up * fallback.dot(up)).normalized()
		ref_right = up.cross(ref_back).normalized()

	if absf(_yaw_delta) > 0.0001:
		ref_back = (ref_back * cos(_yaw_delta) + ref_right * sin(_yaw_delta)).normalized()
		_yaw_delta = 0.0
	elif _manual_orbit_timer <= 0.0 and _target.get("velocity") != null:
		var target_velocity: Vector3 = _target.velocity
		var tangent_velocity := target_velocity - up * target_velocity.dot(up)
		if tangent_velocity.length() > 1.25:
			var desired_back := -tangent_velocity.normalized()
			ref_back = ref_back.slerp(desired_back, minf(1.0, auto_follow_speed * delta)).normalized()

	var orbit_dir: Vector3 = (ref_back * cos(_pitch) + up * sin(_pitch)).normalized()
	var desired_pos: Vector3 = player_pos + orbit_dir * distance + up * height
	desired_pos = _resolve_camera_collision(player_pos + up * 1.2, desired_pos)

	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	var look_target: Vector3 = player_pos + up * 1.5
	look_at(look_target, up)


func _process_first_person(delta: float) -> void:
	var up: Vector3 = _get_up(_target)

	# Position at player head
	var head_pos: Vector3 = _target.global_position + up * 0.9
	global_position = head_pos

	# Keep look_dir projected onto the surface tangent plane
	_fp_look_dir = (_fp_look_dir - up * _fp_look_dir.dot(up))
	if _fp_look_dir.length() < 0.01:
		_fp_look_dir = -_target.global_basis.z
		_fp_look_dir = (_fp_look_dir - up * _fp_look_dir.dot(up))
	_fp_look_dir = _fp_look_dir.normalized()

	# Build right vector
	var right: Vector3 = _fp_look_dir.cross(up).normalized()

	# Apply pitch
	var look_dir: Vector3 = (_fp_look_dir * cos(_fp_pitch_angle) + up * sin(_fp_pitch_angle)).normalized()

	look_at(global_position + look_dir, up)


func _get_up(node: Node3D) -> Vector3:
	if node == null:
		return Vector3.UP
	if node.get("up_direction") != null:
		return node.up_direction
	var pos_up := node.global_position.normalized()
	if pos_up.length() < 0.1:
		return Vector3.UP
	return pos_up


func _resolve_camera_collision(focus: Vector3, desired_pos: Vector3) -> Vector3:
	if _target == null or get_world_3d() == null:
		return desired_pos
	var to_camera := desired_pos - focus
	var desired_distance := to_camera.length()
	if desired_distance < 0.01:
		return desired_pos

	var query := PhysicsRayQueryParameters3D.create(focus, desired_pos)
	query.exclude = [_target.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return desired_pos

	var safe_distance = maxf(min_collision_distance, focus.distance_to(hit.position) - collision_radius)
	safe_distance = minf(safe_distance, desired_distance)
	return focus + to_camera.normalized() * safe_distance


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update_airplane_mesh_visibility() -> void:
	var airplane = get_tree().get_first_node_in_group("airplane")
	if airplane == null:
		return
	
	var is_piloting_first_person: bool = false
	if _target and _target.get("is_in_airplane") and _target.is_in_airplane:
		if view_mode == ViewMode.FIRST_PERSON:
			is_piloting_first_person = true
	
	var fuselage = airplane.get_node_or_null("Fuselage")
	if fuselage:
		fuselage.visible = not is_piloting_first_person
		
	var wing_upper = airplane.get_node_or_null("WingUpper")
	if wing_upper:
		wing_upper.visible = not is_piloting_first_person

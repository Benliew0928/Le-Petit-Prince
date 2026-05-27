extends Node3D
class_name PlanetSun

## PlanetSun — Rotates a local sun around a planet and exposes day/night state.
##
## The sun orbits the planet, creating sunrise/sunset cycles.
## The SkyManager reads the sun position to update the global sky and lighting.

@export var day_length: float = 24.0      # Total cycle time (full orbit) in seconds
@export var orbit_axis: Vector3 = Vector3.RIGHT
@export var local_light_path: NodePath = NodePath("LocalSun")

## Public state
var is_day: bool = true
var time_since_flip: float = 0.0
var sun_altitude: float = 0.0  # -1 (below) to +1 (above) relative to planet "up"

var _time: float = 0.0
var _local_light: Light3D = null
var _sun_mesh: MeshInstance3D = null

# Base energy of the local light (set from scene)
var _base_energy: float = 2.6


func _ready() -> void:
	rotation = Vector3.ZERO

	# Cache the local sun light
	if not local_light_path.is_empty():
		_local_light = get_node_or_null(local_light_path) as Light3D
	else:
		# Try to find a Light3D child
		for child in get_children():
			if child is Light3D:
				_local_light = child
				break

	if _local_light:
		_base_energy = _local_light.light_energy
		# Find the sun mesh (child of the light)
		for child in _local_light.get_children():
			if child is MeshInstance3D:
				_sun_mesh = child
				break


func _process(delta: float) -> void:
	var speed: float = (2.0 * PI) / day_length
	_time += delta

	# Rotate the sun pivot around the designated axis
	rotate(orbit_axis.normalized(), speed * delta)

	# Calculate the sun's position relative to the planet center
	var planet: Node3D = get_parent() as Node3D
	if planet == null:
		return

	var planet_center: Vector3 = planet.global_position

	if _local_light:
		var sun_pos: Vector3 = _local_light.global_position
		var sun_dir: Vector3 = (sun_pos - planet_center).normalized()

		# Use a fixed "up" reference based on the planet's position in world space
		# For planets at origin, use Y up; otherwise use the planet center direction
		var reference_up: Vector3
		if planet_center.length() < 1.0:
			reference_up = Vector3.UP
		else:
			reference_up = planet_center.normalized()

		# Calculate altitude: how high the sun is relative to the planet's "up" hemisphere
		sun_altitude = sun_dir.dot(reference_up)

		# Determine day/night
		var was_day: bool = is_day
		is_day = (sun_altitude > -0.05)  # Small threshold for smooth transition

		if is_day != was_day:
			time_since_flip = 0.0
		else:
			time_since_flip += delta

		# Modulate local light energy based on altitude
		# The local light dims when below horizon and brightens when above
		var energy_mult: float = clampf(remap(sun_altitude, -0.2, 0.15, 0.0, 1.0), 0.0, 1.0)
		_local_light.light_energy = _base_energy * energy_mult

		# Shift local light color with altitude
		var day_color := Color(1.0, 0.95, 0.85)
		var sunset_color := Color(1.0, 0.5, 0.15)
		var night_color := Color(0.2, 0.25, 0.5)

		var light_color: Color
		if sun_altitude > 0.2:
			light_color = day_color
		elif sun_altitude > 0.0:
			var t: float = sun_altitude / 0.2
			light_color = sunset_color.lerp(day_color, t)
		elif sun_altitude > -0.1:
			var t: float = (sun_altitude + 0.1) / 0.1
			light_color = night_color.lerp(sunset_color, t)
		else:
			light_color = night_color

		_local_light.light_color = light_color
	else:
		# Fallback: check the sun's hemisphere using the local Z axis in global space
		var sun_dir: Vector3 = global_basis.z
		var was_day: bool = is_day
		is_day = (sun_dir.y > 0.0)
		sun_altitude = sun_dir.y

		if is_day != was_day:
			time_since_flip = 0.0
		else:
			time_since_flip += delta


func get_sun_world_direction() -> Vector3:
	## Returns the direction FROM the planet center TO the sun, in world space.
	if _local_light == null:
		return global_basis.z
	var planet: Node3D = get_parent() as Node3D
	if planet == null:
		return global_basis.z
	return (_local_light.global_position - planet.global_position).normalized()

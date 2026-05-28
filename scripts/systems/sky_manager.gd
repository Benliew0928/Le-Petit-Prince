extends Node

## SkyManager — Dynamic sky & lighting controller.
##
## Finds the nearest planet's SunPivot and reads its sun direction,
## then updates the sky shader, ambient light, and global directional light
## to create realistic sunrise/sunset/night transitions.

# ── Cached references ──
var _world_env: WorldEnvironment = null
var _sun_light: DirectionalLight3D = null
var _fill_light: DirectionalLight3D = null
var _sky_material: ShaderMaterial = null
var _environment: Environment = null
var _player: Node3D = null

# ── Current state ──
var _current_sun_pivot: Node3D = null
var _sun_altitude: float = 0.0  # -1 (nadir) to +1 (zenith)

# ── Color ramps for time-of-day ──
# Sun light color at different altitudes
const SUN_COLORS := {
	-1.0: Color(0.05, 0.05, 0.15),   # Deep night: very dim blue
	-0.15: Color(0.15, 0.05, 0.08),   # Pre-dawn: deep crimson
	-0.05: Color(0.8, 0.2, 0.05),     # Sunrise: deep orange-red
	0.0: Color(1.0, 0.45, 0.1),       # Horizon: warm orange
	0.1: Color(1.0, 0.7, 0.35),       # Low sun: golden
	0.3: Color(1.0, 0.85, 0.65),      # Mid-morning: warm white
	0.6: Color(1.0, 0.95, 0.88),      # High noon: bright warm white
	1.0: Color(1.0, 0.97, 0.92),      # Zenith: near-white
}

const AMBIENT_COLORS := {
	-1.0: Color(0.18, 0.22, 0.35),    # Night: brighter moonlit evening blue (+30%)
	-0.1: Color(0.20, 0.15, 0.22),    # Pre-dawn: lighter purple
	0.0: Color(0.35, 0.20, 0.15),     # Sunrise: warm dark
	0.2: Color(0.40, 0.32, 0.25),     # Morning: warm ambient
	0.5: Color(0.45, 0.42, 0.38),     # Day: neutral warm
	1.0: Color(0.5, 0.48, 0.42),      # Full day: bright ambient
}

const SUN_ENERGY_CURVE := {
	-1.0: 0.0,       # Night: no sun
	-0.15: 0.0,      # Deep below horizon
	-0.05: 0.05,     # Just below horizon: faint glow
	0.0: 0.25,       # At horizon: dim
	0.1: 0.55,       # Low: moderate
	0.3: 0.72,       # Mid: strong
	0.6: 0.82,       # High: full
	1.0: 0.85,       # Zenith: maximum
}

const AMBIENT_ENERGY_CURVE := {
	-1.0: 0.48,      # Night: much brighter evening feel (+30%)
	-0.05: 0.52,     # Pre-dawn
	0.0: 0.55,       # Sunrise
	0.2: 0.60,       # Morning
	0.5: 0.52,       # Day
	1.0: 0.55,       # Full day
}

# Glow intensity based on sun altitude
const GLOW_CURVE := {
	-1.0: 0.15,      # Night: subtle star glow
	-0.05: 0.25,     # Dawn: awakening glow
	0.0: 0.55,       # Horizon: dramatic bloom
	0.1: 0.45,       # Low sun: strong bloom
	0.3: 0.35,       # Mid: moderate
	1.0: 0.3,        # Day: calm
}


func _ready() -> void:
	# Wait a frame for the scene tree to be fully ready
	await get_tree().process_frame
	_cache_references()


func _process(_delta: float) -> void:
	if _world_env == null or _sun_light == null:
		_cache_references()
		if _world_env == null:
			return

	# Find the nearest planet's sun pivot
	_update_current_sun_pivot()

	if _current_sun_pivot == null:
		return

	# Calculate sun altitude relative to the planet
	_update_sun_altitude()

	# Update all systems
	_update_sky_shader()
	_update_directional_light()
	_update_ambient_light()
	_update_glow()


func _cache_references() -> void:
	_world_env = _find_node_of_type(get_tree().current_scene, "WorldEnvironment") as WorldEnvironment
	if _world_env and _world_env.environment:
		_environment = _world_env.environment
		if _environment.sky and _environment.sky.sky_material is ShaderMaterial:
			_sky_material = _environment.sky.sky_material as ShaderMaterial

	# Find the global sun light (DirectionalLight3D named "SunLight")
	_sun_light = get_tree().current_scene.get_node_or_null("SunLight") as DirectionalLight3D
	_fill_light = get_tree().current_scene.get_node_or_null("FillLight") as DirectionalLight3D

	# Find the player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found := _find_node_of_type(child, type_name)
		if found != null:
			return found
	return null


func _update_current_sun_pivot() -> void:
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
		else:
			return

	# Find the nearest planet and its sun pivot
	var best_dist := 99999.0
	var best_pivot: Node3D = null
	var best_planet: Node3D = null

	for planet in get_tree().get_nodes_in_group("planet"):
		var dist: float = _player.global_position.distance_to(planet.global_position)
		if dist < best_dist:
			best_dist = dist
			best_planet = planet
			# Look for a SunPivot child
			var pivot := planet.get_node_or_null("SunPivot") as Node3D
			if pivot != null:
				best_pivot = pivot

	_current_sun_pivot = best_pivot


func _update_sun_altitude() -> void:
	if _current_sun_pivot == null:
		return

	# Get the sun's local light position
	var local_sun: Node3D = null
	for child in _current_sun_pivot.get_children():
		if child is Light3D:
			local_sun = child
			break
		# Also check for a named child
		var named := _current_sun_pivot.get_node_or_null("LocalSun")
		if named != null:
			local_sun = named
			break

	if local_sun == null:
		return

	# Get the planet center (parent of sun pivot)
	var planet: Node3D = _current_sun_pivot.get_parent() as Node3D
	if planet == null:
		return

	var planet_center: Vector3 = planet.global_position

	# Sun altitude = dot product of (sun direction from planet) and (player direction from planet)
	var sun_dir: Vector3 = (local_sun.global_position - planet_center).normalized()
	var player_dir: Vector3 = (_player.global_position - planet_center).normalized()

	# The "altitude" is how high the sun appears from the player's perspective on the surface
	# Positive = sun is above the player's horizon, negative = below
	_sun_altitude = sun_dir.dot(player_dir)

	# Also compute the sun direction in world space for the sky shader
	var sun_world_dir: Vector3 = (local_sun.global_position - _player.global_position).normalized()

	# Update the global directional light to match the local sun direction
	if _sun_light:
		# Point the directional light FROM the sun direction
		var target_pos: Vector3 = _sun_light.global_position - sun_world_dir
		var up_hint: Vector3 = Vector3.UP
		if absf(sun_world_dir.dot(up_hint)) > 0.99:
			up_hint = Vector3.RIGHT
		_sun_light.look_at(target_pos, up_hint)


func _update_sky_shader() -> void:
	if _sky_material == null:
		return

	if _current_sun_pivot == null:
		return

	# Get the sun's world position relative to player
	var local_sun: Node3D = _current_sun_pivot.get_node_or_null("LocalSun")
	if local_sun == null:
		return

	var sun_world_dir: Vector3 = (local_sun.global_position - _player.global_position).normalized()

	# Update sky shader uniforms
	_sky_material.set_shader_parameter("sun_direction", sun_world_dir)

	# Sun energy in sky based on altitude
	var sky_sun_energy: float = _sample_curve(SUN_ENERGY_CURVE, _sun_altitude) * 3.0
	_sky_material.set_shader_parameter("sun_energy", sky_sun_energy)

	# Tint the sky sun color
	var sun_col: Color = _sample_color_ramp(SUN_COLORS, _sun_altitude)
	_sky_material.set_shader_parameter("sun_color", sun_col)

	# Stars are brighter when the sun is lower
	var star_brightness: float = clampf(remap(_sun_altitude, -0.2, 0.15, 1.2, 0.0), 0.0, 1.2)
	_sky_material.set_shader_parameter("star_brightness", star_brightness)

	# Nebulae are visible at night
	var nebula_vis: float = clampf(remap(_sun_altitude, -0.1, 0.2, 0.5, 0.0), 0.0, 0.5)
	_sky_material.set_shader_parameter("nebula_intensity", nebula_vis)


func _update_directional_light() -> void:
	if _sun_light == null:
		return

	var sun_color: Color = _sample_color_ramp(SUN_COLORS, _sun_altitude)
	var sun_energy: float = _sample_curve(SUN_ENERGY_CURVE, _sun_altitude)

	_sun_light.light_color = sun_color
	_sun_light.light_energy = sun_energy

	# Fill light: cool blue, opposite of sun, dimmer at night
	if _fill_light:
		var fill_energy: float = clampf(remap(_sun_altitude, -0.2, 0.3, 0.22, 0.35), 0.22, 0.35)
		_fill_light.light_energy = fill_energy
		# Shift fill from deep blue (night) to subtle blue-grey (day)
		var fill_color := Color(0.45, 0.50, 0.85).lerp(Color(0.48, 0.56, 0.76), clampf(_sun_altitude + 0.5, 0.0, 1.0))
		_fill_light.light_color = fill_color


func _update_ambient_light() -> void:
	if _environment == null:
		return

	var ambient_color: Color = _sample_color_ramp(AMBIENT_COLORS, _sun_altitude)
	var ambient_energy: float = _sample_curve(AMBIENT_ENERGY_CURVE, _sun_altitude)

	_environment.ambient_light_color = ambient_color
	_environment.ambient_light_energy = ambient_energy


func _update_glow() -> void:
	if _environment == null:
		return

	var glow_intensity: float = _sample_curve(GLOW_CURVE, _sun_altitude)
	_environment.glow_intensity = glow_intensity


## Sample a value from a curve defined as a Dictionary of { key: value } pairs.
## Keys are sorted, and values are linearly interpolated between them.
func _sample_curve(curve: Dictionary, t: float) -> float:
	var keys: Array = curve.keys()
	keys.sort()

	if t <= keys[0]:
		return curve[keys[0]]
	if t >= keys[keys.size() - 1]:
		return curve[keys[keys.size() - 1]]

	for i in range(keys.size() - 1):
		if t >= keys[i] and t <= keys[i + 1]:
			var local_t: float = (t - keys[i]) / (keys[i + 1] - keys[i])
			return lerpf(curve[keys[i]], curve[keys[i + 1]], local_t)

	return curve[keys[keys.size() - 1]]


## Sample a Color from a color ramp defined as a Dictionary of { key: Color } pairs.
func _sample_color_ramp(ramp: Dictionary, t: float) -> Color:
	var keys: Array = ramp.keys()
	keys.sort()

	if t <= keys[0]:
		return ramp[keys[0]]
	if t >= keys[keys.size() - 1]:
		return ramp[keys[keys.size() - 1]]

	for i in range(keys.size() - 1):
		if t >= keys[i] and t <= keys[i + 1]:
			var local_t: float = (t - keys[i]) / (keys[i + 1] - keys[i])
			return ramp[keys[i]].lerp(ramp[keys[i + 1]], local_t)

	return ramp[keys[keys.size() - 1]]

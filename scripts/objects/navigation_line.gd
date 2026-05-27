extends MeshInstance3D

## NavigationLine — Generates and renders a beautiful glowing 3D stardust path ribbon.

@export var thickness: float = 0.55
@export var same_planet_resolution: int = 36
@export var space_resolution: int = 48

var _material: ShaderMaterial = null


func _ready() -> void:
	# Keep a reference to the shader material to set variables if needed
	_material = material_override as ShaderMaterial


func _process(_delta: float) -> void:
	var target = NavigationManager.active_target_node
	var player = get_tree().get_first_node_in_group("player")
	
	# Hide line if no target, no player, or if player is inside the house
	if target == null or player == null or player.get("is_indoors") == true:
		mesh = null
		return
		
	var player_pos = player.global_position
	# If player is in airplane, start the path from the airplane
	if player.get("is_in_airplane") == true:
		var airplane = get_tree().get_first_node_in_group("airplane")
		if airplane:
			player_pos = airplane.global_position
			
	var target_pos = target.global_position
	
	# Determine if player and target are on the same planet
	var player_planet = _get_nearest_planet(player_pos)
	var target_planet = _get_nearest_planet(target_pos)
	
	var on_same_planet = false
	if player_planet == target_planet and player_planet != null:
		# Check distance to planet to be sure they are on/near it
		var dist_to_planet = player_pos.distance_to(player_planet.global_position)
		var radius = _get_planet_radius(player_planet)
		# If player is within a reasonable distance of the planet surface, they are on it
		if dist_to_planet < radius * 2.5:
			on_same_planet = true
			
	var points: Array[Vector3] = []
	
	if on_same_planet:
		points = _calculate_same_planet_path(player_pos, target_pos, player_planet)
	else:
		points = _calculate_space_path(player_pos, target_pos)
		
	_generate_ribbon_mesh(points, on_same_planet, player_planet)


func _get_nearest_planet(pos: Vector3) -> Node3D:
	var best_dist: float = 99999.0
	var best_planet: Node3D = null
	for planet in get_tree().get_nodes_in_group("planet"):
		var dist = pos.distance_to(planet.global_position)
		if dist < best_dist:
			best_dist = dist
			best_planet = planet
	return best_planet


func _get_planet_radius(planet: Node3D) -> float:
	var col = planet.get_node_or_null("CollisionShape3D")
	if col and col.shape is SphereShape3D:
		return col.shape.radius
	return 15.0 # default fallback


func _calculate_same_planet_path(start: Vector3, end: Vector3, planet: Node3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var center = planet.global_position
	
	var v_start = start - center
	var v_end = end - center
	
	var len_start = v_start.length()
	var len_end = v_end.length()
	
	var u_start = v_start.normalized()
	var u_end = v_end.normalized()
	
	var angle = u_start.angle_to(u_end)
	
	# If start and end are practically identical, just draw a direct short segment
	if angle < 0.02:
		points.append(start)
		points.append(end)
		return points
		
	# Interpolate along the sphere surface using SLERP
	for i in range(same_planet_resolution + 1):
		var t = float(i) / same_planet_resolution
		var slerped_normal = u_start.slerp(u_end, t)
		
		# Interpolate height to account for hills/pois smoothly
		var height = lerp(len_start, len_end, t) + 0.38
		var point = center + slerped_normal * height
		points.append(point)
		
	return points


func _calculate_space_path(start: Vector3, end: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var dist = start.distance_to(end)
	
	if dist < 5.0:
		points.append(start)
		points.append(end)
		return points
		
	# Midpoint
	var mid = (start + end) * 0.5
	var dir = (end - start).normalized()
	
	# Find a beautiful arc direction pointing "outwards" from origin (0,0,0)
	var up = mid.normalized()
	if up.length() < 0.1:
		up = Vector3.UP
		
	var right_temp = dir.cross(up).normalized()
	var arc_normal = right_temp.cross(dir).normalized()
	
	var height = dist * 0.20 # Curve height is 20% of travel distance
	var control = mid + arc_normal * height
	
	# Sample quadratic Bezier curve points
	for i in range(space_resolution + 1):
		var t = float(i) / space_resolution
		var point = (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * control + t * t * end
		points.append(point)
		
	return points


func _generate_ribbon_mesh(points: Array[Vector3], on_same_planet: bool, planet: Node3D) -> void:
	if points.size() < 2:
		mesh = null
		return
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var planet_center = planet.global_position if planet else Vector3.ZERO
	
	for i in range(points.size()):
		var p = points[i]
		var tangent: Vector3
		
		if i == 0:
			tangent = (points[1] - points[0]).normalized()
		elif i == points.size() - 1:
			tangent = (points[i] - points[i-1]).normalized()
		else:
			tangent = (points[i+1] - points[i-1]).normalized()
			
		var up: Vector3
		if on_same_planet:
			up = (p - planet_center).normalized()
		else:
			up = p.normalized()
			if up.length() < 0.1:
				up = Vector3.UP
			var right_temp = tangent.cross(up).normalized()
			up = right_temp.cross(tangent).normalized()
			
		var right = tangent.cross(up).normalized()
		
		var left_vert = p - right * (thickness * 0.5)
		var right_vert = p + right * (thickness * 0.5)
		
		# UV.y is length repetition
		var progress = float(i) / (points.size() - 1)
		var v_coord = progress * 12.0
		
		# Save path progress [0,1] in vertex color (COLOR.r) for edge fading in shader!
		st.set_color(Color(progress, 0, 0, 1))
		
		st.set_uv(Vector2(0, v_coord))
		st.add_vertex(left_vert)
		
		st.set_uv(Vector2(1, v_coord))
		st.add_vertex(right_vert)
		
	mesh = st.commit()

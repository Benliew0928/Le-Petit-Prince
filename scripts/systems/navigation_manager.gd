extends Node

## NavigationManager — Global singleton managing map UI state & 3D waypoint navigation lines.

signal map_toggled(is_open: bool)
signal target_changed(node: Node3D, display_name: String)

var active_target_node: Node3D = null
var active_target_name: String = ""
var is_map_open: bool = false

var map_scene = preload("res://ui/map_system.tscn")
var map_instance: Control = null

var line_scene = preload("res://scenes/navigation_line.tscn")
var line_instance: Node3D = null


func _ready() -> void:
	# Instantiate and add the map system UI overlay to root viewport deferred
	map_instance = map_scene.instantiate()
	get_tree().root.call_deferred("add_child", map_instance)
	map_instance.visible = false
	
	# Spawn navigation line in the world
	call_deferred("_setup_navigation_line")


func _setup_navigation_line() -> void:
	var world = get_tree().root.get_node_or_null("TestWorld")
	if world:
		line_instance = line_scene.instantiate()
		world.add_child(line_instance)


func _unhandled_input(event: InputEvent) -> void:
	# Check for key press 'M' to toggle the map system
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_M:
			get_viewport().set_input_as_handled()
			toggle_map()


func toggle_map() -> void:
	is_map_open = not is_map_open
	
	if map_instance:
		map_instance.visible = is_map_open
		if is_map_open:
			map_instance.call("open_map")
		else:
			map_instance.call("close_map")
	
	# Handle mouse capture
	if is_map_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	map_toggled.emit(is_map_open)


func set_navigation_target(node: Node3D, display_name: String) -> void:
	active_target_node = node
	active_target_name = display_name
	target_changed.emit(node, display_name)
	
	# Close the map when target is set
	if is_map_open:
		toggle_map()
		
	# Show narrative feedback bubble
	DialogueManager.show_dialogue([
		{
			"speaker": "Prince",
			"text": "I have marked the way to " + display_name + "! A golden thread will guide us."
		}
	])


func clear_navigation_target() -> void:
	if active_target_node != null:
		active_target_node = null
		active_target_name = ""
		target_changed.emit(null, "")


func _physics_process(delta: float) -> void:
	# Proximity check to clear the active waypoint
	if active_target_node == null:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
		
	var dist = player.global_position.distance_to(active_target_node.global_position)
	var is_airplane = player.get("is_in_airplane") == true
	
	# Proximity threshold depends on whether we are on foot/local or flying in space
	var same_planet = false
	var player_planet = _get_nearest_planet(player.global_position)
	var target_planet = _get_nearest_planet(active_target_node.global_position)
	if player_planet == target_planet and player_planet != null:
		same_planet = true
		
	var clear_dist = 4.0 if same_planet else 45.0
	
	if dist < clear_dist:
		var name_copy = active_target_name
		clear_navigation_target()
		DialogueManager.show_dialogue([
			{
				"speaker": "",
				"text": "You have arrived at your destination: " + name_copy + "."
			}
		])


func _get_nearest_planet(pos: Vector3) -> Node3D:
	var best_dist: float = 99999.0
	var best_planet: Node3D = null
	for planet in get_tree().get_nodes_in_group("planet"):
		var dist = pos.distance_to(planet.global_position)
		if dist < best_dist:
			best_dist = dist
			best_planet = planet
	return best_planet


# Helper to find a specific POI node on a planet dynamically
func find_poi_node(planet_internal_name: String, poi_node_name: String) -> Node3D:
	var world = get_tree().root.get_node_or_null("TestWorld")
	if not world:
		return null
		
	var planet = world.get_node_or_null(planet_internal_name)
	if not planet:
		return null
		
	# Special case for GeologicalLandmark match by name
	if poi_node_name.to_lower() == "geologicallandmark":
		var landmark = planet.find_child("GeologicalLandmark", true, false)
		if landmark:
			return landmark
			
	var target = planet.find_child(poi_node_name, true, false)
	if target is Node3D:
		return target
		
	return planet # fallback

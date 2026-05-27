extends Node

## HeldItem — Autoload singleton for one-item-at-a-time system.
##
## The Prince holds ONE item, visible in his hand.
## Must drop current item (Q) before picking up another.

signal item_held(item_id: String)
signal item_dropped(item_id: String)

var current_item_id: String = ""
var _hand_mesh: MeshInstance3D = null

var _drop_scenes: Dictionary = {}


func _ready() -> void:
	_drop_scenes = {
		"watering_can": preload("res://scenes/watering_can.tscn"),
		"shovel": preload("res://scenes/shovel.tscn"),
		"seeds": preload("res://scenes/seed_item.tscn"),
		"wheat": preload("res://scenes/wheat_item.tscn"),
	}


## Pick up an item. Returns false if already holding something or starving.
func hold(item_id: String) -> bool:
	if not is_empty():
		return false
	if Hunger.is_starving:
		DialogueManager.show_dialogue([{"speaker": "", "text": "Too hungry to carry anything..."}])
		return false
	current_item_id = item_id
	_show_hand_mesh(item_id)
	item_held.emit(item_id)
	return true


## Drop the current item at a world position. Spawns a pickup on the surface.
func drop_at(position: Vector3) -> void:
	if is_empty():
		return
	var item_id := current_item_id
	current_item_id = ""
	_hide_hand_mesh()

	# Spawn world object
	if _drop_scenes.has(item_id):
		var scene: PackedScene = _drop_scenes[item_id]
		var instance := scene.instantiate()
		instance.global_position = position
		get_tree().current_scene.add_child(instance)
		# orient_to_surface is called in the instance's _ready

	item_dropped.emit(item_id)


## Consume the held item (eating food, planting seeds). No world drop.
func consume() -> String:
	var id := current_item_id
	current_item_id = ""
	_hide_hand_mesh()
	return id


func is_holding(item_id: String) -> bool:
	return current_item_id == item_id


func is_empty() -> bool:
	return current_item_id == ""


func _show_hand_mesh(item_id: String) -> void:
	_hide_hand_mesh()
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var hand_slot = player.get_node_or_null("HandSlot")
	if hand_slot == null:
		return
	_hand_mesh = _create_visual(item_id)
	hand_slot.add_child(_hand_mesh)


func _hide_hand_mesh() -> void:
	if _hand_mesh and is_instance_valid(_hand_mesh):
		_hand_mesh.queue_free()
		_hand_mesh = null


func _create_visual(item_id: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	match item_id:
		"watering_can":
			var box := BoxMesh.new()
			box.size = Vector3(0.15, 0.12, 0.1)
			mi.mesh = box
			mat.albedo_color = Color(0.3, 0.5, 0.8)
		"shovel":
			var box := BoxMesh.new()
			box.size = Vector3(0.05, 0.4, 0.05)
			mi.mesh = box
			mat.albedo_color = Color(0.5, 0.35, 0.15)
		"seeds":
			var sphere := SphereMesh.new()
			sphere.radius = 0.06
			sphere.height = 0.12
			mi.mesh = sphere
			mat.albedo_color = Color(0.85, 0.75, 0.3)
		"wheat":
			var box := BoxMesh.new()
			box.size = Vector3(0.06, 0.3, 0.06)
			mi.mesh = box
			mat.albedo_color = Color(0.95, 0.85, 0.3)
		_:
			var box := BoxMesh.new()
			box.size = Vector3(0.1, 0.1, 0.1)
			mi.mesh = box
			mat.albedo_color = Color(1, 1, 1)

	mi.material_override = mat
	return mi

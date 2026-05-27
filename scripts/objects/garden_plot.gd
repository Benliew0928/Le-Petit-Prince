extends Node3D

## GardenPlot — Manages planting spots on the planet surface.
## Player holds seeds and presses E at the garden to plant.

var _crop_scene: PackedScene


func _ready() -> void:
	add_to_group("interactable")
	PlanetGravity.orient_to_surface(self)
	_crop_scene = preload("res://scenes/crop.tscn")


func interact() -> void:
	if not HeldItem.is_holding("seeds"):
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "You need seeds to plant. Check the shelf in the house."}
		])
		return

	# Find nearest empty planting spot
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var nearest_spot: Marker3D = null
	var nearest_dist := 3.0

	for child in get_children():
		if child is Marker3D and _spot_is_empty(child):
			var dist: float = player.global_position.distance_to(child.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_spot = child

	if nearest_spot == null:
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "No empty spots to plant. Wait for crops to be harvested."}
		])
		return

	# Plant seed
	HeldItem.consume()
	var crop := _crop_scene.instantiate()
	crop.global_position = nearest_spot.global_position
	get_tree().current_scene.add_child(crop)
	DialogueManager.show_dialogue([
		{"speaker": "", "text": "Planted a seed! It will take time to grow."}
	])


func get_interact_text() -> String:
	if HeldItem.is_holding("seeds"):
		return "Press E to plant seeds"
	return "Garden — need seeds to plant"


func _spot_is_empty(spot: Marker3D) -> bool:
	var crops := get_tree().get_nodes_in_group("crop")
	for crop in crops:
		if crop.global_position.distance_to(spot.global_position) < 0.5:
			return false
	return true

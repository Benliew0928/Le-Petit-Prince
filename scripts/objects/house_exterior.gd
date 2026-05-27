extends StaticBody3D

## House Exterior — Door interaction to enter the house.
## Teleports the player into the 3D interior room.
## Hides/shows the interior room to prevent it being visible from outside.

func _ready() -> void:
	add_to_group("interactable")
	PlanetGravity.orient_to_surface(self)

	# Hide interior on startup so it's not visible in the sky
	await get_tree().process_frame
	var interior = get_tree().get_first_node_in_group("house_interior")
	if interior:
		interior.visible = false


func interact() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.is_indoors:
		return

	var interior = get_tree().get_first_node_in_group("house_interior")
	if interior == null:
		return

	# Store exit position (above house on planet surface)
	var surface_normal := global_position.normalized()
	interior.exit_position = global_position + surface_normal * 1.5

	# Show interior room
	interior.visible = true

	# Teleport player inside
	var spawn: Marker3D = interior.get_node("SpawnPoint")
	player.global_position = spawn.global_position
	player.is_indoors = true
	player.planet_center = Vector3(0, -1000, 0)
	player.velocity = Vector3.ZERO

	# Snap camera to interior
	var cam := get_viewport().get_camera_3d()
	if cam:
		cam.global_position = spawn.global_position + Vector3(0, 2, 5)


func get_interact_text() -> String:
	return "Press E to enter house"

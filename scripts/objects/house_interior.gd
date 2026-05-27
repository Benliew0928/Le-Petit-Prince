extends Node3D

## HouseInterior — Manages the 3D interior room.
## Stores exit position for when the player leaves.

var exit_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("house_interior")

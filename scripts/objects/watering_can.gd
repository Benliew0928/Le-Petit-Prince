extends StaticBody3D

## Watering Can — Pickup item on Planet B-612.
##
## Player presses E to pick up. Once in inventory, it's permanent.

var picked_up: bool = false


func _ready() -> void:
	add_to_group("interactable")
	PlanetGravity.orient_to_surface(self)


func interact() -> void:
	if picked_up:
		return
	picked_up = true
	Inventory.add_item("watering_can")
	DialogueManager.show_dialogue([
		{"speaker": "", "text": "You picked up the watering can. Rose will need this."}
	])
	# Shrink and hide
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(_hide_permanently)


func get_interact_text() -> String:
	return "Press E to pick up the watering can"


func _hide_permanently() -> void:
	visible = false
	remove_from_group("interactable")
	$CollisionShape3D.set_deferred("disabled", true)

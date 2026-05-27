extends StaticBody3D

## ToolPickup — Generic droppable/pickable world object.
##
## Used for watering can, shovel, seeds, wheat — any item the Prince
## can hold in his hand. Placed on the planet surface.

@export var item_id: String = "watering_can"


func _ready() -> void:
	add_to_group("interactable")
	PlanetGravity.orient_to_surface(self)


func interact() -> void:
	if not HeldItem.is_empty():
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Drop the " + HeldItem.current_item_id.replace("_", " ") + " first. (Press Q)"}
		])
		return

	if HeldItem.hold(item_id):
		queue_free()


func get_interact_text() -> String:
	if not HeldItem.is_empty():
		return "Drop " + HeldItem.current_item_id.replace("_", " ") + " first (Q)"
	return "Press E to pick up " + item_id.replace("_", " ")

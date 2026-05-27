extends StaticBody3D

## SeedShelf — Infinitely dispenses seeds from inside the house.
## Player grabs seeds as a held item to carry outside and plant.

func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	if not HeldItem.is_empty():
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Drop the " + HeldItem.current_item_id.replace("_", " ") + " first. (Press Q)"}
		])
		return

	if HeldItem.hold("seeds"):
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Grabbed some seeds from the shelf."}
		])


func get_interact_text() -> String:
	if not HeldItem.is_empty():
		return "Drop " + HeldItem.current_item_id.replace("_", " ") + " first (Q)"
	return "Press E to grab seeds"

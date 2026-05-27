extends StaticBody3D

## StarPickup — Glowing star item for King's puzzle.
##
## Press E to pick up. Uses HeldItem system.

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("king_star")


func interact() -> void:
	if not HeldItem.is_empty():
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Your hands are full. Drop what you're holding first."}
		])
		return

	var success := HeldItem.hold("star")
	if success:
		visible = false
		# Disable collision so it's gone
		for child in get_children():
			if child is CollisionShape3D:
				child.disabled = true
		remove_from_group("interactable")
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "You picked up a fallen star. It glows warmly in your hands."}
		])


func get_interact_text() -> String:
	return "Press E to pick up the star"

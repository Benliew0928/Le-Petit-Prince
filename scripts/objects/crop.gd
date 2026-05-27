extends StaticBody3D

## Crop — Grows through 3 stages after being planted.
## PLANTED → GROWING → READY (harvestable as wheat).

enum Stage { PLANTED, GROWING, READY }

@export var grow_time: float = 30.0  # Seconds per stage

var stage: Stage = Stage.PLANTED
var _timer: float = 0.0


func _ready() -> void:
	add_to_group("crop")
	PlanetGravity.orient_to_surface(self)
	_update_visual()


func _process(delta: float) -> void:
	if stage == Stage.READY:
		return
	_timer += delta
	if _timer >= grow_time:
		_timer = 0.0
		_advance_stage()


func interact() -> void:
	if stage != Stage.READY:
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "The crop is still growing..."}
		])
		return

	if not HeldItem.is_empty():
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Drop what you're holding first. (Press Q)"}
		])
		return

	if HeldItem.hold("wheat"):
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "Harvested golden wheat!"}
		])
		remove_from_group("crop")
		remove_from_group("interactable")
		queue_free()


func get_interact_text() -> String:
	match stage:
		Stage.PLANTED:
			return "Just planted..."
		Stage.GROWING:
			return "Still growing..."
		Stage.READY:
			if HeldItem.is_empty():
				return "Press E to harvest wheat"
			return "Drop item first (Q) to harvest"
	return ""


func _advance_stage() -> void:
	match stage:
		Stage.PLANTED:
			stage = Stage.GROWING
		Stage.GROWING:
			stage = Stage.READY
			add_to_group("interactable")
	_update_visual()


func _update_visual() -> void:
	var stem := get_node_or_null("Stem") as MeshInstance3D
	var head := get_node_or_null("Head") as MeshInstance3D
	if stem == null:
		return

	match stage:
		Stage.PLANTED:
			stem.scale = Vector3(0.3, 0.2, 0.3)
			if head:
				head.visible = false
		Stage.GROWING:
			stem.scale = Vector3(0.5, 0.6, 0.5)
			if head:
				head.visible = false
		Stage.READY:
			stem.scale = Vector3(0.7, 1.0, 0.7)
			if head:
				head.visible = true
				head.scale = Vector3(1, 1, 1)

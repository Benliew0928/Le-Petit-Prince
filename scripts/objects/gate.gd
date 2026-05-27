extends StaticBody3D

## Gate — Lockable barrier on King's Planet.
##
## Starts locked (solid collision). When unlocked, rotates open.

@export var gate_index: int = 0
var is_locked: bool = true


func _ready() -> void:
	add_to_group("king_gate")


func unlock() -> void:
	if not is_locked:
		return
	is_locked = false

	# Animate: rotate the gate open
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:y", 90.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Disable collision after animation
	await tween.finished
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true

extends StaticBody3D

## Baobab — Grows through 3 stages. All stages removable with shovel.
## Bigger trees require more E presses to dig out.
##
## SPROUT (1 press) → SAPLING (5 presses) → TREE (15 presses)
## Progress resets if the player walks away.

enum Stage { SPROUT, SAPLING, TREE }

@export var growth_time: float = 30.0

var stage: Stage = Stage.SPROUT
var dig_required: int = 1
var dig_progress: int = 0
var _growth_timer: float = 0.0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("baobab")
	PlanetGravity.orient_to_surface(self)
	_update_visual()
	_update_dig_required()


func _process(delta: float) -> void:
	# Growth
	if stage != Stage.TREE:
		_growth_timer += delta
		if _growth_timer >= growth_time:
			_growth_timer = 0.0
			_advance_stage()

	# Reset dig progress if player walks away
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist > 3.0 and dig_progress > 0:
			dig_progress = 0


func interact() -> void:
	if not HeldItem.is_holding("shovel"):
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "You need a shovel to dig this out."}
		])
		return

	# Dig one step
	dig_progress += 1

	if dig_progress >= dig_required:
		# Uprooted!
		set_process(false)
		remove_from_group("interactable")
		remove_from_group("baobab")

		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.4).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)

		# Notify Rose
		var rose = get_tree().get_first_node_in_group("rose")
		if rose:
			var remaining := get_tree().get_nodes_in_group("baobab")
			if remaining.size() <= 1:
				rose.clear_baobab_complaint()
	else:
		# Shake animation
		var tween := create_tween()
		var original_pos := global_position
		var shake_dir := global_basis.x * 0.05
		tween.tween_property(self, "global_position", original_pos + shake_dir, 0.05)
		tween.tween_property(self, "global_position", original_pos - shake_dir, 0.05)
		tween.tween_property(self, "global_position", original_pos, 0.05)


func get_interact_text() -> String:
	if not HeldItem.is_holding("shovel"):
		return "Need shovel to dig"
	if dig_progress > 0:
		return "Digging... (%d/%d)" % [dig_progress, dig_required]
	return "Press E to dig (%d presses)" % dig_required


func _advance_stage() -> void:
	match stage:
		Stage.SPROUT:
			stage = Stage.SAPLING
		Stage.SAPLING:
			stage = Stage.TREE
			var rose = get_tree().get_first_node_in_group("rose")
			if rose:
				rose.trigger_baobab_grown()
	_update_dig_required()
	_update_visual()


func _update_dig_required() -> void:
	match stage:
		Stage.SPROUT:
			dig_required = 1
		Stage.SAPLING:
			dig_required = 5
		Stage.TREE:
			dig_required = 15


func _update_visual() -> void:
	var trunk := get_node_or_null("Trunk") as MeshInstance3D
	var canopy := get_node_or_null("Canopy") as MeshInstance3D
	if trunk == null or canopy == null:
		return
	match stage:
		Stage.SPROUT:
			trunk.scale = Vector3(0.3, 0.3, 0.3)
			canopy.scale = Vector3(0.3, 0.3, 0.3)
		Stage.SAPLING:
			trunk.scale = Vector3(0.6, 0.7, 0.6)
			canopy.scale = Vector3(0.7, 0.6, 0.7)
		Stage.TREE:
			trunk.scale = Vector3(1.0, 1.2, 1.0)
			canopy.scale = Vector3(1.3, 1.0, 1.3)

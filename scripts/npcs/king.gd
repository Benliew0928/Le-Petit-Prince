extends StaticBody3D

## King NPC — Gives "logical orders" as puzzles.
##
## 3 orders: sit, bring star, wait for sunset.
## Progression-based: puzzle elements appear/activate as orders are completed.

enum PuzzleState { GREETING, ORDER_SIT, ORDER_STAR, ORDER_SUNSET, COMPLETE }

var puzzle_state: PuzzleState = PuzzleState.GREETING
var _has_greeted: bool = false
var _sit_timer: float = 0.0
const SIT_REQUIRED: float = 2.0
var _visibility_initialized: bool = false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("king")
	# Wait enough frames for all nodes to register their groups
	await get_tree().create_timer(0.2).timeout
	_update_puzzle_visibility()
	_visibility_initialized = true


func _physics_process(delta: float) -> void:
	# Safety: re-hide if not yet initialized
	if not _visibility_initialized:
		return

	if puzzle_state != PuzzleState.ORDER_SIT:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist: float = global_position.distance_to(player.global_position)
	if dist > 4.0:
		_sit_timer = 0.0
		return

	if player.get("is_sitting") != null and player.is_sitting:
		_sit_timer += delta
		if _sit_timer >= SIT_REQUIRED:
			_sit_timer = 0.0
			DialogueManager.show_dialogue(KingDialogue.sit_success)
			puzzle_state = PuzzleState.ORDER_STAR
			_update_puzzle_visibility()
	else:
		_sit_timer = 0.0


func interact() -> void:
	match puzzle_state:
		PuzzleState.GREETING:
			DialogueManager.show_dialogue(KingDialogue.greeting)
			puzzle_state = PuzzleState.ORDER_SIT
			_has_greeted = true

		PuzzleState.ORDER_SIT:
			if not _has_greeted:
				DialogueManager.show_dialogue(KingDialogue.greeting)
				_has_greeted = true
			else:
				DialogueManager.show_dialogue(KingDialogue.order_sit)

		PuzzleState.ORDER_STAR:
			if HeldItem.is_holding("star"):
				HeldItem.consume()
				DialogueManager.show_dialogue(KingDialogue.star_success)
				puzzle_state = PuzzleState.ORDER_SUNSET
				_update_puzzle_visibility()
			else:
				DialogueManager.show_dialogue(KingDialogue.order_star)

		PuzzleState.ORDER_SUNSET:
			DialogueManager.show_dialogue(KingDialogue.order_sunset)

		PuzzleState.COMPLETE:
			DialogueManager.show_dialogue(KingDialogue.get_post_complete())


## Called by SunsetZone when the sunset finishes.
func on_sunset_complete() -> void:
	if puzzle_state == PuzzleState.ORDER_SUNSET:
		DialogueManager.show_dialogue(KingDialogue.sunset_success)
		puzzle_state = PuzzleState.COMPLETE
		await get_tree().create_timer(4.0).timeout
		DialogueManager.show_dialogue(KingDialogue.farewell)


## Show/hide puzzle elements based on current state.
func _update_puzzle_visibility() -> void:
	# Star pickup: only visible/interactable during ORDER_STAR
	for node in get_tree().get_nodes_in_group("king_star"):
		var show_star: bool = (puzzle_state == PuzzleState.ORDER_STAR)
		node.visible = show_star
		if show_star:
			node.add_to_group("interactable")
		else:
			if node.is_in_group("interactable"):
				node.remove_from_group("interactable")
		for child in node.get_children():
			if child is CollisionShape3D:
				child.disabled = not show_star

	# Sunset zone: only active during ORDER_SUNSET
	for node in get_tree().get_nodes_in_group("king_sunset"):
		var show_sunset: bool = (puzzle_state == PuzzleState.ORDER_SUNSET)
		node.visible = show_sunset
		node.set_process(show_sunset)
		for child in node.get_children():
			if child is CollisionShape3D:
				child.disabled = not show_sunset


func get_interact_text() -> String:
	match puzzle_state:
		PuzzleState.GREETING:
			return "Press E to approach the King"
		PuzzleState.ORDER_SIT:
			return "Sit near the King (press C)"
		PuzzleState.ORDER_STAR:
			if HeldItem.is_holding("star"):
				return "Press E to present the star"
			return "Press E to hear the King's order"
		PuzzleState.ORDER_SUNSET:
			return "Press E to hear the King's order"
		PuzzleState.COMPLETE:
			return "Press E to speak with the King"
	return ""

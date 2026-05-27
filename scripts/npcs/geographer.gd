extends StaticBody3D

## Geographer NPC — Tasks the player with exploring other planets and recording surveys.

enum PuzzleState { GREETING, IN_PROGRESS, COMPLETE }

var puzzle_state: PuzzleState = PuzzleState.GREETING


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("geographer")


func interact() -> void:
	match puzzle_state:
		PuzzleState.GREETING:
			DialogueManager.show_dialogue(GeographerDialogue.greeting)
			GeographyQuest.is_quest_active = true
			puzzle_state = PuzzleState.IN_PROGRESS

		PuzzleState.IN_PROGRESS:
			if GeographyQuest.is_complete():
				# Play success + farewell sequence in one continuous flow
				var final_sequence := GeographerDialogue.quest_success + GeographerDialogue.farewell
				DialogueManager.show_dialogue(final_sequence)
				puzzle_state = PuzzleState.COMPLETE
			else:
				# Format and show dynamic reminder
				var reminder := GeographerDialogue.quest_reminder.duplicate(true)
				var count_str := str(GeographyQuest.get_recorded_count())
				reminder[2]["text"] = "Come back once you have found the glowing Memory Anchor on each of them! (Surveys recorded: " + count_str + "/4)"
				DialogueManager.show_dialogue(reminder)

		PuzzleState.COMPLETE:
			DialogueManager.show_dialogue(GeographerDialogue.post_complete)


func get_interact_text() -> String:
	match puzzle_state:
		PuzzleState.GREETING:
			return "Press E to speak with the Geographer"
		PuzzleState.IN_PROGRESS:
			if GeographyQuest.is_complete():
				return "Press E to submit geographical surveys"
			return "Press E to speak with the Geographer"
		PuzzleState.COMPLETE:
			return "Press E to speak with the Geographer"
	return ""

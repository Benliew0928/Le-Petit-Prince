extends CanvasLayer

## DialogueBox UI — Typewriter text display with speaker name.
##
## Registers with DialogueManager autoload. Handles input for
## advancing/skipping dialogue when active.

var is_typing: bool = false
var _full_text: String = ""

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/VBox/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $Panel/VBox/DialogueLabel
@onready var continue_label: Label = $Panel/VBox/ContinueLabel
@onready var type_timer: Timer = $TypeTimer


func _ready() -> void:
	DialogueManager.register_box(self)
	hide_box()


func _unhandled_input(event: InputEvent) -> void:
	if not DialogueManager.is_active:
		return

	# Space, Enter, E, or left-click to advance dialogue
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E]:
			get_viewport().set_input_as_handled()
			DialogueManager.advance()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			DialogueManager.advance()


## Display a single dialogue line with typewriter effect.
func display_line(line: Dictionary) -> void:
	panel.visible = true
	speaker_label.text = line.get("speaker", "")

	# Color the speaker name based on who's speaking
	if line.get("speaker", "") == "Rose":
		speaker_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.45, 1))
	else:
		speaker_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4, 1))

	_full_text = line.get("text", "")
	dialogue_label.text = _full_text
	dialogue_label.visible_characters = 0
	is_typing = true
	continue_label.visible = false
	type_timer.start()


## Skip the typewriter and show all text immediately.
func skip_typewriter() -> void:
	dialogue_label.visible_characters = -1
	is_typing = false
	type_timer.stop()
	continue_label.visible = true


## Hide the dialogue box.
func hide_box() -> void:
	panel.visible = false
	continue_label.visible = false


func _on_type_timer_timeout() -> void:
	dialogue_label.visible_characters += 1
	if dialogue_label.visible_characters >= _full_text.length():
		skip_typewriter()

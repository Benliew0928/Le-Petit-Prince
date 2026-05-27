extends Node

## DialogueManager — Autoload singleton for all dialogue display.
##
## Call DialogueManager.show_dialogue(lines) from any script.
## Each line is a Dictionary: {"speaker": "Rose", "text": "Some dialogue..."}
## Emits dialogue_started/dialogue_finished signals.

signal dialogue_started
signal dialogue_finished

var is_active: bool = false

var _lines: Array = []
var _index: int = 0
var _box = null  # Reference to the DialogueBox UI node


## Register the dialogue box UI (called by DialogueBox._ready)
func register_box(box) -> void:
	_box = box


## Show a sequence of dialogue lines. Each line: {"speaker": "Name", "text": "..."}
func show_dialogue(lines: Array) -> void:
	if is_active or lines.is_empty():
		return
	_lines = lines
	_index = 0
	is_active = true
	dialogue_started.emit()
	_show_current_line()


## Advance to the next line, or skip typewriter if still typing.
func advance() -> void:
	if not is_active:
		return
	if _box and _box.is_typing:
		_box.skip_typewriter()
		return
	_index += 1
	_show_current_line()


func _show_current_line() -> void:
	if _index >= _lines.size():
		_end_dialogue()
		return
	if _box:
		_box.display_line(_lines[_index])


func _end_dialogue() -> void:
	is_active = false
	_lines = []
	_index = 0
	if _box:
		_box.hide_box()
	dialogue_finished.emit()

extends StaticBody3D

## Lamplighter NPC and Rhythm Puzzle Controller
##
## The planet has a rapid day/night cycle driven by PlanetSun.
## The player must press E exactly when it turns dark (to turn on)
## and when it turns bright (to turn off), maintaining the rhythm.

enum State { IDLE, EXPLAINING, PLAYING, COMPLETED }

var current_state: State = State.IDLE
var is_day: bool = true
var lamp_is_on: bool = false
var successful_toggles: int = 0
const TOLERANCE: float = 1.0 # 1 second window to react

@onready var lamp_light: OmniLight3D = $Streetlamp/LampLight
@onready var lamp_mesh: MeshInstance3D = $Streetlamp/LampMesh


func _ready() -> void:
	add_to_group("interactable")
	lamp_light.visible = false


func _process(delta: float) -> void:
	if current_state == State.COMPLETED:
		return

	var sun_pivot := get_parent().get_node_or_null("SunPivot") as PlanetSun
	if sun_pivot:
		var was_day := is_day
		is_day = sun_pivot.is_day
		
		# If playing and they missed the previous window, reset combo
		if current_state == State.PLAYING and is_day != was_day:
			if (is_day and lamp_is_on) or (not is_day and not lamp_is_on):
				# They failed to toggle it in time!
				successful_toggles = 0
				current_state = State.IDLE
				DialogueManager.show_dialogue(LamplighterDialogue.fail_miss)


func interact() -> void:
	if current_state == State.IDLE:
		DialogueManager.show_dialogue(LamplighterDialogue.greeting)
		current_state = State.EXPLAINING
	elif current_state == State.EXPLAINING:
		DialogueManager.show_dialogue(LamplighterDialogue.explanation)
		current_state = State.PLAYING
		successful_toggles = 0
		var sun_pivot := get_parent().get_node_or_null("SunPivot") as PlanetSun
		if sun_pivot:
			is_day = sun_pivot.is_day
	elif current_state == State.COMPLETED:
		DialogueManager.show_dialogue(LamplighterDialogue.post_complete)
	elif current_state == State.PLAYING:
		_try_toggle_lamp()


func _try_toggle_lamp() -> void:
	var sun_pivot := get_parent().get_node_or_null("SunPivot") as PlanetSun
	if sun_pivot == null:
		return
		
	var time_since_flip := sun_pivot.time_since_flip
	var day_length := sun_pivot.day_length
	var time_until_flip := (day_length / 2.0) - time_since_flip
	
	if time_since_flip <= TOLERANCE or time_until_flip <= TOLERANCE:
		# Success!
		lamp_is_on = not lamp_is_on
		lamp_light.visible = lamp_is_on
		
		var mat := lamp_mesh.get_active_material(0)
		if mat:
			mat = mat.duplicate()
			lamp_mesh.set_surface_override_material(0, mat)
			if lamp_is_on:
				mat.set("emission_energy_multiplier", 2.0)
			else:
				mat.set("emission_energy_multiplier", 0.0)
			
		successful_toggles += 1
		
		if successful_toggles >= 4:
			current_state = State.COMPLETED
			DialogueManager.show_dialogue(LamplighterDialogue.completed)
		else:
			DialogueManager.show_dialogue(LamplighterDialogue.success_combo)
	else:
		# Failed! Pressed at the wrong time.
		successful_toggles = 0
		current_state = State.IDLE
		DialogueManager.show_dialogue(LamplighterDialogue.fail_early)


func get_interact_text() -> String:
	match current_state:
		State.IDLE:
			return "Press E to talk to the Lamplighter"
		State.EXPLAINING:
			return "Press E to learn the rhythm"
		State.PLAYING:
			if is_day:
				return "Wait for Sunset... (Then press E to Light)"
			else:
				return "Wait for Sunrise... (Then press E to Extinguish)"
		State.COMPLETED:
			return "The Lamplighter is sleeping"
	return ""

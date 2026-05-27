extends Area3D

@export var landmark_id: String = "" # "b612", "desert", "king", "lamplighter"
@export var landmark_name: String = ""

var _time: float = 0.0
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	add_to_group("interactable")
	_time = randf_range(0.0, 10.0)
	await get_tree().process_frame
	_update_visuals()


func _process(delta: float) -> void:
	_time += delta
	# Bobbing up and down + rotating animation
	if mesh:
		mesh.position.y = sin(_time * 2.0) * 0.12
		mesh.rotate_y(0.8 * delta)
		mesh.rotate_x(0.3 * delta)
	
	# Breathing light glow
	if light:
		light.light_energy = 1.0 + sin(_time * 3.0) * 0.35


func interact() -> void:
	if not GeographyQuest.is_quest_active:
		DialogueManager.show_dialogue([
			{"speaker": "Narrator", "text": "A beautiful glowing relic. It hums with the soft memory of the planet, but you have no journal to record its details yet."}
		])
		return
	
	if GeographyQuest.recorded_surveys.get(landmark_id, false):
		DialogueManager.show_dialogue([
			{"speaker": "Narrator", "text": "You have already recorded the geographical survey for this planet in your log."}
		])
		return
	
	# Record the survey
	GeographyQuest.recorded_surveys[landmark_id] = true
	_update_visuals()
	
	var text_lines: Array = []
	match landmark_id:
		"b612":
			text_lines = [
				{"speaker": "Narrator", "text": "Survey recorded: Volcanoes of B-612."},
				{"speaker": "Prince", "text": "I have noted: Two active volcanoes and one extinct. A good source of heat, if kept swept clean!"}
			]
		"desert":
			text_lines = [
				{"speaker": "Narrator", "text": "Survey recorded: Sandy Desert Planet."},
				{"speaker": "Prince", "text": "I have noted: Endless silent dunes, and the quiet home of a wild taming fox."}
			]
		"king":
			text_lines = [
				{"speaker": "Narrator", "text": "Survey recorded: Royal Throne Peak."},
				{"speaker": "Prince", "text": "I have noted: A tiny planet completely dominated by a royal seat of absolute authority."}
			]
		"lamplighter":
			text_lines = [
				{"speaker": "Narrator", "text": "Survey recorded: The Midnight Pole."},
				{"speaker": "Prince", "text": "I have noted: A streetlamp spinning so fast that day and night happen within seconds."}
			]
	
	DialogueManager.show_dialogue(text_lines)


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	
	if mesh:
		var mat := mesh.get_active_material(0) as ShaderMaterial
		if mat:
			mat = mat.duplicate() as ShaderMaterial
			mesh.set_surface_override_material(0, mat)
			
			if GeographyQuest.recorded_surveys.get(landmark_id, false):
				# Dim blue/white when recorded
				mat.set_shader_parameter("base_color", Color(0.4, 0.5, 0.6, 1.0))
				if light:
					light.light_color = Color(0.4, 0.6, 0.8)
			else:
				# Glowing cyan when unrecorded
				mat.set_shader_parameter("base_color", Color(0.1, 0.9, 0.7, 1.0))
				if light:
					light.light_color = Color(0.1, 0.9, 0.7)


func get_interact_text() -> String:
	if not GeographyQuest.is_quest_active:
		return "Examine glowing relic"
	if GeographyQuest.recorded_surveys.get(landmark_id, false):
		return "Survey completed"
	return "Record geographical survey"

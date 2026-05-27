extends Area3D

## SunsetZone — When player enters and stays, triggers a timed sunset.
##
## After 15 seconds, the sun "sets" (light dims) and the King is notified.
## Player must stay inside the zone for the full duration.

var _timer: float = 0.0
var _active: bool = false
var _completed: bool = false
var _player_inside: bool = false
var _sun_light: DirectionalLight3D = null
var _original_energy: float = 1.4

# Narration flags — prevent dialogue spam
var _shown_start: bool = false
var _shown_mid1: bool = false
var _shown_mid2: bool = false


func _ready() -> void:
	add_to_group("king_sunset")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not _active or _completed or not _player_inside:
		return

	_timer += delta

	# Gradually dim the sun
	if _sun_light != null:
		var progress: float = clampf(_timer / 15.0, 0.0, 1.0)
		_sun_light.light_energy = lerpf(_original_energy, 0.15, progress)

	# Show progress narration (once each)
	if _timer > 3.0 and not _shown_mid1:
		_shown_mid1 = true
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "(The light begins to soften...)"}
		])
	elif _timer > 8.0 and not _shown_mid2:
		_shown_mid2 = true
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "(The sky grows warmer... the sun is obeying.)"}
		])

	# Complete after 15 seconds
	if _timer >= 15.0:
		_completed = true
		_active = false

		DialogueManager.show_dialogue([
			{"speaker": "", "text": "(The sunset is complete. The King's order has been obeyed.)"}
		])

		# Notify the King
		var king = get_tree().get_first_node_in_group("king")
		if king != null and king.has_method("on_sunset_complete"):
			king.on_sunset_complete()

		# Restore light after a delay
		await get_tree().create_timer(5.0).timeout
		if _sun_light != null:
			var tween := create_tween()
			tween.tween_property(_sun_light, "light_energy", _original_energy, 3.0)


func _on_body_entered(body: Node3D) -> void:
	if _completed or not body.is_in_group("player"):
		return

	# Prevent re-triggering if already active
	if _player_inside:
		return

	_player_inside = true
	_active = true
	_timer = 0.0

	# Find the sun light
	if _sun_light == null:
		for node in get_tree().get_nodes_in_group("sun_light"):
			if node is DirectionalLight3D:
				_sun_light = node
				_original_energy = _sun_light.light_energy
				break
		if _sun_light == null:
			var root := get_tree().current_scene
			for child in root.get_children():
				if child is DirectionalLight3D:
					_sun_light = child
					_original_energy = _sun_light.light_energy
					break

	if not _shown_start:
		_shown_start = true
		DialogueManager.show_dialogue([
			{"speaker": "", "text": "(You wait for the sunset, as the King commanded... stay here.)"}
		])


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	_player_inside = false

	if not _completed:
		_active = false
		_timer = 0.0
		_shown_mid1 = false
		_shown_mid2 = false
		# Restore light
		if _sun_light != null:
			var tween := create_tween()
			tween.tween_property(_sun_light, "light_energy", _original_energy, 1.0)

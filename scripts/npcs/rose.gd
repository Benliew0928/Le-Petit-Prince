extends StaticBody3D

## Rose NPC — The Whims & Thorns System
##
## Rose is vain, demanding, and dramatic. She always has a complaint.
## Fulfilling one whim triggers dismissive thanks then a new complaint.
## A hidden bond meter gradually reveals her vulnerability.

signal whim_fulfilled(whim_type: String)

# ── Whim System ──
const WHIM_PRIORITY := ["dome", "water", "baobab", "caterpillar", "wind", "attention"]

var current_whim: String = "attention"
var escalation_stage: int = 0  # 0=hint, 1=demand, 2=outburst, 3=silence
var bond_level: int = 20       # 0-100, hidden from player

# ── Timers ──
@export var escalation_time: float = 45.0    # Seconds per escalation stage
@export var water_interval: float = 60.0     # Seconds before water whim triggers
@export var dome_wind_min: float = 90.0      # Min seconds between wind events
@export var dome_wind_max: float = 180.0     # Max seconds between wind events

var _escalation_timer: float = 0.0
var _water_timer: float = 15.0    # First water need comes quickly
var _dome_timer: float = 0.0
var _next_wind_time: float = 120.0

# ── State ──
var needs_water: bool = false
var dome_missing: bool = false
var baobab_complaint: bool = false
var _random_whim_active: String = ""


var _ambient_timer: float = 0.0
var _ambient_interval: float = 30.0  # Seconds between ambient lines
var _sway_phase: float = 0.0

var _ambient_lines: Array = [
	{"speaker": "Rose", "text": "*sigh* ...It's so quiet when you're not here."},
	{"speaker": "Rose", "text": "I can feel the starlight on my petals tonight."},
	{"speaker": "Rose", "text": "Are you going to stand there, or are you going to say something?"},
	{"speaker": "Rose", "text": "I was NOT waiting for you. I was enjoying the breeze."},
	{"speaker": "Rose", "text": "The sunset is beautiful... but don't tell it I said that."},
	{"speaker": "Rose", "text": "You know, other flowers don't have to ask to be watered."},
]


func _ready() -> void:
	add_to_group("rose")
	add_to_group("interactable")
	_next_wind_time = randf_range(dome_wind_min, dome_wind_max)
	_ambient_timer = randf_range(15.0, 45.0)

	# Orient to planet surface
	PlanetGravity.orient_to_surface(self)


func _process(delta: float) -> void:
	var dome := get_node_or_null("GlassDome") as MeshInstance3D
	if dome:
		dome.visible = not dome_missing
	var dome_base := get_node_or_null("DomeBase") as MeshInstance3D
	if dome_base:
		dome_base.visible = not dome_missing
	var dome_knob := get_node_or_null("DomeKnob") as MeshInstance3D
	if dome_knob:
		dome_knob.visible = not dome_missing

	# ── Gentle sway animation ──
	_sway_phase += delta * 1.5
	var sway_angle: float = sin(_sway_phase) * 0.03
	var petal := get_node_or_null("Petals") as MeshInstance3D
	if petal == null:
		petal = get_node_or_null("PetalCone") as MeshInstance3D
	if petal:
		petal.rotation.z = sway_angle
		petal.rotation.x = cos(_sway_phase * 0.7) * 0.02

	# ── Escalation timer ──
	_escalation_timer += delta
	if _escalation_timer >= escalation_time and escalation_stage < 3:
		escalation_stage += 1
		_escalation_timer = 0.0
		bond_level = maxi(0, bond_level - 3)
		if escalation_stage == 3:
			bond_level = maxi(0, bond_level - 7)

	# ── Water decay ──
	if not needs_water:
		_water_timer -= delta
		if _water_timer <= 0.0:
			needs_water = true
			_water_timer = water_interval
			_try_upgrade_whim("water")

	# ── Wind events (dome removal) ──
	if not dome_missing:
		_dome_timer += delta
		if _dome_timer >= _next_wind_time:
			dome_missing = true
			_dome_timer = 0.0
			_next_wind_time = randf_range(dome_wind_min, dome_wind_max)
			_try_upgrade_whim("dome")

	# ── Random whim trigger ──
	if current_whim == "attention" and _random_whim_active == "":
		if randf() < 0.0005:
			_random_whim_active = ["caterpillar", "wind"][randi() % 2]
			_try_upgrade_whim(_random_whim_active)

	# ── Ambient dialogue (unprompted) ──
	_ambient_timer -= delta
	if _ambient_timer <= 0.0:
		_ambient_timer = randf_range(25.0, 50.0)
		var player = get_tree().get_first_node_in_group("player")
		if player != null and not DialogueManager.is_active:
			var dist: float = global_position.distance_to(player.global_position)
			# Only speak if player is on same planet (nearby but not right next to)
			if dist > 2.0 and dist < 12.0:
				var line: Dictionary = _ambient_lines[randi() % _ambient_lines.size()]
				DialogueManager.show_dialogue([line])


## Called when the player presses E near Rose.
func interact() -> void:
	# If player has watering can and Rose needs water → water her
	if needs_water and HeldItem.is_holding("watering_can"):
		fulfill_whim("water")
		return

	# If dome is missing → place dome back
	if dome_missing:
		fulfill_whim("dome")
		return

	# Otherwise → Rose speaks her current whim
	var line: Dictionary
	if escalation_stage == 3:
		# Silence break
		line = RoseDialogue.get_silence_break()
		escalation_stage = 1  # Reset to demand level
		bond_level = maxi(0, bond_level + 2)
	else:
		line = RoseDialogue.get_whim_line(current_whim, escalation_stage, bond_level)
		bond_level = mini(100, bond_level + 1)

	DialogueManager.show_dialogue([line])


## Called when a whim is fulfilled (watering, dome placement, baobab pull, etc.)
func fulfill_whim(whim_type: String) -> void:
	# Bond increase — more if caught early
	if escalation_stage < 2:
		bond_level = mini(100, bond_level + 10)
	else:
		bond_level = mini(100, bond_level + 5)

	# Get fulfillment dialogue
	var lines: Array = [RoseDialogue.get_fulfillment_line(whim_type, bond_level)]

	# Rare vulnerability moment at high bond
	if bond_level >= 70 and randf() < 0.15:
		lines.append(RoseDialogue.get_vulnerability_line())

	DialogueManager.show_dialogue(lines)
	whim_fulfilled.emit(whim_type)

	# Apply whim-specific effects
	match whim_type:
		"water":
			needs_water = false
			_water_timer = water_interval
		"dome":
			dome_missing = false
			_dome_timer = 0.0
		"baobab":
			baobab_complaint = false
		"caterpillar", "wind":
			_random_whim_active = ""

	# Pick next whim
	_pick_next_whim()


## Get the interaction prompt text for the HUD.
func get_interact_text() -> String:
	if needs_water and HeldItem.is_holding("watering_can"):
		return "Press E to water Rose"
	if dome_missing:
		return "Press E to place the glass dome"
	if escalation_stage == 3:
		return "Press E ..."
	return "Press E to talk to Rose"


## Called by BaobabSpawner when a baobab reaches tree stage.
func trigger_baobab_grown() -> void:
	baobab_complaint = true
	_try_upgrade_whim("baobab")


## Called externally when baobabs are cleared.
func clear_baobab_complaint() -> void:
	baobab_complaint = false


func _try_upgrade_whim(whim: String) -> void:
	var priority_current := WHIM_PRIORITY.find(current_whim)
	var priority_new := WHIM_PRIORITY.find(whim)
	if priority_new >= 0 and (priority_new < priority_current or priority_current < 0):
		current_whim = whim
		escalation_stage = 0
		_escalation_timer = 0.0


func _pick_next_whim() -> void:
	# Check whims in priority order
	if dome_missing:
		current_whim = "dome"
	elif needs_water:
		current_whim = "water"
	elif baobab_complaint:
		current_whim = "baobab"
	elif _random_whim_active != "":
		current_whim = _random_whim_active
	else:
		current_whim = "attention"

	escalation_stage = 0
	_escalation_timer = 0.0

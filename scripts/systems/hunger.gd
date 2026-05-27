extends Node

## Hunger — Autoload singleton for starvation system.
##
## FULL (5 min) → HUNGRY (1 min warning) → STARVING (slow + can't pick up)
## Eating food or sleeping resets to FULL.

signal hunger_changed(state_name: String)

enum State { FULL, HUNGRY, STARVING }

var state: State = State.FULL
var is_starving: bool = false

var full_duration: float = 300.0     # 5 minutes
var hungry_duration: float = 60.0    # 1 minute grace

var _timer: float = 300.0
var _speed_multiplier: float = 1.0


func _process(delta: float) -> void:
	_timer -= delta

	match state:
		State.FULL:
			if _timer <= 0.0:
				state = State.HUNGRY
				_timer = hungry_duration
				hunger_changed.emit("hungry")
		State.HUNGRY:
			if _timer <= 0.0:
				state = State.STARVING
				is_starving = true
				_speed_multiplier = 0.5
				hunger_changed.emit("starving")
		State.STARVING:
			pass  # Stays until eating


## Eat food — resets hunger to FULL.
func eat() -> void:
	state = State.FULL
	is_starving = false
	_timer = full_duration
	_speed_multiplier = 1.0
	hunger_changed.emit("full")


## Get speed multiplier (1.0 normal, 0.5 when starving).
func get_speed_multiplier() -> float:
	return _speed_multiplier


## Get hunger ratio for HUD bar (1.0 = full, 0.0 = empty).
func get_hunger_ratio() -> float:
	match state:
		State.FULL:
			return clampf(_timer / full_duration, 0.0, 1.0)
		State.HUNGRY:
			return 0.0
		State.STARVING:
			return 0.0
	return 1.0


## Get state name as string.
func get_state_name() -> String:
	match state:
		State.FULL: return "full"
		State.HUNGRY: return "hungry"
		State.STARVING: return "starving"
	return "full"


## Reset hunger (called by bed/sleep).
func reset_hunger() -> void:
	eat()

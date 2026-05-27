extends Node3D

## BaobabSpawner — Manages baobab sprout spawning on the planet surface.
##
## Place Marker3D children to define spawn points.
## Spawns new baobabs on a timer, up to a maximum count.

@export var spawn_interval_min: float = 45.0
@export var spawn_interval_max: float = 90.0
@export var max_active: int = 3
@export var first_spawn_delay: float = 15.0

var _spawn_timer: float = 0.0
var _next_spawn_time: float = 15.0
var _spawn_points: Array[Marker3D] = []
var _baobab_scene: PackedScene

func _ready() -> void:
	_baobab_scene = preload("res://scenes/baobab_sprout.tscn")
	_next_spawn_time = first_spawn_delay

	# Collect all Marker3D children as spawn points
	for child in get_children():
		if child is Marker3D:
			_spawn_points.append(child)
			PlanetGravity.orient_to_surface(child)


func _process(delta: float) -> void:
	_spawn_timer += delta
	var active_count := get_tree().get_nodes_in_group("baobab").size()
	if _spawn_timer >= _next_spawn_time and active_count < max_active:
		_try_spawn()
		_spawn_timer = 0.0
		_next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)


func _try_spawn() -> void:
	# Find unoccupied spawn points
	var active_baobabs := get_tree().get_nodes_in_group("baobab")
	var available: Array[Marker3D] = []

	for point in _spawn_points:
		var occupied := false
		for b in active_baobabs:
			if b.global_position.distance_to(point.global_position) < 1.5:
				occupied = true
				break
		if not occupied:
			available.append(point)

	if available.is_empty():
		return

	# Pick a random available point
	var point: Marker3D = available[randi() % available.size()]
	var baobab: Node3D = _baobab_scene.instantiate()
	get_tree().current_scene.add_child(baobab)
	baobab.global_position = point.global_position
	# The baobab's _ready() will call orient_to_surface

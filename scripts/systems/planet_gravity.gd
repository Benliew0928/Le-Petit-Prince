extends Node3D
class_name PlanetGravity

## Attach to any planet to define its gravity field.
## Other systems can query this to get gravity direction and force
## for any world-space position.

@export var gravity_strength: float = 25.0
@export var radius: float = 8.0


## Returns the gravity direction (unit vector toward planet center)
## from the given world-space position.
func get_gravity_direction(from_position: Vector3) -> Vector3:
	var to_center := global_position - from_position
	if to_center.length_squared() < 0.001:
		return Vector3.DOWN
	return to_center.normalized()


## Returns the full gravity force vector (direction × strength)
## from the given world-space position.
func get_gravity_force(from_position: Vector3) -> Vector3:
	return get_gravity_direction(from_position) * gravity_strength


## Returns the surface normal (pointing away from center)
## at the given world-space position.
func get_surface_normal(from_position: Vector3) -> Vector3:
	return -get_gravity_direction(from_position)


## Static utility: orient a Node3D so its Y-up faces away from the planet center.
## Call from any surface object's _ready().
static func orient_to_surface(node: Node3D, center: Vector3 = Vector3.ZERO) -> void:
	var up := (node.global_position - center)
	if up.length() < 0.1:
		return
	up = up.normalized()
	var ref := Vector3.FORWARD
	if absf(up.dot(ref)) > 0.9:
		ref = Vector3.RIGHT
	var right := up.cross(ref).normalized()
	var forward := right.cross(up).normalized()
	node.global_basis = Basis(right, up, -forward)


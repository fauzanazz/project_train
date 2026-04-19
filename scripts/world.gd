extends Node2D
## res://scripts/world.gd
## Map layout management, navigation region, spawn corridor positions.

const MAP_SIZE: float = 3200.0
const VILLAGE_SIZE: float = 300.0

@export var spawn_corridors: Array[Vector2] = [
	Vector2(-1600, 0),   # West
	Vector2(1600, 0),    # East
	Vector2(0, -1600),   # North
	Vector2(0, 1600),    # South
]

func _ready() -> void:
	pass

func get_spawn_corridor(index: int) -> Vector2:
	return spawn_corridors[index % spawn_corridors.size()]

func get_village_gate() -> Vector2:
	if has_node("Village"):
		return get_node("Village").global_position + Vector2(0, VILLAGE_SIZE * 0.5)
	return Vector2.ZERO

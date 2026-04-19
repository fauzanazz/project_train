extends Node2D
## res://scripts/world.gd
## Map layout management, navigation region, spawn corridor positions.

const MAP_SIZE: float = 3200.0
const VILLAGE_SIZE: float = 300.0
const GROUND_COLOR := Color("#6B5A3E")

@export var spawn_corridors: Array[Vector2] = [
	Vector2(-1600, 0),   # West
	Vector2(1600, 0),    # East
	Vector2(0, -1600),   # North
	Vector2(0, 1600),    # South
]

# 12 resource nodes: mix of types in mid and outer rings
const NODE_PLACEMENTS: Array = [
	# Mid ring (~600-900 units from center)
	{"type": "lumber",   "pos": Vector2(700, 200)},
	{"type": "metal",    "pos": Vector2(-650, 350)},
	{"type": "medicine", "pos": Vector2(300, -750)},
	{"type": "lumber",   "pos": Vector2(-400, -680)},
	{"type": "metal",    "pos": Vector2(800, -300)},
	{"type": "medicine", "pos": Vector2(-780, -200)},
	# Outer ring (~1100-1400 units from center)
	{"type": "lumber",   "pos": Vector2(1200, 600)},
	{"type": "metal",    "pos": Vector2(-1100, 700)},
	{"type": "medicine", "pos": Vector2(1300, -500)},
	{"type": "lumber",   "pos": Vector2(-1200, -600)},
	{"type": "metal",    "pos": Vector2(600, 1300)},
	{"type": "medicine", "pos": Vector2(-500, -1350)},
]

func _ready() -> void:
	_place_resource_nodes()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Ground — fill the entire map with muted brown
	draw_rect(Rect2(-MAP_SIZE * 0.5, -MAP_SIZE * 0.5, MAP_SIZE, MAP_SIZE), GROUND_COLOR)

	# Subtle grid lines to give depth
	var grid_color := Color(0, 0, 0, 0.06)
	var step := 200.0
	var half := MAP_SIZE * 0.5
	var x := -half
	while x <= half:
		draw_line(Vector2(x, -half), Vector2(x, half), grid_color, 1.0)
		x += step
	var y := -half
	while y <= half:
		draw_line(Vector2(-half, y), Vector2(half, y), grid_color, 1.0)
		y += step

func _place_resource_nodes() -> void:
	var container: Node = get_node_or_null("ResourceNodes")
	if not container:
		return
	var rn_scene: PackedScene = load("res://scenes/resource_node.tscn")
	if not rn_scene:
		return
	for entry in NODE_PLACEMENTS:
		var node = rn_scene.instantiate()
		node.resource_type = entry["type"]
		node.position = entry["pos"]
		container.add_child(node)

func get_spawn_corridor(index: int) -> Vector2:
	return spawn_corridors[index % spawn_corridors.size()]

func get_village_gate() -> Vector2:
	if has_node("Village"):
		return get_node("Village").global_position + Vector2(0, VILLAGE_SIZE * 0.5)
	return Vector2.ZERO

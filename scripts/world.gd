extends Node2D
## res://scripts/world.gd
## Map layout management, navigation region, spawn corridors, hazard placement.

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
	# Outer ring (~1100-1400 units from center) — these get 3x yield
	{"type": "lumber",   "pos": Vector2(1200, 600)},
	{"type": "metal",    "pos": Vector2(-1100, 700)},
	{"type": "medicine", "pos": Vector2(1300, -500)},
	{"type": "lumber",   "pos": Vector2(-1200, -600)},
	{"type": "metal",    "pos": Vector2(600, 1300)},
	{"type": "medicine", "pos": Vector2(-500, -1350)},
]

# Hazard placements — 4 hazards on the map
const HAZARD_PLACEMENTS: Array = [
	{"type": "toxic_puddle", "pos": Vector2(500, -400)},
	{"type": "rubble_pile", "pos": Vector2(-600, 500)},
	{"type": "electrified_rail", "pos": Vector2(300, 800)},
	{"type": "toxic_puddle", "pos": Vector2(-900, -900)},
]

func _ready() -> void:
	_place_resource_nodes()
	_place_hazards()

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

	# Hazard warning markers on ground
	for hz_data in HAZARD_PLACEMENTS:
		var hz_type: String = hz_data["type"]
		var hz_pos: Vector2 = hz_data["pos"]
		match hz_type:
			"toxic_puddle":
				draw_circle(hz_pos, 22.0, Color("#4A7A3E44"))
			"rubble_pile":
				draw_circle(hz_pos, 18.0, Color("#8B8B8B44"))
			"electrified_rail":
				draw_line(hz_pos + Vector2(-40, 0), hz_pos + Vector2(40, 0), Color("#FFD70044"), 6.0)

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

func _place_hazards() -> void:
	var container: Node = get_node_or_null("HazardNodes")
	if not container:
		return
	for hz_data in HAZARD_PLACEMENTS:
		var hz_type: String = hz_data["type"]
		var hz_pos: Vector2 = hz_data["pos"]
		var hazard: Node2D = null
		match hz_type:
			"toxic_puddle":
				var hz_scene: PackedScene = load("res://scenes/hazard_toxic_puddle.tscn")
				if hz_scene:
					hazard = hz_scene.instantiate()
			"rubble_pile":
				var hz_scene: PackedScene = load("res://scenes/hazard_rubble_pile.tscn")
				if hz_scene:
					hazard = hz_scene.instantiate()
			"electrified_rail":
				var hz_scene: PackedScene = load("res://scenes/hazard_electrified_rail.tscn")
				if hz_scene:
					hazard = hz_scene.instantiate()
		if hazard:
			hazard.position = hz_pos
			container.add_child(hazard)

func get_spawn_corridor(index: int) -> Vector2:
	return spawn_corridors[index % spawn_corridors.size()]

func get_village_gate() -> Vector2:
	if has_node("Village"):
		return get_node("Village").global_position + Vector2(0, VILLAGE_SIZE * 0.5)
	return Vector2.ZERO
extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_swarmer_queen.gd
## Swarmer Queen — 150 HP, hybrid AI, spawns a Crawler every 5 seconds.

var _spawn_timer: float = 0.0
const SPAWN_INTERVAL: float = 5.0
const CRAWLER_SCENE_PATH: String = "res://scenes/enemy_crawler.tscn"

func _ready() -> void:
	super._ready()
	add_to_group("elites")
	_spawn_timer = SPAWN_INTERVAL

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_crawler()
		_spawn_timer = SPAWN_INTERVAL

func _spawn_crawler() -> void:
	var crawler_scene = load(CRAWLER_SCENE_PATH)
	if not crawler_scene:
		return
	var crawler = crawler_scene.instantiate()
	crawler.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	var world = get_tree().current_scene.get_node_or_null("World") if get_tree() else null
	if world:
		world.add_child(crawler)
	elif get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(crawler)
	WaveManager._active_enemies += 1

func _draw_body() -> void:
	# Dark purple (#8E44AD), bulbous body with small eyes
	const BODY := Color("#8E44AD")
	const OUTLINE := Color("#111111")
	const DARK := Color("#5A2A6A")
	const EYE_WHITE := Color("#CCCCCC")
	# Bulbous body — overlapping circles
	draw_circle(Vector2.ZERO, 13.0, BODY)
	draw_circle(Vector2(-5, 3), 10.0, BODY)
	draw_circle(Vector2(5, 3), 10.0, BODY)
	draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 24, OUTLINE, 2.5)
	# Eggs/sacs on sides
	draw_circle(Vector2(-8, 5), 5.0, DARK)
	draw_circle(Vector2(8, 5), 5.0, DARK)
	draw_arc(Vector2(-8, 5), 5.0, 0.0, TAU, 12, OUTLINE, 1.5)
	draw_arc(Vector2(8, 5), 5.0, 0.0, TAU, 12, OUTLINE, 1.5)
	# Head
	draw_circle(Vector2(0, -9), 7.0, DARK)
	draw_arc(Vector2(0, -9), 7.0, 0.0, TAU, 14, OUTLINE, 2.0)
	# Small compound eyes
	draw_circle(Vector2(-3, -10), 2.0, EYE_WHITE)
	draw_circle(Vector2(3, -10), 2.0, EYE_WHITE)
	draw_circle(Vector2(-3, -10), 1.0, Color("#111111"))
	draw_circle(Vector2(3, -10), 1.0, Color("#111111"))

func _get_radius() -> float:
	return 13.0
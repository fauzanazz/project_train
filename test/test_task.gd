extends SceneTree
## res://test/test_task.gd
## Visual test for Task 3: Run gameplay for 12 seconds, spawn mixed enemies.

var _elapsed: float = 0.0
const TEST_DURATION: float = 15.0
var _spawned: bool = false

func _initialize() -> void:
	var main_scene = load("res://scenes/main.tscn")
	if main_scene:
		var main = main_scene.instantiate()
		root.add_child(main)

func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed > 2.0 and not _spawned:
		_spawned = true
		_spawn_test_enemies()
	if _elapsed >= TEST_DURATION:
		quit(0)
	return false

func _spawn_test_enemies() -> void:
	var world = root.get_child(0).get_node_or_null("World")
	if not world:
		world = root.find_child("World", true, false)
	if not world:
		return
	var scenes := [
		["res://scenes/enemy_shambler.tscn", Vector2(400, 200)],
		["res://scenes/enemy_shambler.tscn", Vector2(-350, 150)],
		["res://scenes/enemy_runner.tscn", Vector2(250, -300)],
		["res://scenes/enemy_runner.tscn", Vector2(-200, -400)],
		["res://scenes/enemy_bloater.tscn", Vector2(500, -100)],
		["res://scenes/enemy_brute.tscn", Vector2(-500, 300)],
		["res://scenes/enemy_screamer.tscn", Vector2(600, -200)],
		["res://scenes/enemy_swarmer_queen.tscn", Vector2(-400, -300)],
		["res://scenes/enemy_chain.tscn", Vector2(300, 500)],
		["res://scenes/enemy_shambler.tscn", Vector2(-300, -200)],
		["res://scenes/enemy_runner.tscn", Vector2(200, 400)],
		["res://scenes/enemy_bloater.tscn", Vector2(-600, 0)],
	]
	for entry in scenes:
		var path: String = entry[0]
		var pos: Vector2 = entry[1]
		var scene = load(path)
		if scene:
			var enemy = scene.instantiate()
			enemy.global_position = pos
			world.add_child(enemy)
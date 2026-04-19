extends SceneTree
## Task 2 visual test: Loads main scene, lets enemies spawn and combat run for ~10s.
## Run: Godot --write-movie screenshots/task2/test.avi --fixed-fps 30 --script test/test_task.gd

var _elapsed: float = 0.0
const MAX_TIME: float = 12.0

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		push_error("Failed to load main.tscn")
		quit(1)
		return
	var instance = main_scene.instantiate()
	root.add_child(instance)

func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed >= MAX_TIME:
		print("Task 2 test complete. Elapsed: %.1fs" % _elapsed)
		quit(0)
	return false
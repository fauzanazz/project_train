extends SceneTree
## res://test/test_task.gd
## Visual test for Task 1: Train Foundation & World
## Captures screenshots via movie mode, then extracts frames.

var _frame_count: int = 0
var _scene_loaded: bool = false
var _dir: String = "screenshots/task1"

func _initialize() -> void:
	var da = DirAccess.open("res://")
	if da and not da.dir_exists(_dir):
		da.make_dir_recursive(_dir)
	
	# Load main scene
	var main_scene = load("res://scenes/main.tscn")
	if main_scene:
		var instance = main_scene.instantiate()
		get_root().add_child(instance)
		print("Task1: Main scene loaded")
		_scene_loaded = true
	else:
		print("Task1: ERROR - could not load main.tscn")
		quit(1)

func _process(delta: float) -> bool:
	if not _scene_loaded:
		return false
	
	_frame_count += 1
	
	# Simulate mouse position to steer train in a circle
	var angle = _frame_count * 0.015
	var mouse_world = Vector2(cos(angle), sin(angle)) * 300.0
	# Push mouse motion events so locomotive.gd steers toward mouse
	var ev = InputEventMouseMotion.new()
	ev.position = mouse_world + Vector2(640, 360)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	
	# End after 360 frames (~6 seconds at 60fps) 
	if _frame_count >= 360:
		print("Task1: Test complete at frame %d" % _frame_count)
		quit(0)
	
	return false
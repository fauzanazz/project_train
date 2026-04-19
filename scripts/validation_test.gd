extends Node
## res://scripts/validation_test.gd
## Validation test autoload — checks enemy spawning and resource collection.
## Added temporarily to project.godot autoloads for validation runs.

var _elapsed: float = 0.0
var _screenshots_taken: int = 0
var _validation_results: Dictionary = {}
const TEST_DURATION: float = 20.0

func _ready() -> void:
	# Wait for game to fully initialize
	await get_tree().create_timer(0.5).timeout

func _process(delta: float) -> void:
	_elapsed += delta
	
	# Screenshot 1: t=3s — game started, train visible with compartment
	if _elapsed >= 3.0 and _screenshots_taken == 0:
		_screenshots_taken = 1
		_take_screenshot("01_train_started")
		_check_train_compartment()
	
	# Screenshot 2: t=8s — after grace period, enemies should be spawning
	if _elapsed >= 8.0 and _screenshots_taken == 1:
		_screenshots_taken = 2
		_take_screenshot("02_enemies_spawn")
		_check_enemies()
	
	# Drive train to nearest resource node at (700, 200) between t=3 and t=12
	if _elapsed >= 3.0 and _elapsed < 12.0:
		_drive_to_resource()
	
	# Screenshot 3: t=12s — after resource collection attempt
	if _elapsed >= 12.0 and _screenshots_taken == 2:
		_screenshots_taken = 3
		_take_screenshot("03_resource_collect")
		_check_resource_collection()
	
	if _elapsed >= TEST_DURATION:
		_take_screenshot("04_final")
		print("\n=== VALIDATION SUMMARY ===")
		_print_results()
		get_tree().quit(0)

func _check_train_compartment() -> void:
	var train = _find_train()
	if not train:
		_validation_results["train_exists"] = "FAIL: Train node not found"
		return
	_validation_results["train_exists"] = "PASS: Train node found"
	
	var comp_count: int = 0
	if "compartments" in train:
		comp_count = train.compartments.size()
	
	if comp_count >= 1:
		_validation_results["starting_compartment"] = "PASS: Train has %d compartment(s)" % comp_count
	else:
		_validation_results["starting_compartment"] = "FAIL: Train has %d compartments (expected >=1)" % comp_count

func _check_enemies() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var enemy_count: int = enemies.size()
	if enemy_count > 0:
		_validation_results["enemy_spawn"] = "PASS: %d enemy(ies) spawned and in 'enemies' group" % enemy_count
		var e: Node = enemies[0]
		if e.get_script() != null:
			_validation_results["enemy_script"] = "PASS: Enemy has script attached"
		else:
			_validation_results["enemy_script"] = "FAIL: Enemy has no script"
	else:
		_validation_results["enemy_spawn"] = "FAIL: 0 enemies in 'enemies' group after grace period"

func _check_resource_collection() -> void:
	var train = _find_train()
	if not train:
		_validation_results["resource_collect"] = "FAIL: Train not found"
		return
	
	var has_cargo: bool = false
	if "locomotive_cargo" in train and not train.locomotive_cargo.is_empty():
		_validation_results["resource_collect"] = "PASS: Locomotive collected %s (x%d)" % [train.locomotive_cargo, train.locomotive_cargo_amount]
		has_cargo = true
	
	if "compartments" in train:
		for comp in train.compartments:
			if comp and "cargo" in comp and not comp.cargo.is_empty():
				_validation_results["resource_collect_comp"] = "PASS: Compartment collected %s (x%d)" % [comp.cargo, comp.cargo_amount]
				has_cargo = true
	
	if not has_cargo:
		var depleted_count: int = 0
		var nodes: Array = get_tree().get_nodes_in_group("resource_nodes")
		for n in nodes:
			if "depleted" in n and n.depleted:
				depleted_count += 1
		if depleted_count > 0:
			_validation_results["resource_collect"] = "PASS: %d resource node(s) depleted (collected)" % depleted_count
		else:
			_validation_results["resource_collect"] = "FAIL: No cargo collected, no nodes depleted"

func _drive_to_resource() -> void:
	var train = _find_train()
	if not train:
		return
	var loco = train.locomotive if "locomotive" in train else null
	if not loco:
		return
	var target := Vector2(700.0, 200.0)
	var direction: Vector2 = (target - loco.global_position).normalized()
	var speed := 200.0
	loco.velocity = direction * speed
	loco.move_and_slide()

func _find_train() -> Node:
	var scene = get_tree().current_scene
	if scene:
		var train = scene.get_node_or_null("Train")
		if train:
			return train
	# Fallback: search by group
	for node in get_tree().get_nodes_in_group("locomotive"):
		var parent = node.get_parent()
		if parent and parent.has_method("add_compartment"):
			return parent
	return null

func _take_screenshot(label: String) -> void:
	var dir := "screenshots/validation"
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/%s.png" % [dir, label]
	var vp := get_viewport()
	var img := vp.get_texture().get_image()
	img.save_png(path)
	print("Screenshot: %s" % path)

func _print_results() -> void:
	var all_pass := true
	for key in _validation_results:
		var val: String = _validation_results[key]
		var status := "PASS" if val.begins_with("PASS") else "FAIL"
		if val.begins_with("FAIL"):
			all_pass = false
		print("  [%s] %s: %s" % [status, key, val])
	if all_pass:
		print("\n=== ALL CHECKS PASSED ===")
	else:
		print("\n=== SOME CHECKS FAILED ===")

extends SceneTree

const FPS: int = 30
const TOTAL_FRAMES: int = 900

var _frame: int = 0
var _initialized: bool = false

var _main: Node = null
var _world: Node2D = null
var _train: Node = null
var _locomotive: CharacterBody2D = null
var _hud: CanvasLayer = null
var _village: Node2D = null

var _resource_target: Vector2 = Vector2(700, 200)
var _gate_target: Vector2 = Vector2.ZERO

var _horde_spawned: bool = false
var _resource_forced: bool = false
var _delivery_forced: bool = false
var _levelup_triggered: bool = false
var _levelup_selected: bool = false
var _village_upgraded: bool = false
var _boss_spawned: bool = false

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene:
		_main = main_scene.instantiate()
		root.add_child(_main)

func _process(_delta: float) -> bool:
	if not _initialized:
		_initialized = _cache_nodes()
		return false

	var time_sec: float = float(_frame) / float(FPS)
	_drive_timeline(time_sec)

	_frame += 1
	if _frame >= TOTAL_FRAMES:
		quit(0)
	return false

func _cache_nodes() -> bool:
	if not _main:
		return false
	_world = _main.get_node_or_null("World")
	_train = _main.get_node_or_null("Train")
	_hud = _main.get_node_or_null("HUD")
	if not _world or not _train:
		return false
	_locomotive = _train.get_node_or_null("Locomotive")
	if not _locomotive:
		return false
	_village = _world.get_node_or_null("Village")
	if _village:
		_gate_target = _village.global_position + Vector2(0, 160)
	_add_starting_compartments()
	_locomotive.global_position = Vector2(-900, 260)
	_locomotive.rotation = 0.0
	return true

func _add_starting_compartments() -> void:
	if not _train or not _train.has_method("add_compartment"):
		return
	var compartment_scene: PackedScene = load("res://scenes/compartment.tscn")
	if not compartment_scene:
		return
	_train.add_compartment(compartment_scene)
	_train.add_compartment(compartment_scene)

func _drive_timeline(time_sec: float) -> void:
	if time_sec < 6.0:
		if not _horde_spawned and time_sec > 0.8:
			_horde_spawned = true
			_spawn_horde_sequence()
		_follow_target(_snake_target(time_sec))
		_set_speed_multiplier(1.35)
		return

	if time_sec < 10.0:
		_follow_target(_resource_target)
		_set_speed_multiplier(1.2)
		if not _resource_forced and time_sec > 8.4:
			_resource_forced = true
			_force_resource_pickup()
		return

	if time_sec < 14.0:
		_follow_target(_gate_target)
		_set_speed_multiplier(1.0)
		if not _delivery_forced and time_sec > 11.8:
			_delivery_forced = true
			_force_delivery()
		return

	if time_sec < 18.0:
		_follow_target(Vector2(180, 120))
		_set_speed_multiplier(0.85)
		if not _levelup_triggered and time_sec > 14.2:
			_levelup_triggered = true
			_get_player_manager().add_xp(450)
		if not _levelup_selected and time_sec > 15.6:
			_levelup_selected = true
			_select_level_up_card(0)
		return

	if time_sec < 22.0:
		_follow_target(Vector2(40, -40))
		_set_speed_multiplier(0.7)
		if not _village_upgraded and time_sec > 18.5:
			_village_upgraded = true
			_trigger_village_upgrade()
		return

	if not _boss_spawned and time_sec > 22.2:
		_boss_spawned = true
		_spawn_boss_encounter()
	_follow_target(_boss_snake_target(time_sec))
	_set_speed_multiplier(1.25)

func _snake_target(time_sec: float) -> Vector2:
	var x: float = lerp(-860.0, -120.0, clamp(time_sec / 6.0, 0.0, 1.0))
	var y: float = 260.0 + sin(time_sec * 2.8) * 170.0
	return Vector2(x, y)

func _boss_snake_target(time_sec: float) -> Vector2:
	var local_t: float = max(0.0, time_sec - 22.0)
	var x: float = 220.0 + cos(local_t * 0.9) * 380.0
	var y: float = -180.0 + sin(local_t * 1.6) * 280.0
	return Vector2(x, y)

func _follow_target(world_target: Vector2) -> void:
	if not _locomotive:
		return
	var to_target: Vector2 = world_target - _locomotive.global_position
	if to_target.length_squared() < 4.0:
		return
	_locomotive.global_position = _locomotive.global_position.lerp(world_target, 0.04)
	_locomotive.rotation = lerp_angle(_locomotive.rotation, to_target.angle(), 0.1)

func _set_speed_multiplier(target: float) -> void:
	if not _locomotive:
		return
	_locomotive.speed_multiplier = lerp(_locomotive.speed_multiplier, target, 0.08)

func _spawn_horde_sequence() -> void:
	_spawn_enemy("res://scenes/enemy_shambler.tscn", Vector2(-650, 120))
	_spawn_enemy("res://scenes/enemy_shambler.tscn", Vector2(-600, 300))
	_spawn_enemy("res://scenes/enemy_runner.tscn", Vector2(-560, 180))
	_spawn_enemy("res://scenes/enemy_runner.tscn", Vector2(-500, 240))
	_spawn_enemy("res://scenes/enemy_bloater.tscn", Vector2(-740, 210))
	_spawn_enemy("res://scenes/enemy_crawler.tscn", Vector2(-680, 340))

func _spawn_enemy(path: String, pos: Vector2) -> void:
	if not _world:
		return
	var scene: PackedScene = load(path)
	if not scene:
		return
	var enemy: Node2D = scene.instantiate()
	enemy.global_position = pos
	_world.add_child(enemy)

func _force_resource_pickup() -> void:
	if not _locomotive:
		return
	var nearest: Node = null
	var best_dist: float = INF
	for node in root.get_tree().get_nodes_in_group("resource_nodes"):
		if not (node is Node2D) or node.depleted:
			continue
		var d: float = _locomotive.global_position.distance_to(node.global_position)
		if d < best_dist:
			nearest = node
			best_dist = d
	if nearest and nearest.has_method("_on_body_entered"):
		nearest._on_body_entered(_locomotive)

func _force_delivery() -> void:
	if _train and _train.has_method("_deliver_resources"):
		_train._deliver_resources()

func _select_level_up_card(index: int) -> void:
	if not _hud:
		return
	var event := InputEventAction.new()
	event.pressed = true
	event.action = "level_up_%d" % (index + 1)
	_hud._input(event)

func _trigger_village_upgrade() -> void:
	var resource_manager: Node = _get_resource_manager()
	resource_manager.deliver_resources("lumber", 200)
	resource_manager.deliver_resources("metal", 200)
	resource_manager.deliver_resources("medicine", 100)

func _get_player_manager() -> Node:
	return root.get_node("/root/PlayerManager")

func _get_resource_manager() -> Node:
	return root.get_node("/root/ResourceManager")

func _spawn_boss_encounter() -> void:
	_spawn_enemy("res://scenes/boss_locomotive.tscn", Vector2(520, -120))
	_spawn_enemy("res://scenes/enemy_brute.tscn", Vector2(660, -40))
	_spawn_enemy("res://scenes/enemy_screamer.tscn", Vector2(700, -220))
	_spawn_enemy("res://scenes/enemy_chain.tscn", Vector2(780, -140))

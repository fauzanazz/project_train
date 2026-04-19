extends Node
## res://scripts/wave_manager.gd
## Wave scheduling and enemy spawn dispatch. Singleton autoloaded as WaveManager.

# Force-load base class so subclass extends resolve at runtime
const _EnemyBase = preload("res://scripts/enemy_base.gd")

signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal all_clear

@export var grace_period: float = 10.0

const SPAWN_INTERVAL: float = 2.0
const GROUP_SIZE: int = 4

var current_wave: int = 0
var _active_enemies: int = 0
var _enemies_to_spawn: int = 0
var _wave_timer: Timer
var _grace_timer: Timer
var _spawn_timer: Timer
var _spawning: bool = false

var _shambler_scene: PackedScene
var _runner_scene: PackedScene
var _bloater_scene: PackedScene
var _crawler_scene: PackedScene
var _brute_scene: PackedScene
var _screamer_scene: PackedScene
var _swarmer_queen_scene: PackedScene
var _chain_scene: PackedScene
var _boss_scene: PackedScene

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	_wave_timer = Timer.new()
	_wave_timer.one_shot = true
	add_child(_wave_timer)
	_grace_timer = Timer.new()
	_grace_timer.one_shot = true
	_grace_timer.timeout.connect(_begin_next_wave)
	add_child(_grace_timer)
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = SPAWN_INTERVAL
	_spawn_timer.timeout.connect(_spawn_next_group)
	add_child(_spawn_timer)

func _on_game_started() -> void:
	current_wave = 0
	_active_enemies = 0
	_shambler_scene = load("res://scenes/enemy_shambler.tscn")
	_runner_scene = load("res://scenes/enemy_runner.tscn")
	_bloater_scene = load("res://scenes/enemy_bloater.tscn")
	_crawler_scene = load("res://scenes/enemy_crawler.tscn")
	_brute_scene = load("res://scenes/enemy_brute.tscn")
	_screamer_scene = load("res://scenes/enemy_screamer.tscn")
	_swarmer_queen_scene = load("res://scenes/enemy_swarmer_queen.tscn")
	_chain_scene = load("res://scenes/enemy_chain.tscn")
	_boss_scene = load("res://scenes/boss_locomotive.tscn")
	_grace_timer.start(grace_period * 0.5)

func _begin_next_wave() -> void:
	current_wave += 1
	_spawning = true
	_enemies_to_spawn = _wave_enemy_count(current_wave)
	# Boss at wave 10
	if current_wave == 10:
		_spawn_boss()
	wave_started.emit(current_wave)
	_spawn_timer.start(SPAWN_INTERVAL)
	_spawn_next_group()

func _wave_enemy_count(wave: int) -> int:
	return 5 + (wave - 1) * 3

func _spawn_next_group() -> void:
	if _enemies_to_spawn <= 0:
		_spawn_timer.stop()
		_spawning = false
		return
	var count := mini(GROUP_SIZE, _enemies_to_spawn)
	for _i in count:
		_spawn_one_enemy()
		_enemies_to_spawn -= 1
	if _enemies_to_spawn <= 0:
		_spawn_timer.stop()
		_spawning = false

func _spawn_one_enemy() -> void:
	var scene := _pick_enemy_scene()
	if not scene:
		return
	# Check for elite replacement
	if current_wave >= 6 and _pick_elite_chance():
		var elite_scene := _pick_elite_scene()
		if elite_scene:
			scene = elite_scene
	var enemy = scene.instantiate()
	enemy.global_position = _get_spawn_position()
	var world = _find_world()
	if world:
		world.add_child(enemy)
	_active_enemies += 1

func _pick_elite_chance() -> bool:
	var chance: float = DifficultyManager.get_elite_chance(current_wave)
	return randf() < chance

func _pick_elite_scene() -> PackedScene:
	var roll := randf()
	if roll < 0.3:
		return _brute_scene
	elif roll < 0.55:
		return _screamer_scene
	elif roll < 0.8:
		return _swarmer_queen_scene
	else:
		return _chain_scene

func _spawn_boss() -> void:
	if not _boss_scene:
		return
	var boss = _boss_scene.instantiate()
	boss.global_position = _get_spawn_position()
	var world = _find_world()
	if world:
		world.add_child(boss)
	_active_enemies += 1

func _pick_enemy_scene() -> PackedScene:
	if current_wave <= 4:
		return _shambler_scene
	var roll := randf()
	if current_wave <= 6:
		if roll < 0.5:
			return _shambler_scene
		elif roll < 0.8:
			return _runner_scene
		else:
			return _crawler_scene
	if roll < 0.3:
		return _shambler_scene
	elif roll < 0.55:
		return _runner_scene
	elif roll < 0.75:
		return _bloater_scene
	else:
		return _crawler_scene

func _get_spawn_position() -> Vector2:
	var corridors := [
		Vector2(-1600, 0), Vector2(1600, 0),
		Vector2(0, -1600), Vector2(0, 1600),
	]
	# Try to use World's spawn corridors if available
	var world = _find_world()
	if world and world.has_method("get_spawn_corridor"):
		var idx := randi() % 4
		return world.get_spawn_corridor(idx) + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	var base: Vector2 = corridors[randi() % corridors.size()]
	return base + Vector2(randf_range(-80, 80), randf_range(-80, 80))

func _find_world() -> Node:
	if get_tree() and get_tree().current_scene:
		var w = get_tree().current_scene.get_node_or_null("World")
		if w:
			return w
		return get_tree().current_scene
	return null

func register_enemy_death() -> void:
	_active_enemies = max(0, _active_enemies - 1)
	if _active_enemies == 0 and not _spawning and _enemies_to_spawn <= 0:
		_spawning = false
		wave_ended.emit(current_wave)
		all_clear.emit()
		_grace_timer.start(grace_period)

func get_wave_time_remaining() -> float:
	return _grace_timer.time_left if not _spawning else 0.0

func get_active_enemy_count() -> int:
	return _active_enemies
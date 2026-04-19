extends Node
## res://scripts/wave_manager.gd
## Wave scheduling and enemy spawn dispatch. Singleton autoloaded as WaveManager.

signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal all_clear

@export var grace_period: float = 10.0

var current_wave: int = 0
var _active_enemies: int = 0
var _wave_timer: Timer
var _grace_timer: Timer
var _spawning: bool = false

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	_wave_timer = Timer.new()
	_wave_timer.one_shot = true
	_wave_timer.timeout.connect(_begin_next_wave)
	add_child(_wave_timer)
	_grace_timer = Timer.new()
	_grace_timer.one_shot = true
	_grace_timer.timeout.connect(_begin_next_wave)
	add_child(_grace_timer)

func _on_game_started() -> void:
	current_wave = 0
	_active_enemies = 0
	_grace_timer.start(grace_period)

func _begin_next_wave() -> void:
	current_wave += 1
	_active_enemies = 0
	_spawning = true
	wave_started.emit(current_wave)
	# Actual enemy spawning implemented in Task 2

func register_enemy_death() -> void:
	_active_enemies = max(0, _active_enemies - 1)
	if _active_enemies == 0 and _spawning:
		_spawning = false
		wave_ended.emit(current_wave)
		all_clear.emit()
		_grace_timer.start(grace_period)

func get_wave_time_remaining() -> float:
	return _grace_timer.time_left if not _spawning else 0.0

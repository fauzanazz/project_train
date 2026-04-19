extends Node
## res://scripts/game_manager.gd
## Global event bus and scene lifecycle manager. Singleton — autoloaded as GameManager.

signal game_started
signal game_over(wave_index: int)
signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)

var is_running: bool = false

func _ready() -> void:
	pass

func start_game() -> void:
	is_running = true
	game_started.emit()

func end_game(wave_index: int) -> void:
	is_running = false
	game_over.emit(wave_index)

func _on_village_destroyed() -> void:
	end_game(WaveManager.current_wave)

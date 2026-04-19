extends Node
## res://scripts/difficulty_manager.gd
## Stat scaling formulas driven by wave index and player level. Singleton autoloaded as DifficultyManager.

func get_enemy_hp(base_hp: float, wave_index: int) -> float:
	return base_hp * (1.0 + 0.15 * wave_index)

func get_enemy_speed(base_speed: float, wave_index: int) -> float:
	return base_speed * (1.0 + 0.05 * wave_index)

func get_enemy_count(base_count: int, player_level: int) -> int:
	return int(base_count * (1.0 + 0.1 * player_level))

func get_elite_chance(wave_index: int) -> float:
	return min(0.05 * wave_index, 0.4)

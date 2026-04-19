extends Node2D
## res://scripts/village.gd
## Village walls, HP, turret management, and visual tier upgrades.

signal village_damaged(amount: float, new_hp: float)
signal village_destroyed

const TIER_HP_BONUS: Array[float] = [1.0, 1.25, 1.75, 2.5, 4.0]
const BASE_HP: float = 500.0

var hp: float = BASE_HP
var max_hp: float = BASE_HP
var tier: int = 0
var turrets: Array = []

func _ready() -> void:
	ResourceManager.village_upgraded.connect(_on_village_upgraded)

func take_damage(amount: float) -> void:
	hp -= amount
	village_damaged.emit(amount, hp)
	if hp <= 0.0:
		village_destroyed.emit()

func repair(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	village_damaged.emit(0.0, hp)

func _on_village_upgraded(new_tier: int) -> void:
	tier = new_tier
	max_hp = BASE_HP * TIER_HP_BONUS[new_tier]
	hp = min(hp, max_hp)
	queue_redraw()
	# Turret spawning implemented in Task 2

func _draw() -> void:
	pass  # Visual drawing implemented in Task 1

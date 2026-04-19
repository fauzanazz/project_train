extends Node
## res://scripts/resource_manager.gd
## Village resource ledger and upgrade state. Singleton autoloaded as ResourceManager.

signal resources_changed(lumber: int, metal: int, medicine: int)
signal village_upgraded(new_tier: int)

const TIER_THRESHOLDS: Array[Dictionary] = [
	{},  # Tier 0 — start state, no requirements
	{"lumber": 50},  # Tier 1
	{"metal": 50, "lumber": 30},  # Tier 2
	{"metal": 100, "lumber": 50},  # Tier 3
	{"metal": 150, "lumber": 100, "medicine": 50},  # Tier 4
]

var lumber: int = 0
var metal: int = 0
var medicine: int = 0
var village_tier: int = 0

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	WaveManager.wave_ended.connect(_on_wave_ended)

func _on_game_started() -> void:
	lumber = 0
	metal = 0
	medicine = 0
	village_tier = 0

func deliver_resources(type: String, amount: int) -> void:
	match type:
		"lumber": lumber += amount
		"metal": metal += amount
		"medicine": medicine += amount
	resources_changed.emit(lumber, metal, medicine)
	_check_upgrade()

func _check_upgrade() -> void:
	if village_tier >= TIER_THRESHOLDS.size() - 1:
		return
	var next: Dictionary = TIER_THRESHOLDS[village_tier + 1]
	if lumber >= next.get("lumber", 0) and metal >= next.get("metal", 0) and medicine >= next.get("medicine", 0):
		village_tier += 1
		village_upgraded.emit(village_tier)

func _on_wave_ended(_wave: int) -> void:
	# Passive generator ticks added in Task 2
	pass

func _on_zombie_killed(_xp: int, _position: Vector2, resource_drop: Dictionary) -> void:
	if resource_drop.is_empty():
		return
	deliver_resources(resource_drop.get("type", ""), resource_drop.get("amount", 0))

func _on_train_destroyed(cargo: Array) -> void:
	# Cargo lost on destruction — no refund
	pass

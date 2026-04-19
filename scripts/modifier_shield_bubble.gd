extends "res://scripts/modifier_base.gd"
## res://scripts/modifier_shield_bubble.gd
## Absorbs damage, cooldown after breaking. Visual: translucent blue circle around compartment.

const BASE_SHIELD_CAPACITY: float = 100.0
const BASE_COOLDOWN: float = 30.0

signal shield_absorbed(amount: float)
signal shield_broken

var shield_capacity: float = BASE_SHIELD_CAPACITY
var cooldown_time: float = BASE_COOLDOWN
var shield_hp: float = BASE_SHIELD_CAPACITY
var _cooldown_timer: float = 0.0
var active: bool = true

func _init() -> void:
	id = "shield_bubble"
	display_name = "Shield Bubble"
	tier = ModifierTier.BASIC
	slot_type = SlotType.UTILITY
	upgrade_names = PackedStringArray(["Reinforced Shield", "Quick Recharge"])
	upgrade_descs = PackedStringArray(["Shield 100 → 175", "Cooldown 30s → 18s"])

func get_max_level() -> int:
	return 3

func tick(dt: float) -> void:
	if not active:
		_cooldown_timer -= dt
		if _cooldown_timer <= 0.0:
			active = true
			shield_hp = shield_capacity

func absorb_damage(amount: float) -> float:
	if not active:
		return amount
	var absorbed: float = min(shield_hp, amount)
	shield_hp -= absorbed
	if shield_hp <= 0.0:
		active = false
		_cooldown_timer = cooldown_time
		shield_broken.emit()
	else:
		shield_absorbed.emit(absorbed)
	return amount - absorbed

func get_shield_visual() -> Dictionary:
	return {"active": active, "ratio": shield_hp / shield_capacity if active else 0.0}

func on_level_up(new_level: int) -> void:
	super(new_level)
	shield_capacity = BASE_SHIELD_CAPACITY
	cooldown_time = BASE_COOLDOWN
	if new_level >= 2:
		shield_capacity = 175.0
	if new_level >= 3:
		cooldown_time = 18.0
	if active:
		shield_hp = shield_capacity

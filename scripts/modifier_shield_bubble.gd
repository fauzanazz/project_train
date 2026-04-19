extends "res://scripts/modifier_base.gd"
## res://scripts/modifier_shield_bubble.gd
## Absorbs next 100 damage, 30s cooldown. Visual: translucent blue circle around compartment.

const SHIELD_CAPACITY: float = 100.0
const COOLDOWN: float = 30.0

signal shield_absorbed(amount: float)
signal shield_broken

var shield_hp: float = SHIELD_CAPACITY
var _cooldown_timer: float = 0.0
var active: bool = true

func _init() -> void:
	id = "shield_bubble"
	display_name = "Shield Bubble"
	tier = ModifierTier.BASIC
	slot_type = SlotType.UTILITY

func tick(dt: float) -> void:
	if not active:
		_cooldown_timer -= dt
		if _cooldown_timer <= 0.0:
			active = true
			shield_hp = SHIELD_CAPACITY

func absorb_damage(amount: float) -> float:
	## Returns remaining damage after shield absorption.
	if not active:
		return amount
	var absorbed: float = min(shield_hp, amount)
	shield_hp -= absorbed
	if shield_hp <= 0.0:
		active = false
		_cooldown_timer = COOLDOWN
		shield_broken.emit()
	else:
		shield_absorbed.emit(absorbed)
	return amount - absorbed

func get_shield_visual() -> Dictionary:
	return {"active": active, "ratio": shield_hp / SHIELD_CAPACITY if active else 0.0}
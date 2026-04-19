extends "res://scripts/modifier_base.gd"
## res://scripts/modifier_repair_drone.gd
## Repairs 2 HP/s on the compartment it's mounted on.

const HEAL_PER_SEC: float = 2.0

func _init() -> void:
	id = "repair_drone"
	display_name = "Repair Drone"
	tier = ModifierTier.BASIC
	slot_type = SlotType.UTILITY

func tick(dt: float) -> void:
	if not _compartment:
		return
	if _compartment.has_method("take_damage"):
		_compartment.hp = min(_compartment.hp + HEAL_PER_SEC * dt, _compartment.max_hp)
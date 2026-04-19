extends Node
## res://scripts/modifier_base.gd
## Base class for all weapon, utility, and passive modifiers.

signal projectile_spawn(origin: Vector2, direction: Vector2, data: Dictionary)

enum ModifierTier { BASIC, ADVANCED, ELITE }
enum SlotType { WEAPON, UTILITY, PASSIVE }

var id: String = ""
var display_name: String = ""
var tier: ModifierTier = ModifierTier.BASIC
var slot_type: SlotType = SlotType.WEAPON

var _compartment: Node = null
var _upgrade_count: int = 0

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	_compartment = compartment

func on_detach() -> void:
	_compartment = null

func tick(dt: float) -> void:
	pass

func on_level_up(upgrade_count: int) -> void:
	_upgrade_count = upgrade_count

func serialize() -> Dictionary:
	return {"id": id, "upgrade_count": _upgrade_count}

func deserialize(data: Dictionary) -> void:
	_upgrade_count = data.get("upgrade_count", 0)

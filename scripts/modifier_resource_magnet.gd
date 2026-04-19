extends "res://scripts/modifier_base.gd"
## res://scripts/modifier_resource_magnet.gd
## Attracts nearby resource nodes toward train per tick. 200px range, 100 units/s.

const BASE_ATTRACT_RANGE: float = 200.0
const BASE_ATTRACT_SPEED: float = 100.0

var attract_range: float = BASE_ATTRACT_RANGE
var attract_speed: float = BASE_ATTRACT_SPEED
var attracts_xp: bool = false

func _init() -> void:
	id = "resource_magnet"
	display_name = "Resource Magnet"
	tier = ModifierTier.BASIC
	slot_type = SlotType.UTILITY
	upgrade_names = PackedStringArray(["Wide Field", "XP Attraction"])
	upgrade_descs = PackedStringArray(["+50% pull radius", "Attracts XP orbs too"])

func get_max_level() -> int:
	return 3

func tick(dt: float) -> void:
	if not _compartment:
		return
	var nodes = _compartment.get_tree().get_nodes_in_group("resource_nodes") if _compartment.get_tree() else []
	for rn in nodes:
		if not rn is Node2D or rn.get("depleted"):
			continue
		var dist: float = _compartment.global_position.distance_to(rn.global_position)
		if dist < attract_range and dist > 5.0:
			var dir: Vector2 = _compartment.global_position - rn.global_position
			rn.global_position += dir.normalized() * attract_speed * dt

func on_level_up(new_level: int) -> void:
	super(new_level)
	attract_range = BASE_ATTRACT_RANGE
	attract_speed = BASE_ATTRACT_SPEED
	attracts_xp = false
	if new_level >= 2:
		attract_range *= 1.5
	if new_level >= 3:
		attracts_xp = true

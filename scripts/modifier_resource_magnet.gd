extends "res://scripts/modifier_base.gd"
## res://scripts/modifier_resource_magnet.gd
## Attracts nearby resource nodes toward train per tick. 200px range, 100 units/s.

const ATTRACT_RANGE: float = 200.0
const ATTRACT_SPEED: float = 100.0

func _init() -> void:
	id = "resource_magnet"
	display_name = "Resource Magnet"
	tier = ModifierTier.BASIC
	slot_type = SlotType.UTILITY

func tick(dt: float) -> void:
	if not _compartment:
		return
	var nodes = _compartment.get_tree().get_nodes_in_group("resource_nodes") if _compartment.get_tree() else []
	for rn in nodes:
		if not rn is Node2D or rn.get("depleted"):
			continue
		var dist: float = _compartment.global_position.distance_to(rn.global_position)
		if dist < ATTRACT_RANGE and dist > 5.0:
			var dir: Vector2 = _compartment.global_position - rn.global_position
			rn.global_position += dir.normalized() * ATTRACT_SPEED * dt
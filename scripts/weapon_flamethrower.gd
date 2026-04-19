extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_flamethrower.gd
## Flamethrower Mk1 — continuous cone AoE fire damage at short range.

const BASE_DAMAGE_PER_SEC: float = 5.0
const BASE_RANGE: float = 150.0
const CONE_ANGLE: float = 0.6  # radians half-angle

var damage_per_sec: float = BASE_DAMAGE_PER_SEC
var range_px: float = BASE_RANGE
var _flame_area: Area2D = null

func _init() -> void:
	id = "flamethrower_mk1"
	display_name = "Flamethrower"
	tier = ModifierTier.BASIC
	slot_type = SlotType.WEAPON

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	# Cone AoE constructed at runtime in Task 2

func tick(dt: float) -> void:
	if not _compartment:
		return
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment.get_tree() else []
	for e in enemies:
		if not e is Node2D:
			continue
		var to_e: Vector2 = e.global_position - _compartment.global_position
		if to_e.length() > range_px:
			continue
		var angle_diff: float = abs(to_e.angle() - _compartment.rotation)
		if angle_diff > CONE_ANGLE:
			continue
		if e.has_method("take_damage"):
			e.take_damage(damage_per_sec * dt, "fire")

func on_level_up(upgrade_count: int) -> void:
	super(upgrade_count)
	damage_per_sec = BASE_DAMAGE_PER_SEC + upgrade_count * 2.0
	range_px = BASE_RANGE + upgrade_count * 20.0

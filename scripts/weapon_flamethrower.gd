extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_flamethrower.gd
## Flamethrower Mk1 — continuous cone AoE fire damage at short range.

const BASE_DAMAGE_PER_SEC: float = 5.0
const BASE_RANGE: float = 150.0
const BASE_CONE_ANGLE: float = 0.6

var damage_per_sec: float = BASE_DAMAGE_PER_SEC
var range_px: float = BASE_RANGE
var cone_angle: float = BASE_CONE_ANGLE
var sticky_fuel: bool = false
var death_explosion: bool = false

func _init() -> void:
	id = "flamethrower_mk1"
	display_name = "Flamethrower"
	tier = ModifierTier.BASIC
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Extended Nozzle", "Sticky Fuel", "Wide Cone", "Infernal Pressure"])
	upgrade_descs = PackedStringArray(["Range +40%", "Burn lingers 2s", "Cone angle +50%", "Damage +100%, death explosion"])

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)

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
		if angle_diff > cone_angle:
			continue
		if e.has_method("take_damage"):
			e.take_damage(damage_per_sec * dt, "fire")

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage_per_sec = BASE_DAMAGE_PER_SEC
	range_px = BASE_RANGE
	cone_angle = BASE_CONE_ANGLE
	sticky_fuel = false
	death_explosion = false
	if new_level >= 2:
		range_px *= 1.4
	if new_level >= 3:
		sticky_fuel = true
	if new_level >= 4:
		cone_angle *= 1.5
	if new_level >= 5:
		damage_per_sec *= 2.0
		death_explosion = true

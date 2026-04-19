extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_mortar.gd
## Mortar Mk1 — lobbed projectile, explosive AoE on landing.

const BASE_DAMAGE: float = 35.0
const BASE_FIRE_RATE: float = 2.0
const BASE_RANGE: float = 400.0
const BASE_AOE_RADIUS: float = 60.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var aoe_radius: float = BASE_AOE_RADIUS
var _cooldown: float = 0.0

func _init() -> void:
	id = "mortar_mk1"
	display_name = "Mortar"
	tier = ModifierTier.BASIC
	slot_type = SlotType.WEAPON

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0

func tick(dt: float) -> void:
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	var target = _find_nearest_enemy()
	if not target:
		return
	_fire_at(target)
	_cooldown = fire_rate

func _find_nearest_enemy() -> Node:
	if not _compartment:
		return null
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment.get_tree() else []
	var nearest: Node = null
	var nearest_dist: float = range_px * range_px
	for e in enemies:
		if not e is Node2D:
			continue
		var d: float = _compartment.global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func _fire_at(target: Node) -> void:
	if not _compartment or not target is Node2D:
		return
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	projectile_spawn.emit(_compartment.global_position, dir, {
		"damage": damage,
		"range": range_px,
		"type": "explosive",
		"piercing": 0,
		"aoe_radius": aoe_radius,
		"arc": true,
	})

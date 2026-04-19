extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_railgun.gd
## Rail Cannon — kinetic, instant pierce through all enemies in line.

const BASE_DAMAGE: float = 80.0
const BASE_FIRE_RATE: float = 3.5
const BASE_RANGE: float = 600.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var _cooldown: float = 0.0

func _init() -> void:
	id = "railgun_mk1"
	display_name = "Rail Cannon"
	tier = ModifierTier.ADVANCED
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
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	projectile_spawn.emit(_compartment.global_position, dir, {
		"damage": damage,
		"range": range_px,
		"type": "kinetic",
		"piercing": 999,  # pierce all
		"aoe_radius": 0.0,
		"instant": true,
	})
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

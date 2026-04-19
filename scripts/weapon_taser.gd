extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_taser.gd
## Taser Mk1 — electric, slows target 50% on hit.

const BASE_DAMAGE: float = 12.0
const BASE_FIRE_RATE: float = 0.8
const BASE_RANGE: float = 250.0
const SLOW_FACTOR: float = 0.5
const SLOW_DURATION: float = 2.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var _cooldown: float = 0.0

func _init() -> void:
	id = "taser_mk1"
	display_name = "Taser"
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
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	projectile_spawn.emit(_compartment.global_position, dir, {
		"damage": damage,
		"range": range_px,
		"type": "electric",
		"piercing": 0,
		"aoe_radius": 0.0,
		"slow_factor": SLOW_FACTOR,
		"slow_duration": SLOW_DURATION,
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

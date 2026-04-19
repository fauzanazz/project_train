extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_tesla.gd
## Tesla Coil — electric, chains lightning to up to 3 nearby enemies.

const BASE_DAMAGE: float = 30.0
const BASE_FIRE_RATE: float = 1.2
const BASE_RANGE: float = 280.0
const CHAIN_COUNT: int = 3
const CHAIN_RANGE: float = 150.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var _cooldown: float = 0.0

func _init() -> void:
	id = "tesla_mk1"
	display_name = "Tesla Coil"
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
	_chain_lightning(target)
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

func _chain_lightning(first_target: Node) -> void:
	var hit: Array = [first_target]
	if first_target.has_method("take_damage"):
		first_target.take_damage(damage, "electric")
	# Chain to nearby
	var source: Node2D = first_target
	for _i in CHAIN_COUNT - 1:
		var next = _find_chain_target(source, hit)
		if not next:
			break
		if next.has_method("take_damage"):
			next.take_damage(damage * 0.7, "electric")
		hit.append(next)
		source = next

func _find_chain_target(source: Node2D, exclude: Array) -> Node:
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment.get_tree() else []
	var nearest: Node = null
	var nearest_dist: float = CHAIN_RANGE * CHAIN_RANGE
	for e in enemies:
		if e in exclude or not e is Node2D:
			continue
		var d: float = source.global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

class_name ModifierBase
extends Node
## res://scripts/modifier_base.gd
## Base class for all weapon, utility, and passive modifiers.

signal projectile_spawn(origin: Vector2, direction: Vector2, data: Dictionary)

enum ModifierTier { BASIC, ADVANCED, ELITE }
enum SlotType { WEAPON, UTILITY, PASSIVE }
enum TargetingMode { PLAYER_CENTER, MOUSE_POINTER }

static var targeting_mode: TargetingMode = TargetingMode.PLAYER_CENTER
static var targeting_origin: Vector2 = Vector2.ZERO
static var targeting_position: Vector2 = Vector2.ZERO
static var has_target: bool = false

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

func _find_target(search_range: float) -> Node2D:
	if not _compartment:
		return null
	var tree := _compartment.get_tree()
	if not tree:
		return null
	var enemies := tree.get_nodes_in_group("enemies")
	var reference_pos: Vector2
	match targeting_mode:
		TargetingMode.PLAYER_CENTER:
			reference_pos = _compartment.global_position
		TargetingMode.MOUSE_POINTER:
			reference_pos = _compartment.get_global_mouse_position()
	var nearest: Node2D = null
	var nearest_dist: float = search_range * search_range
	for e in enemies:
		if not e is Node2D:
			continue
		var d: float = reference_pos.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	targeting_origin = _compartment.global_position
	if nearest:
		targeting_position = nearest.global_position
		has_target = true
	else:
		has_target = false
	return nearest

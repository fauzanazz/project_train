extends Node2D
## res://scripts/compartment.gd
## Follows the position history of the segment ahead. Holds modifier slot and cargo bay.

signal compartment_destroyed(index: int)

const FOLLOW_SPACING: int = 18  # frames back in position history to follow
const BASE_HP: float = 80.0
const LERP_SPEED: float = 12.0

@export var index: int = 0

var hp: float = BASE_HP
var max_hp: float = BASE_HP
var cargo: String = ""  # empty string = empty bay
var cargo_amount: int = 0
var modifier: Node = null  # IModifier child node

var _target_source: Node = null  # locomotive or previous compartment

func _ready() -> void:
	pass

func setup(target: Node) -> void:
	_target_source = target

func _physics_process(delta: float) -> void:
	if not _target_source:
		return
	# Get position from history: locomotive stores it, compartments read from it
	var history: Array = _get_history()
	if history.size() == 0:
		return
	var target_idx: int = min(FOLLOW_SPACING * (index + 1), history.size() - 1)
	var target_pos: Vector2 = history[target_idx]
	var target_rot: float = 0.0
	if target_idx + 1 < history.size():
		var prev_pos: Vector2 = history[target_idx + 1]
		target_rot = (target_pos - prev_pos).angle()
	global_position = global_position.lerp(target_pos, LERP_SPEED * delta)
	rotation = lerp_angle(rotation, target_rot, LERP_SPEED * delta)

func _get_history() -> Array:
	# Walk up to locomotive
	var loco = _find_locomotive()
	if loco and loco.has_method("get") and "position_history" in loco:
		return loco.position_history
	return []

func _find_locomotive() -> Node:
	var parent = get_parent()
	while parent:
		if parent.has_node("Locomotive"):
			return parent.get_node("Locomotive")
		parent = parent.get_parent()
	return null

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		compartment_destroyed.emit(index)
		queue_free()

func get_cargo() -> Array:
	if cargo.is_empty():
		return []
	return [{"type": cargo, "amount": cargo_amount}]

func clear_cargo() -> void:
	cargo = ""
	cargo_amount = 0

func load_cargo(type: String, amount: int) -> bool:
	if not cargo.is_empty():
		return false
	cargo = type
	cargo_amount = amount
	return true

func attach_modifier(mod: Node) -> void:
	if modifier:
		modifier.queue_free()
	modifier = mod
	add_child(mod)
	if mod.has_method("on_attach"):
		mod.on_attach(self)

func _draw() -> void:
	pass  # Visual drawing implemented in Task 1 as custom draw

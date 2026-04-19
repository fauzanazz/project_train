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
	# Walk up to find the Train node, then get its Locomotive child
	var parent = get_parent()
	while parent:
		if parent is Node2D and parent.name == "CompartmentContainer":
			var train = parent.get_parent()
			if train and train.has_node("Locomotive"):
				return train.get_node("Locomotive")
		parent = parent.get_parent()
	# Fallback: search by group
	var locos = get_tree().get_nodes_in_group("locomotive") if get_tree() else []
	return locos[0] if locos.size() > 0 else null

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

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Cargo box ~50×28, top-down cartoonist style
	const BODY_COLOR := Color("#7A7875")
	const OUTLINE_COLOR := Color("#111111")
	const ACCENT_COLOR := Color("#D2691E")
	const WHEEL_RIM := Color("#888888")
	const CARGO_COLORS := {
		"lumber": Color("#22C55E"),
		"metal": Color("#EAB308"),
		"medicine": Color("#3B82F6")
	}

	# Main box
	draw_rect(Rect2(-25, -14, 50, 28), BODY_COLOR)
	draw_rect(Rect2(-25, -14, 50, 28), OUTLINE_COLOR, false, 2.0)

	# Accent marks
	draw_rect(Rect2(-23, -5, 8, 10), ACCENT_COLOR)
	draw_rect(Rect2(15, -5, 8, 10), ACCENT_COLOR)

	# Cargo color fill when loaded
	if not cargo.is_empty() and CARGO_COLORS.has(cargo):
		var c: Color = CARGO_COLORS[cargo]
		draw_rect(Rect2(-12, -8, 24, 16), c)
		draw_rect(Rect2(-12, -8, 24, 16), OUTLINE_COLOR, false, 1.5)

	# 4 small wheels
	var wheel_positions := [
		Vector2(-14, -16), Vector2(12, -16),
		Vector2(-14, 16), Vector2(12, 16)
	]
	for wp: Vector2 in wheel_positions:
		draw_circle(wp, 5.0, OUTLINE_COLOR)
		draw_circle(wp, 3.5, WHEEL_RIM)

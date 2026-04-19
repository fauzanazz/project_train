extends Node2D
## res://scripts/compartment.gd
## Follows position history of segment ahead. Holds modifier slot and cargo bay.

signal compartment_destroyed(index: int)

const FOLLOW_SPACING: int = 18
const BASE_HP: float = 80.0
const LERP_SPEED: float = 12.0

@export var index: int = 0

var hp: float = BASE_HP
var max_hp: float = BASE_HP
var cargo: String = ""
var cargo_amount: int = 0
var modifier: Node = null
var _target_source: Node = null
var _flash_timer: float = 0.0

func _ready() -> void:
	pass

func setup(target: Node) -> void:
	_target_source = target

func _physics_process(delta: float) -> void:
	if not _target_source:
		return
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
	# Tick modifier
	if modifier and modifier.has_method("tick"):
		modifier.tick(delta)

func _get_history() -> Array:
	var loco = _find_locomotive()
	if loco and "position_history" in loco:
		return loco.position_history
	return []

func _find_locomotive() -> Node:
	var parent = get_parent()
	while parent:
		if parent.name == "CompartmentContainer":
			var train = parent.get_parent()
			if train and train.has_node("Locomotive"):
				return train.get_node("Locomotive")
		parent = parent.get_parent()
	var locos = get_tree().get_nodes_in_group("locomotive") if get_tree() else []
	return locos[0] if locos.size() > 0 else null

func take_damage(amount: float) -> void:
	# Check for shield bubble on modifier
	if modifier and modifier.has_method("absorb_damage"):
		var remaining: float = modifier.absorb_damage(amount)
		amount = remaining
	hp -= amount
	_flash_timer = 0.1
	if hp <= 0.0:
		_die()

func _die() -> void:
	compartment_destroyed.emit(index)
	# Brief flash animation before removal
	var flash_tween := create_tween()
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	flash_tween.tween_callback(queue_free)

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
	_flash_timer = max(0.0, _flash_timer - _delta)
	queue_redraw()

func _draw() -> void:
	const BODY_COLOR := Color("#7A7875")
	const OUTLINE := Color("#111111")
	const ACCENT := Color("#D2691E")
	const WHEEL_RIM := Color("#888888")
	const CARGO_COLORS := {
		"lumber": Color("#22C55E"),
		"metal": Color("#EAB308"),
		"medicine": Color("#3B82F6")
	}
	# Damage tint
	var body_color := BODY_COLOR
	if hp < max_hp * 0.5:
		body_color = BODY_COLOR.lerp(Color("#AA4444"), 0.3)
	# Flash on damage
	if _flash_timer > 0.0:
		body_color = body_color.lerp(Color.WHITE, _flash_timer * 5.0)
	draw_rect(Rect2(-25, -14, 50, 28), body_color)
	draw_rect(Rect2(-25, -14, 50, 28), OUTLINE, false, 2.0)
	draw_rect(Rect2(-23, -5, 8, 10), ACCENT)
	draw_rect(Rect2(15, -5, 8, 10), ACCENT)
	if not cargo.is_empty() and CARGO_COLORS.has(cargo):
		var c: Color = CARGO_COLORS[cargo]
		draw_rect(Rect2(-12, -8, 24, 16), c)
		draw_rect(Rect2(-12, -8, 24, 16), OUTLINE, false, 1.5)
	var wheel_positions := [
		Vector2(-14, -16), Vector2(12, -16),
		Vector2(-14, 16), Vector2(12, 16)
	]
	for wp: Vector2 in wheel_positions:
		draw_circle(wp, 5.0, OUTLINE)
		draw_circle(wp, 3.5, WHEEL_RIM)
	# HP indicator bar if damaged
	if hp < max_hp:
		var bar_w := 40.0
		var ratio := hp / max_hp
		draw_rect(Rect2(-20, -18, bar_w, 3), Color("#333333"))
		draw_rect(Rect2(-20, -18, bar_w * ratio, 3), Color("#22CC22") if ratio > 0.5 else Color("#FF4444"))
	# Shield bubble visual
	if modifier and modifier.has_method("get_shield_visual"):
		var shield_info: Dictionary = modifier.get_shield_visual()
		if shield_info.get("active", false):
			var ratio: float = shield_info.get("ratio", 0.0)
			var alpha := 0.3 + 0.2 * sin(Time.get_ticks_msec() / 300.0)
			draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(0.3, 0.6, 1.0, alpha), 2.0)
			draw_arc(Vector2.ZERO, 20.0, 0.0, TAU * ratio, 24, Color(0.3, 0.6, 1.0, 0.6), 3.0)
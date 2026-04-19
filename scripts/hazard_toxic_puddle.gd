extends Area2D
## res://scripts/hazard_toxic_puddle.gd
## Toxic Puddle — damages and slows train on contact.

signal hazard_activated

@export var damage_per_sec: float = 5.0
@export var slow_factor: float = 0.8  # 20% slow
const CONTACT_LAYER := 1  # player layer
const CONTACT_MASK := 1

var _active: bool = true

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 32  # hazards (layer 6)
	collision_mask = 1    # player
	_connect_body_signals()

func _connect_body_signals() -> void:
	if has_node("CollisionShape2D"):
		pass  # Area2D signals connected via area_entered/body_entered
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	# Slow the locomotive
	var loco = _find_locomotive_from(body)
	if loco:
		loco.speed_multiplier *= slow_factor

func _on_body_exited(body: Node) -> void:
	var loco = _find_locomotive_from(body)
	if loco:
		loco.speed_multiplier = max(1.0, loco.speed_multiplier / slow_factor)

func _find_locomotive_from(body: Node) -> Node:
	if body.is_in_group("locomotive"):
		return body
	var parent = body.get_parent()
	while parent:
		if parent.is_in_group("locomotive"):
			return parent
		parent = parent.get_parent()
	return null

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Green-brown (#4A7A3E) splat shape
	const PUDDLE_COLOR := Color("#4A7A3E")
	const DARK_COLOR := Color("#3A5A2E")
	const OUTLINE := Color("#222222")
	# Irregular splat using overlapping circles
	draw_circle(Vector2(-8, 5), 18.0, PUDDLE_COLOR)
	draw_circle(Vector2(8, -3), 20.0, PUDDLE_COLOR)
	draw_circle(Vector2(-4, -10), 15.0, PUDDLE_COLOR)
	draw_circle(Vector2(10, 10), 14.0, DARK_COLOR)
	draw_circle(Vector2(-12, -6), 12.0, DARK_COLOR)
	# Outline blobs
	draw_arc(Vector2(-8, 5), 18.0, 0.0, TAU, 24, OUTLINE, 2.0)
	draw_arc(Vector2(8, -3), 20.0, 0.0, TAU, 24, OUTLINE, 2.0)
	# Bubbles
	var time := Time.get_ticks_msec() / 1000.0
	for i in 3:
		var bx := -10.0 + i * 10.0
		var by := -8.0 + 4.0 * sin(time * 2.0 + i * 1.5)
		draw_circle(Vector2(bx, by), 3.0, Color("#6ABA6A88"))
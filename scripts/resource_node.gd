extends Area2D
## res://scripts/resource_node.gd
## Resource pickup node — drive over to collect into cargo bay.

signal resource_collected(type: String, amount: int, node: Node)

@export var resource_type: String = "lumber"  # "lumber" | "metal" | "medicine"
@export var yield_amount: int = 10
@export var respawn_time: float = 60.0

var depleted: bool = false
var _pulse_time: float = 0.0
var _respawn_timer: Timer

const TYPE_COLORS := {
	"lumber":   Color("#22C55E"),
	"metal":    Color("#EAB308"),
	"medicine": Color("#3B82F6"),
}
const DEPLETED_COLOR := Color("#6B7280")
const OUTLINE_COLOR := Color("#111111")

func _ready() -> void:
	add_to_group("resource_nodes")
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_on_respawn)
	add_child(_respawn_timer)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not depleted:
		_pulse_time += delta
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if depleted:
		return
	if not body.is_in_group("train_body"):
		return
	var train = _find_train(body)
	if train and train.has_method("try_collect_resource"):
		if train.try_collect_resource(resource_type, yield_amount):
			_deplete()

func _find_train(body: Node) -> Node:
	# Check if body itself has the method (it's the train root)
	if body.has_method("try_collect_resource"):
		return body
	var parent = body.get_parent()
	while parent:
		if parent.has_method("try_collect_resource"):
			return parent
		parent = parent.get_parent()
	return null

func _deplete() -> void:
	depleted = true
	resource_collected.emit(resource_type, yield_amount, self)
	queue_redraw()
	_respawn_timer.start(respawn_time)

func _on_respawn() -> void:
	depleted = false
	_pulse_time = 0.0
	queue_redraw()

func _draw() -> void:
	if depleted:
		# Gray, smaller, no glow
		draw_circle(Vector2.ZERO, 14.0, DEPLETED_COLOR)
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, OUTLINE_COLOR, 2.0)
		return

	# Pulsing glow
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 3.0)
	var glow_r := 20.0 + 6.0 * pulse
	var base_color: Color = TYPE_COLORS.get(resource_type, DEPLETED_COLOR)
	var glow_color := Color(base_color.r, base_color.g, base_color.b, 0.3 * pulse)
	draw_circle(Vector2.ZERO, glow_r, glow_color)

	# Filled main circle
	draw_circle(Vector2.ZERO, 18.0, base_color)
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, OUTLINE_COLOR, 2.5)

	# Icon inside
	match resource_type:
		"lumber":
			_draw_lumber_icon()
		"metal":
			_draw_metal_icon()
		"medicine":
			_draw_medicine_icon()

func _draw_lumber_icon() -> void:
	# Simple log shape: brown rectangle
	draw_rect(Rect2(-8, -5, 16, 10), Color("#5C3317"))
	draw_rect(Rect2(-8, -5, 16, 10), OUTLINE_COLOR, false, 1.5)
	# Tree top
	draw_circle(Vector2(0, -8), 6.0, Color("#166534"))
	draw_arc(Vector2(0, -8), 6.0, 0.0, TAU, 20, OUTLINE_COLOR, 1.5)

func _draw_metal_icon() -> void:
	# Gear-like shape: hexagonal bolt
	var points := PackedVector2Array()
	for i in 6:
		var angle := i * TAU / 6.0 - PI / 6.0
		points.append(Vector2(cos(angle), sin(angle)) * 9.0)
	draw_polygon(points, [Color("#5C4A00")])
	draw_polyline(PackedVector2Array(Array(points) + [points[0]]), OUTLINE_COLOR, 1.5)
	draw_circle(Vector2.ZERO, 4.0, Color("#D4A017"))

func _draw_medicine_icon() -> void:
	# Cross shape
	draw_rect(Rect2(-3, -9, 6, 18), Color("#FFFFFF"))
	draw_rect(Rect2(-9, -3, 18, 6), Color("#FFFFFF"))
	draw_rect(Rect2(-3, -9, 6, 18), OUTLINE_COLOR, false, 1.5)
	draw_rect(Rect2(-9, -3, 18, 6), OUTLINE_COLOR, false, 1.5)

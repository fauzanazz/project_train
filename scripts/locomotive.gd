extends CharacterBody2D
## res://scripts/locomotive.gd
## Mouse-cursor steering, speed, and position history management for the train chain.

const BASE_SPEED: float = 200.0
const HISTORY_LENGTH: int = 120  # frames of position history for compartment lerp
const MIN_ZOOM: float = 0.8
const MAX_ZOOM: float = 1.2

# Draw constants — top-down cartoonist locomotive ~60×30
const BODY_COLOR := Color("#8B8680")
const CAB_COLOR := Color("#5C5855")
const ACCENT_COLOR := Color("#D2691E")
const OUTLINE_COLOR := Color("#111111")
const WHEEL_RIM_COLOR := Color("#888888")

@export var turn_speed: float = 3.5  # radians/s at base speed

var current_speed: float = BASE_SPEED
var speed_multiplier: float = 1.0
var position_history: Array = []
var _camera: Camera2D

func _ready() -> void:
	add_to_group("locomotive")
	add_to_group("train_body")
	_camera = get_viewport().get_camera_2d()
	if _camera:
		_camera.make_current()
	# Pre-fill history
	for i in HISTORY_LENGTH:
		position_history.append(global_position)

func _physics_process(delta: float) -> void:
	_steer_toward_mouse(delta)
	_move(delta)
	_push_history()
	_update_camera_zoom()

func _process(_delta: float) -> void:
	queue_redraw()

func _steer_toward_mouse(delta: float) -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = (mouse_world - global_position)
	if to_mouse.length_squared() < 400.0:
		return
	var target_angle: float = to_mouse.angle()
	# Turning radius inversely proportional to speed — faster = wider turns
	var effective_turn: float = turn_speed * (BASE_SPEED / max(current_speed, 1.0))
	rotation = lerp_angle(rotation, target_angle, effective_turn * delta)

func _move(delta: float) -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(rotation)
	velocity = dir * current_speed * speed_multiplier
	move_and_slide()

func _push_history() -> void:
	position_history.push_front(global_position)
	if position_history.size() > HISTORY_LENGTH:
		position_history.pop_back()

func _update_camera_zoom() -> void:
	if not _camera:
		_camera = get_viewport().get_camera_2d()
	if not _camera:
		return
	var speed_ratio: float = (current_speed * speed_multiplier) / BASE_SPEED
	var target_zoom: float = lerp(MAX_ZOOM, MIN_ZOOM, (speed_ratio - 1.0))
	target_zoom = clamp(target_zoom, MIN_ZOOM, MAX_ZOOM)
	_camera.zoom = _camera.zoom.lerp(Vector2(target_zoom, target_zoom), 0.05)

func get_speed_ratio() -> float:
	return (current_speed * speed_multiplier) / BASE_SPEED

func _draw() -> void:
	# Body — warm gray rounded rect 60×30
	draw_rect(Rect2(-30, -15, 60, 30), BODY_COLOR)
	draw_rect(Rect2(-30, -15, 60, 30), OUTLINE_COLOR, false, 3.0)

	# Cab at front (right side in local space)
	draw_rect(Rect2(8, -13, 20, 26), CAB_COLOR)
	draw_rect(Rect2(8, -13, 20, 26), OUTLINE_COLOR, false, 2.0)

	# Rust orange accent stripe
	draw_rect(Rect2(-28, -4, 60, 8), ACCENT_COLOR)

	# Smokestack nub at very front
	draw_circle(Vector2(26, 0), 5.0, OUTLINE_COLOR)
	draw_circle(Vector2(26, 0), 4.0, CAB_COLOR)

	# 4 wheels: two left, two right
	var wheel_positions := [
		Vector2(-16, -17), Vector2(10, -17),
		Vector2(-16, 17), Vector2(10, 17)
	]
	for wp: Vector2 in wheel_positions:
		draw_circle(wp, 7.0, OUTLINE_COLOR)
		draw_circle(wp, 5.5, WHEEL_RIM_COLOR)

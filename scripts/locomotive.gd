extends CharacterBody2D
## res://scripts/locomotive.gd
## A/D keyboard drift control, position history, and body damage to enemies.

const _MB = preload("res://scripts/modifier_base.gd")

const BASE_SPEED: float = 200.0
const HISTORY_LENGTH: int = 120
const MIN_ZOOM: float = 0.8
const MAX_ZOOM: float = 1.2

const BODY_COLOR := Color("#8B8680")
const CAB_COLOR := Color("#5C5855")
const ACCENT_COLOR := Color("#D2691E")
const OUTLINE_COLOR := Color("#111111")
const WHEEL_RIM_COLOR := Color("#888888")

@export var turn_speed: float = 3.5

var current_speed: float = BASE_SPEED
var speed_multiplier: float = 1.0
var position_history: Array = []
var _camera: Camera2D
var _weapon: Node = null

func _ready() -> void:
	add_to_group("locomotive")
	add_to_group("train_body")
	_camera = get_viewport().get_camera_2d()
	if _camera:
		_camera.make_current()
	for i in HISTORY_LENGTH:
		position_history.append(global_position)

func _physics_process(delta: float) -> void:
	_steer_with_keys(delta)
	_move(delta)
	_push_history()
	_update_camera_zoom()
	if _weapon and _weapon.has_method("tick"):
		_weapon.tick(delta)

func _process(_delta: float) -> void:
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("target_mode_toggle"):
		_toggle_targeting_mode()

func _steer_with_keys(delta: float) -> void:
	var effective_turn: float = turn_speed * (BASE_SPEED / maxf(current_speed, 1.0))
	if Input.is_action_pressed("steer_left"):
		rotation -= effective_turn * delta
	if Input.is_action_pressed("steer_right"):
		rotation += effective_turn * delta

func _toggle_targeting_mode() -> void:
	if _MB.targeting_mode == _MB.TargetingMode.PLAYER_CENTER:
		_MB.targeting_mode = _MB.TargetingMode.MOUSE_POINTER
	else:
		_MB.targeting_mode = _MB.TargetingMode.PLAYER_CENTER

func _move(delta: float) -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(rotation)
	velocity = dir * current_speed * speed_multiplier
	move_and_slide()
	# Clamp to map bounds (1600 half-size minus margin)
	var half := 1580.0
	global_position.x = clampf(global_position.x, -half, half)
	global_position.y = clampf(global_position.y, -half, half)

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

func attach_weapon(weapon_node: Node) -> void:
	_weapon = weapon_node

func take_damage(amount: float, _damage_type: String = "kinetic") -> void:
	var train = get_parent()
	if train and train.has_method("take_damage"):
		train.take_damage(amount)

func get_weapon() -> Node:
	return _weapon

func _draw() -> void:
	draw_rect(Rect2(-30, -15, 60, 30), BODY_COLOR)
	draw_rect(Rect2(-30, -15, 60, 30), OUTLINE_COLOR, false, 3.0)
	draw_rect(Rect2(8, -13, 20, 26), CAB_COLOR)
	draw_rect(Rect2(8, -13, 20, 26), OUTLINE_COLOR, false, 2.0)
	draw_rect(Rect2(-28, -4, 60, 8), ACCENT_COLOR)
	draw_circle(Vector2(26, 0), 5.0, OUTLINE_COLOR)
	draw_circle(Vector2(26, 0), 4.0, CAB_COLOR)
	var wheel_positions := [
		Vector2(-16, -17), Vector2(10, -17),
		Vector2(-16, 17), Vector2(10, 17)
	]
	for wp: Vector2 in wheel_positions:
		draw_circle(wp, 7.0, OUTLINE_COLOR)
		draw_circle(wp, 5.5, WHEEL_RIM_COLOR)
	# Targeting line from weapon origin to current target
	if _MB.has_target:
		var origin_local := to_local(_MB.targeting_origin)
		var target_local := to_local(_MB.targeting_position)
		draw_line(origin_local, target_local, Color(1.0, 1.0, 0.3, 0.25), 1.0)
		draw_circle(target_local, 4.0, Color(1.0, 0.3, 0.3, 0.4))
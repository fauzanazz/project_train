extends CharacterBody2D
## res://scripts/locomotive.gd
## Mouse-cursor steering, speed, and position history management for the train chain.

const BASE_SPEED: float = 200.0
const HISTORY_LENGTH: int = 120  # frames of position history for compartment lerp
const MIN_ZOOM: float = 0.8
const MAX_ZOOM: float = 1.2

@export var turn_speed: float = 3.5  # radians/s at base speed

var current_speed: float = BASE_SPEED
var speed_multiplier: float = 1.0
var position_history: Array = []
var _camera: Camera2D

func _ready() -> void:
	_camera = get_viewport().get_camera_2d()
	# Pre-fill history
	for i in HISTORY_LENGTH:
		position_history.append(global_position)

func _physics_process(delta: float) -> void:
	_steer_toward_mouse(delta)
	_move(delta)
	_push_history()
	_update_camera_zoom()

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
		return
	var speed_ratio: float = (current_speed * speed_multiplier) / BASE_SPEED
	var target_zoom: float = lerp(MAX_ZOOM, MIN_ZOOM, (speed_ratio - 1.0))
	target_zoom = clamp(target_zoom, MIN_ZOOM, MAX_ZOOM)
	_camera.zoom = _camera.zoom.lerp(Vector2(target_zoom, target_zoom), 0.05)

func get_speed_ratio() -> float:
	return (current_speed * speed_multiplier) / BASE_SPEED

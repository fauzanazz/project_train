extends Node
## res://scripts/screen_shake.gd
## Autoload accessible via ScreenShake.shake(duration, intensity).

var _shake_duration: float = 0.0
var _shake_intensity: float = 0.0
var _camera: Camera2D = null

func shake(duration: float, intensity: float) -> void:
	_shake_duration = duration
	_shake_intensity = intensity

func _process(delta: float) -> void:
	if _shake_duration > 0.0:
		_shake_duration -= delta
		if not _camera:
			_camera = get_viewport().get_camera_2d() if get_viewport() else null
		if _camera:
			var offset := Vector2(randf_range(-1, 1) * _shake_intensity, randf_range(-1, 1) * _shake_intensity)
			_camera.offset = offset
	else:
		if _camera:
			_camera.offset = Vector2.ZERO
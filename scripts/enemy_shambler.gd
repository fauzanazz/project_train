extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_shambler.gd
## Shambler zombie — slow, tanky, paths to village.

func _draw_body() -> void:
	# Desaturated green (#6B8E6B), wobbly proportions, thick outline ~24x24
	const BODY := Color("#6B8E6B")
	const OUTLINE := Color("#111111")
	const DARK := Color("#3A5A3A")
	# Wobbly body — slightly offset circles for asymmetry
	draw_circle(Vector2(-2, 1), 11.0, BODY)
	draw_circle(Vector2(3, -1), 10.0, BODY)
	draw_circle(Vector2(1, 3), 9.0, BODY)
	# Thick outline as primitives
	draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 24, OUTLINE, 3.0)
	# Head
	draw_circle(Vector2(0, -10), 7.0, DARK)
	draw_arc(Vector2(0, -10), 7.0, 0.0, TAU, 16, OUTLINE, 2.0)
	# Eyes
	draw_circle(Vector2(-3, -11), 2.0, Color("#FF4444"))
	draw_circle(Vector2(3, -11), 2.0, Color("#FF4444"))
	# Arms — stubby sticks
	draw_line(Vector2(-12, 0), Vector2(-18, 5), DARK, 3.0)
	draw_line(Vector2(12, 0), Vector2(18, -3), DARK, 3.0)
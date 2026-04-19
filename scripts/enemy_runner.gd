extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_runner.gd
## Runner zombie — fast, fragile, chases the player.

func _draw_body() -> void:
	# Purple-tinted (#8B668B), thin and fast-looking, motion lines ~18x18
	const BODY := Color("#8B668B")
	const OUTLINE := Color("#111111")
	const DARK := Color("#5A3A5A")
	# Thin angular body
	var pts := PackedVector2Array([
		Vector2(-7, -8), Vector2(7, -8), Vector2(9, 0),
		Vector2(7, 8), Vector2(-7, 8), Vector2(-9, 0)
	])
	draw_polygon(pts, [BODY])
	draw_polyline(PackedVector2Array(Array(pts) + [pts[0]]), OUTLINE, 2.0)
	# Head smaller, forward-leaning
	draw_circle(Vector2(0, -9), 5.0, DARK)
	draw_arc(Vector2(0, -9), 5.0, 0.0, TAU, 12, OUTLINE, 2.0)
	# Glowing eyes
	draw_circle(Vector2(-2, -10), 1.5, Color("#FF66FF"))
	draw_circle(Vector2(2, -10), 1.5, Color("#FF66FF"))
	# Motion lines behind
	draw_line(Vector2(-12, 0), Vector2(-18, -2), Color("#8B668B88"), 1.5)
	draw_line(Vector2(-12, 3), Vector2(-20, 4), Color("#8B668B88"), 1.5)
	draw_line(Vector2(-11, -3), Vector2(-17, -5), Color("#8B668B88"), 1.5)
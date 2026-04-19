extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_crawler.gd
## Crawler zombie — flat gray-green, low profile, hybrid AI.

func _draw_body() -> void:
	# Flat gray-green silhouette, low profile ~20x20
	const BODY := Color("#6B7A6B")
	const OUTLINE := Color("#111111")
	const DARK := Color("#4A5A4A")
	# Flat wide body
	draw_rect(Rect2(-10, -5, 20, 10), BODY)
	draw_rect(Rect2(-10, -5, 20, 10), OUTLINE, false, 2.0)
	# Segmented look
	draw_line(Vector2(-8, -1), Vector2(8, -1), DARK, 1.0)
	draw_line(Vector2(-8, 2), Vector2(8, 2), DARK, 1.0)
	# Head — oval shape via polygon
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0 - PI * 0.5
		var rx := 5.0
		var ry := 3.5
		var px := cos(angle) * rx
		var py := -7.0 + sin(angle) * ry
		pts.append(Vector2(px, py))
	var colors := PackedColorArray([DARK])
	draw_polygon(pts, colors)
	draw_polyline(PackedVector2Array(Array(pts) + [pts[0]]), OUTLINE, 1.5)
	# Eyes
	draw_circle(Vector2(-3, -7), 1.5, Color("#CCCCCC"))
	draw_circle(Vector2(3, -7), 1.5, Color("#CCCCCC"))
	# Legs
	draw_line(Vector2(-8, 5), Vector2(-9, 9), DARK, 2.0)
	draw_line(Vector2(-4, 5), Vector2(-5, 9), DARK, 2.0)
	draw_line(Vector2(4, 5), Vector2(5, 9), DARK, 2.0)
	draw_line(Vector2(8, 5), Vector2(9, 9), DARK, 2.0)
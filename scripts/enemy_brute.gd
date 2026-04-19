extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_brute.gd
## Armored Brute — 300 HP, slow, kinetic-resistant, paths to village.

func _ready() -> void:
	super._ready()
	add_to_group("elites")

func _draw_body() -> void:
	# Large dark gray (#4A4A4A), thick armor plates as overlapping rectangles
	const BODY := Color("#4A4A4A")
	const OUTLINE := Color("#111111")
	const PLATE := Color("#5A5A5A")
	const DARK := Color("#333333")
	# Main body
	draw_rect(Rect2(-14, -14, 28, 28), BODY)
	draw_rect(Rect2(-14, -14, 28, 28), OUTLINE, false, 3.0)
	# Overlapping armor plates
	draw_rect(Rect2(-12, -10, 24, 8), PLATE)
	draw_rect(Rect2(-10, 2, 20, 8), PLATE)
	draw_rect(Rect2(-8, 8, 16, 6), PLATE)
	# Head
	draw_circle(Vector2(0, -16), 8.0, DARK)
	draw_arc(Vector2(0, -16), 8.0, 0.0, TAU, 16, OUTLINE, 2.0)
	# Eyes — small, determined
	draw_circle(Vector2(-3, -17), 2.0, Color("#FF4444"))
	draw_circle(Vector2(3, -17), 2.0, Color("#FF4444"))
	# Armor rivets
	draw_circle(Vector2(-10, -6), 1.5, Color("#888888"))
	draw_circle(Vector2(10, -6), 1.5, Color("#888888"))
	draw_circle(Vector2(-8, 6), 1.5, Color("#888888"))
	draw_circle(Vector2(8, 6), 1.5, Color("#888888"))

func _apply_resistances(amount: float, damage_type: String) -> float:
	if damage_type == "kinetic":
		return amount * 0.5
	return amount

func _get_radius() -> float:
	return 14.0
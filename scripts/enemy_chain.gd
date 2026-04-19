extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_chain.gd
## Chain Zombie — 200 HP, electric-resistant, can pull train toward it briefly.

var _pull_timer: float = 0.0
var _pull_target: Vector2 = Vector2.ZERO
const PULL_DURATION: float = 0.5

func _ready() -> void:
	super._ready()
	add_to_group("elites")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _pull_timer > 0.0:
		_pull_timer -= delta
		# Lerp train toward chain zombie position
		var loco = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
		if loco:
			loco.global_position = loco.global_position.lerp(global_position, 0.03)

func _on_body_contact_train() -> void:
	if _pull_timer <= 0.0:
		_pull_timer = PULL_DURATION
		_pull_target = global_position

func _apply_resistances(amount: float, damage_type: String) -> float:
	if damage_type == "electric":
		return amount * 0.5
	return amount

func _draw_body() -> void:
	# Bright green chains (#2ECC71), chain links drawn around body
	const BODY := Color("#2ECC71")
	const OUTLINE := Color("#111111")
	const CHAIN := Color("#1ABC9C")
	const DARK := Color("#1A9A4A")
	# Main body
	draw_circle(Vector2.ZERO, 12.0, BODY)
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, OUTLINE, 2.5)
	# Chain links around body
	for i in 8:
		var angle := i * TAU / 8.0
		var cx := cos(angle) * 16.0
		var cy := sin(angle) * 16.0
		draw_rect(Rect2(cx - 3, cy - 2, 6, 4), CHAIN)
		draw_rect(Rect2(cx - 3, cy - 2, 6, 4), OUTLINE, false, 1.0)
	# Head
	draw_circle(Vector2(0, -10), 7.0, DARK)
	draw_arc(Vector2(0, -10), 7.0, 0.0, TAU, 14, OUTLINE, 2.0)
	# Eyes — electric spark
	draw_circle(Vector2(-3, -11), 2.0, Color("#00FFFF"))
	draw_circle(Vector2(3, -11), 2.0, Color("#00FFFF"))
	# Pull indicator
	if _pull_timer > 0.0:
		var alpha := _pull_timer / PULL_DURATION
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 16, Color(0.18, 0.8, 0.44, alpha), 2.0)

func _get_radius() -> float:
	return 12.0
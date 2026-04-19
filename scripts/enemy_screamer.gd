extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_screamer.gd
## Screamer — 60 HP, fast, buffs nearby zombies +30% speed, paths to player.

var _pulse_time: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group("elites")

func _process(delta: float) -> void:
	_pulse_time += delta
	super._process(delta)

func _draw_body() -> void:
	# Purple (#9B59B6), pulsing shockwave rings
	const BODY := Color("#9B59B6")
	const OUTLINE := Color("#111111")
	const DARK := Color("#6A3A8A")
	const AURA := Color("#9B59B68A")
	# Pulsing aura rings
	var pulse_alpha := 0.3 + 0.3 * sin(_pulse_time * 5.0)
	var ring_r := 20.0 + 4.0 * sin(_pulse_time * 4.0)
	draw_circle(Vector2.ZERO, ring_r, Color(AURA.r, AURA.g, AURA.b, pulse_alpha))
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 24, Color(BODY.r, BODY.g, BODY.b, pulse_alpha + 0.2), 2.0)
	# Main body — smaller center
	draw_circle(Vector2.ZERO, 11.0, BODY)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, OUTLINE, 2.5)
	# Head
	draw_circle(Vector2(0, -11), 6.0, DARK)
	draw_arc(Vector2(0, -11), 6.0, 0.0, TAU, 14, OUTLINE, 2.0)
	# Wide eyes
	draw_circle(Vector2(-4, -12), 3.0, Color("#FF66FF"))
	draw_circle(Vector2(4, -12), 3.0, Color("#FF66FF"))
	# Mouth — open screaming
	draw_rect(Rect2(-3, -7, 6, 4), Color("#4A1A6A"))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_buff_nearby_zombies(delta)

func _buff_nearby_zombies(delta: float) -> void:
	if not get_tree():
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self:
			continue
		if not e is Node2D:
			continue
		var dist: float = global_position.distance_to(e.global_position)
		if dist < 120.0 and e.has_method("apply_slow"):
			# +30% speed boost = 1.3 multiplier, override slow
			e.speed_multiplier_temp = 1.3

func _get_radius() -> float:
	return 11.0
extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_bloater.gd
## Bloater zombie — fat, slow, explodes on death dealing AoE.

const EXPLOSION_RADIUS: float = 80.0
const EXPLOSION_DAMAGE: float = 25.0

var _pulse_time: float = 0.0

func _process(delta: float) -> void:
	_pulse_time += delta

func _draw_body() -> void:
	# Fat green round body, pulsing outline ~32x32
	const BODY := Color("#4A7A4A")
	const OUTLINE := Color("#111111")
	const PULSE := Color("#8AFF8A")
	const DARK := Color("#2A5A2A")
	var pulse_factor := 1.0 + 0.08 * sin(_pulse_time * 4.0)
	# Fat body
	draw_circle(Vector2.ZERO, 15.0 * pulse_factor, BODY)
	draw_arc(Vector2.ZERO, 15.0 * pulse_factor + 1.0, 0.0, TAU, 24, PULSE, 2.5)
	draw_arc(Vector2.ZERO, 15.0 * pulse_factor + 3.0, 0.0, TAU, 24, OUTLINE, 3.0)
	# Head (small, embedded in body)
	draw_circle(Vector2(0, -14), 6.0, DARK)
	draw_arc(Vector2(0, -14), 6.0, 0.0, TAU, 16, OUTLINE, 2.0)
	# Sunken eyes
	draw_circle(Vector2(-3, -15), 2.0, Color("#FF6644"))
	draw_circle(Vector2(3, -15), 2.0, Color("#FF6644"))
	# Pustules
	draw_circle(Vector2(-10, 5), 3.0, Color("#6AE86A"))
	draw_circle(Vector2(8, -3), 2.5, Color("#6AE86A"))
	draw_circle(Vector2(3, 10), 3.0, Color("#6AE86A"))

func _die() -> void:
	# AoE explosion before normal death
	var enemies = get_tree().get_nodes_in_group("enemies") if get_tree() else []
	# Damage train compartments in range
	var train = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	if train:
		var train_root = train.get_parent()
		if train_root and "compartments" in train_root:
			for comp in train_root.compartments:
				if comp.global_position.distance_to(global_position) <= EXPLOSION_RADIUS:
					comp.take_damage(EXPLOSION_DAMAGE * 0.5)
	if train and train.global_position.distance_to(global_position) <= EXPLOSION_RADIUS:
		train.get_parent().take_damage(EXPLOSION_DAMAGE * 0.3)
	# Visual explosion effect
	_spawn_explosion_effect()
	super._die()

func _spawn_explosion_effect() -> void:
	var effect = Node2D.new()
	effect.set_script(_create_explosion_script())
	effect.global_position = global_position
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(effect)

func _create_explosion_script() -> Script:
	var src = "
extends Node2D
var _time := 0.5
var _radius := 80.0
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var ratio := maxf(0, _time / 0.5)
	var r := _radius * (1.0 - ratio)
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.6, 0.2, ratio * 0.6))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.4, ratio * 0.8))"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script
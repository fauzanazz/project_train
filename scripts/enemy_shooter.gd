extends "res://scripts/enemy_base.gd"
## res://scripts/enemy_shooter.gd
## Ranged zombie that stops and shoots projectiles at the player.

const SHOOT_RANGE: float = 300.0
const SHOOT_COOLDOWN: float = 2.0
const PROJECTILE_SPEED: float = 250.0
const PROJECTILE_DAMAGE: float = 8.0

var _shoot_timer: float = 0.0
var _is_shooting: bool = false

func _ready() -> void:
	super._ready()
	max_hp = 40.0
	base_speed = 45.0
	body_damage = 3.0
	wall_damage = 2.0
	xp_value = 15
	ai_type = AIType.HYBRID
	hybrid_switch_range = 400.0
	_shoot_timer = SHOOT_COOLDOWN * 0.5  # First shot comes faster

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _dying:
		return
	# Handle shooting
	if _shoot_timer > 0.0:
		_shoot_timer -= delta
	# Check if player is in range
	var player_pos := _find_player_position()
	var dist: float = global_position.distance_to(player_pos)
	if dist < SHOOT_RANGE and _shoot_timer <= 0.0:
		_fire_projectile(player_pos)
		_shoot_timer = SHOOT_COOLDOWN
	_is_shooting = dist < SHOOT_RANGE

func _fire_projectile(target_pos: Vector2) -> void:
	var dir: Vector2 = global_position.direction_to(target_pos)
	# Spawn a projectile aimed at the player
	var proj_scene: PackedScene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return
	var proj = proj_scene.instantiate()
	proj.setup(global_position + dir * 15.0, dir, {
		"damage": PROJECTILE_DAMAGE,
		"range": 400.0,
		"type": "kinetic",
		"speed": PROJECTILE_SPEED,
		"piercing": 0,
		"is_enemy": true,
	})
	# Add to world
	var world = get_tree().current_scene.get_node_or_null("World") if get_tree() else null
	if world:
		world.add_child(proj)
	elif get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(proj)

func _draw_body() -> void:
	# Green zombie body with a protruding "arm" holding a projectile
	var body_color := Color("#4A7A3E")
	var arm_color := Color("#6B8E6B")
	var outline := Color("#111111")
	# Main body
	draw_circle(Vector2.ZERO, 11.0, body_color)
	draw_circle(Vector2.ZERO, 11.0, outline, false, 2.0)
	# Arm holding projectile (pointing in movement direction)
	var arm_dir := Vector2.RIGHT.rotated(rotation)
	var arm_end := arm_dir * 18.0
	draw_line(Vector2.ZERO, arm_end, arm_color, 3.0)
	# Projectile in hand
	draw_circle(arm_end, 3.5, Color("#FFD700"))
	draw_circle(arm_end, 3.5, outline, false, 1.0)
	# Eye
	var eye_offset := Vector2(3.0, -3.0).rotated(rotation)
	draw_circle(eye_offset, 2.5, Color.WHITE)
	draw_circle(eye_offset + Vector2(1.0, 0.0).rotated(rotation), 1.5, Color.RED)

func _get_radius() -> float:
	return 11.0

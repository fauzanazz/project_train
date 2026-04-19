extends CharacterBody2D
## res://scripts/boss_locomotive.gd
## The Locomotive boss — zombie-infested enemy train, chases player, heavy body damage.

signal boss_killed(xp: int, position: Vector2)

const BOSS_HP: float = 2000.0
const BOSS_SPEED: float = 100.0
const CONTACT_DAMAGE: float = 30.0
const XP_REWARD: int = 200

var hp: float = BOSS_HP
var max_hp: float = BOSS_HP
var speed: float = BOSS_SPEED
var _nav_agent: NavigationAgent2D
var _flash_timer: float = 0.0
var _segment_positions: Array = []
const SEGMENT_COUNT: int = 3
const SEGMENT_SPACING: float = 50.0
const FOLLOW_DELAY: int = 8

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_nav_agent = $NavigationAgent2D if has_node("NavigationAgent2D") else null
	if not _nav_agent:
		_nav_agent = NavigationAgent2D.new()
		_nav_agent.name = "NavigationAgent2D"
		_nav_agent.path_desired_distance = 20.0
		_nav_agent.target_desired_distance = 20.0
		add_child(_nav_agent)
	# Initialize segment positions
	for i in SEGMENT_COUNT:
		_segment_positions.append(global_position)
	# Initialize position history for segments
	position_history.append(global_position)
	position_history.append(global_position)
	position_history.append(global_position)

var position_history: Array = []
const HISTORY_LENGTH: int = 60

func _physics_process(delta: float) -> void:
	var target := _find_player_position()
	if _nav_agent:
		_nav_agent.target_position = target
		var next_pos: Vector2 = _nav_agent.get_next_path_position()
		var dir: Vector2 = (next_pos - global_position)
		if dir.length_squared() > 4.0:
			velocity = dir.normalized() * speed
			rotation = dir.angle()
		else:
			velocity = Vector2.ZERO
	else:
		var dir: Vector2 = (target - global_position)
		if dir.length_squared() > 100.0:
			velocity = dir.normalized() * speed
			rotation = dir.angle()
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	# Push position history for segments
	position_history.push_front(global_position)
	if position_history.size() > HISTORY_LENGTH:
		position_history.pop_back()
	# Deal contact damage to train and village
	_check_contact_damage(delta)
	_flash_timer = max(0.0, _flash_timer - delta)

func _process(_delta: float) -> void:
	queue_redraw()

func _find_player_position() -> Vector2:
	var loco = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	return loco.global_position if loco else Vector2.ZERO

func _check_contact_damage(delta: float) -> void:
	# Damage train on contact
	var loco = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	if loco:
		var dist: float = global_position.distance_to(loco.global_position)
		if dist < 50.0:
			var train_root = loco.get_parent()
			if train_root and train_root.has_method("take_damage"):
				train_root.take_damage(CONTACT_DAMAGE * delta)
	# Damage village on contact
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if village:
		var dist: float = global_position.distance_to(village.global_position)
		if dist < 170.0:
			village.take_damage(CONTACT_DAMAGE * 0.5 * delta)

func take_damage(amount: float, damage_type: String = "kinetic") -> void:
	hp -= amount
	_flash_timer = 0.15
	if hp <= 0.0:
		_die()

func _die() -> void:
	PlayerManager.add_xp(XP_REWARD)
	WaveManager.register_enemy_death()
	_boss_death_effect()
	queue_free()

func _boss_death_effect() -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	var effect = Node2D.new()
	effect.set_script(_create_boss_death_script())
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)
	ScreenShake.shake(0.5, 20.0)

func _create_boss_death_script() -> Script:
	var src = "
extends Node2D
var _time := 1.0
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var ratio := max(0, _time / 1.0)
	var r := 120.0 * (1.0 - ratio)
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.3, 0.1, ratio * 0.5))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 0.8, 0.2, ratio * 0.7))
	draw_circle(Vector2.ZERO, r * 0.2, Color(1.0, 1.0, 0.8, ratio))"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _draw() -> void:
	# Much larger than player train — dark rusted (#3C2415) with spikes and skull emblem
	const BODY_COLOR := Color("#3C2415")
	const RUST := Color("#5C3A1A")
	const OUTLINE := Color("#111111")
	const SPIKE := Color("#4A4A4A")
	const SKULL := Color("#DDDDDD")
	# Flash white on hit
	var body_color := BODY_COLOR
	if _flash_timer > 0.0:
		body_color = BODY_COLOR.lerp(Color.WHITE, _flash_timer * 4.0)
	# Main body — much larger than player (80x40 vs 60x30)
	draw_rect(Rect2(-40, -20, 80, 40), body_color)
	draw_rect(Rect2(-40, -20, 80, 40), OUTLINE, false, 3.0)
	# Cab
	draw_rect(Rect2(12, -18, 24, 36), RUST)
	draw_rect(Rect2(12, -18, 24, 36), OUTLINE, false, 2.5)
	# Rust streaks
	draw_line(Vector2(-30, -10), Vector2(10, -12), RUST, 2.0)
	draw_line(Vector2(-25, 5), Vector2(5, 8), RUST, 2.0)
	# Skull emblem at front
	draw_circle(Vector2(-35, 0), 8.0, SKULL)
	draw_circle(Vector2(-35, 0), 8.0, OUTLINE, false, 1.5)
	# Skull eyes
	draw_circle(Vector2(-38, -2), 2.0, Color("#111111"))
	draw_circle(Vector2(-32, -2), 2.0, Color("#111111"))
	# Spikes along top
	for i in 5:
		var sx := -30.0 + i * 14.0
		draw_polygon(PackedVector2Array([Vector2(sx, -20), Vector2(sx + 3, -28), Vector2(sx + 6, -20)]), [SPIKE])
		draw_polygon(PackedVector2Array([Vector2(sx, -20), Vector2(sx + 3, -28), Vector2(sx + 6, -20)]), [OUTLINE], PackedVector2Array(), PackedColorArray(), OUTLINE)
	# Spikes along bottom
	for i in 5:
		var sx := -30.0 + i * 14.0
		draw_polygon(PackedVector2Array([Vector2(sx, 20), Vector2(sx + 3, 28), Vector2(sx + 6, 20)]), [SPIKE])
	# Wheels — big chunky
	var wheel_positions := [Vector2(-24, -22), Vector2(16, -22), Vector2(-24, 22), Vector2(16, 22)]
	for wp in wheel_positions:
		draw_circle(wp, 8.0, OUTLINE)
		draw_circle(wp, 6.0, RUST)
	# HP bar
	var bar_width := 80.0
	var bar_height := 6.0
	var bar_y := -30.0
	var ratio := hp / max_hp
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, bar_height), Color("#333333"))
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width * ratio, bar_height), Color("#FF2222"))
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, bar_height), OUTLINE, false, 1.5)
	# Draw boss segments following
	_draw_segments()

func _draw_segments() -> void:
	# Draw trailing segments like player compartment chain
	const SEG_COLOR := Color("#3C2415")
	const SEG_OUTLINE := Color("#111111")
	if position_history.size() < FOLLOW_DELAY * SEGMENT_COUNT:
		return
	for i in SEGMENT_COUNT:
		var idx := min(FOLLOW_DELAY * (i + 1), position_history.size() - 1)
		var seg_pos: Vector2 = position_history[idx] - global_position
		# Each segment is smaller than the boss
		var seg_w := 36.0 - i * 4.0
		var seg_h := 24.0 - i * 2.0
		draw_rect(Rect2(seg_pos.x - seg_w * 0.5, seg_pos.y - seg_h * 0.5, seg_w, seg_h), SEG_COLOR)
		draw_rect(Rect2(seg_pos.x - seg_w * 0.5, seg_pos.y - seg_h * 0.5, seg_w, seg_h), SEG_OUTLINE, false, 2.0)
		# Skull on each segment
		draw_circle(seg_pos + Vector2(-seg_w * 0.3, 0), 4.0, Color("#DDDDDD"))
		draw_circle(seg_pos + Vector2(-seg_w * 0.3 - 2, -1), 1.2, Color("#111111"))
		draw_circle(seg_pos + Vector2(-seg_w * 0.3 + 2, -1), 1.2, Color("#111111"))
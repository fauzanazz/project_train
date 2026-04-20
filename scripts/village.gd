extends Node2D
## res://scripts/village.gd
## Village walls, HP, turret management, gate delivery, visual tier upgrades, electric fence, missile battery.

signal village_damaged(amount: float, new_hp: float)
signal village_destroyed

const TIER_HP_BONUS: Array[float] = [1.0, 1.25, 1.75, 2.5, 4.0]
const BASE_HP: float = 500.0
const WALL_SIZE: float = 300.0
const WALL_THICK: float = 18.0
const GATE_WIDTH: float = 60.0

const WALL_COLOR := Color("#8B7355")
const WALL_OUTLINE := Color("#111111")
const HP_BAR_BG := Color("#333333")
const HP_BAR_FG := Color("#22C55E")
const HP_BAR_LOW := Color("#EF4444")
const FENCE_COLOR := Color("#00FFFF")
const FORTIFY_COLOR := Color("#FFD700")

var hp: float = BASE_HP
var max_hp: float = BASE_HP
var base_hp: float = 200.0
var base_max_hp: float = 200.0
var walls_destroyed: bool = false
var tier: int = 0
var turrets: Array = []
var _damage_flash: float = 0.0
var _upgrade_flash: float = 0.0
var _fence_pulse: float = 0.0
var _missile_battery_timer: float = 0.0
const MISSILE_RANGE: float = 500.0
const MISSILE_DAMAGE: float = 120.0
const MISSILE_COOLDOWN: float = 4.0

func _ready() -> void:
	add_to_group("village")
	ResourceManager.village_upgraded.connect(_on_village_upgraded)

func _process(delta: float) -> void:
	_damage_flash = maxf(0.0, _damage_flash - delta * 3.0)
	_upgrade_flash = maxf(0.0, _upgrade_flash - delta * 2.0)
	_fence_pulse += delta
	# Tier 3: Electric fence aura damages nearby enemies
	if tier >= 3:
		_fence_damage_enemies(delta)
	# Tier 4: Missile battery targets elites
	if tier >= 4:
		_missile_battery_timer -= delta
		if _missile_battery_timer <= 0.0:
			_fire_missile_battery()
			_missile_battery_timer = MISSILE_COOLDOWN
	queue_redraw()

func take_damage(amount: float) -> void:
	if walls_destroyed:
		base_hp -= amount
		_damage_flash = 1.0
		village_damaged.emit(amount, base_hp)
		if base_hp <= 0.0:
			base_hp = 0.0
			village_destroyed.emit()
			GameManager._on_village_destroyed()
		return
	hp -= amount
	_damage_flash = 1.0
	village_damaged.emit(amount, hp)
	if hp <= 0.0:
		hp = 0.0
		walls_destroyed = true

func take_damage_from(enemy: Node, amount: float) -> void:
	# Tier 4: basic zombies deal 0 damage to walls
	if tier >= 4 and not enemy.is_in_group("elites") and not enemy.is_in_group("boss"):
		return
	take_damage(amount)

func repair(amount: float) -> void:
	if walls_destroyed:
		base_hp = minf(base_hp + amount, base_max_hp)
		village_damaged.emit(0.0, base_hp)
	else:
		hp = minf(hp + amount, max_hp)
		village_damaged.emit(0.0, hp)

func are_walls_intact() -> bool:
	return not walls_destroyed

func _fence_damage_enemies(delta: float) -> void:
	# Electric fence: damages all enemies within 50px of walls at 15 HP/s
	if not get_tree():
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var half := WALL_SIZE * 0.5
	var fence_range := 50.0
	for e in enemies:
		if not e is Node2D:
			continue
		var dist: float = e.global_position.distance_to(global_position)
		if dist < half + fence_range and dist > half - fence_range:
			if e.has_method("take_damage"):
				e.take_damage(15.0 * delta, "electric")

func _fire_missile_battery() -> void:
	if not get_tree():
		return
	# Find nearest elite enemy in range
	var enemies := get_tree().get_nodes_in_group("enemies")
	var target: Node = null
	var target_dist: float = MISSILE_RANGE * MISSILE_RANGE
	# Prioritize elites and boss
	for e in enemies:
		if not e is Node2D:
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d > target_dist:
			continue
		var is_elite: bool = e.is_in_group("elites") or e.is_in_group("boss")
		if is_elite or target == null:
			if is_elite or (target and not target.is_in_group("elites")):
				target = e
				target_dist = d
	if target:
		_spawn_missile(target)

func _spawn_missile(target: Node) -> void:
	var proj_scene: PackedScene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return
	var dir: Vector2 = global_position.direction_to(target.global_position)
	var proj = proj_scene.instantiate()
	proj.setup(global_position, dir, {
		"damage": MISSILE_DAMAGE,
		"range": MISSILE_RANGE,
		"type": "explosive",
		"piercing": 0,
		"aoe_radius": 80.0,
		"speed": 400.0,
	})
	var world = get_tree().current_scene.get_node_or_null("World") if get_tree() else null
	if world:
		world.add_child(proj)
	elif get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(proj)

func _on_village_upgraded(new_tier: int) -> void:
	tier = new_tier
	max_hp = BASE_HP * TIER_HP_BONUS[minf(new_tier, TIER_HP_BONUS.size() - 1)]
	hp = minf(hp, max_hp)
	_upgrade_flash = 1.0
	if new_tier == 1:
		_spawn_turret("arrow", Vector2(-120, -160))
		_spawn_turret("arrow", Vector2(120, -160))
	elif new_tier == 2:
		_spawn_turret("cannon", Vector2(0, -165))
	elif new_tier == 3:
		# Electric fence upgrade — visual only, damage handled in _process
		pass
	elif new_tier == 4:
		# Fortress walls + missile battery
		_missile_battery_timer = MISSILE_COOLDOWN
	queue_redraw()

func _spawn_turret(turret_type_str: String, pos: Vector2) -> void:
	var turret_scene: PackedScene = load("res://scenes/village_turret.tscn")
	if not turret_scene:
		return
	var turret = turret_scene.instantiate()
	if turret_type_str == "cannon":
		turret.turret_type = 1  # CANNON
	else:
		turret.turret_type = 0  # ARROW
	turret.global_position = global_position + pos
	add_child(turret)
	turrets.append(turret)

func get_gate_position() -> Vector2:
	return global_position + Vector2(0, WALL_SIZE * 0.5)

func _draw() -> void:
	var half := WALL_SIZE * 0.5
	var t := WALL_THICK
	var wall_color := WALL_COLOR
	if walls_destroyed:
		wall_color = Color(WALL_COLOR.r, WALL_COLOR.g, WALL_COLOR.b, 0.3)
	if _damage_flash > 0.0:
		wall_color = WALL_COLOR.lerp(Color("#FF4444"), _damage_flash * 0.5)
	# Tier 4: fortress glow
	if tier >= 4:
		wall_color = wall_color.lerp(FORTIFY_COLOR, 0.3)
	# North wall
	_draw_wall_segment(Vector2(-half, -half), Vector2(WALL_SIZE, t), wall_color)
	# South wall — with gate gap
	var gate_half := GATE_WIDTH * 0.5
	_draw_wall_segment(Vector2(-half, half - t), Vector2(half - gate_half, t), wall_color)
	_draw_wall_segment(Vector2(gate_half, half - t), Vector2(half - gate_half, t), wall_color)
	# West wall
	_draw_wall_segment(Vector2(-half, -half + t), Vector2(t, WALL_SIZE - t), wall_color)
	# East wall
	_draw_wall_segment(Vector2(half - t, -half + t), Vector2(t, WALL_SIZE - t), wall_color)
	# Gate marker
	draw_rect(Rect2(-gate_half, half - t, GATE_WIDTH, t), Color("#5C4A2A"))
	# Tier 3: Electric fence aura
	if tier >= 3:
		_draw_electric_fence(half, t)
	# Tier 4: Missile battery visual
	if tier >= 4:
		_draw_missile_battery()
	# Upgrade flash overlay
	if _upgrade_flash > 0.0:
		var flash_color := Color(1.0, 1.0, 1.0, _upgrade_flash * 0.6)
		draw_rect(Rect2(-half, -half, WALL_SIZE, WALL_SIZE), flash_color)
	# HP bar
	var bar_width := 200.0
	var bar_height := 14.0
	var bar_x := -bar_width * 0.5
	var bar_y := -half - 30.0
	var display_hp := base_hp if walls_destroyed else hp
	var display_max := base_max_hp if walls_destroyed else max_hp
	var hp_ratio := display_hp / display_max if display_max > 0 else 0.0
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), HP_BAR_BG)
	var fill_color := HP_BAR_FG if hp_ratio > 0.3 else HP_BAR_LOW
	draw_rect(Rect2(bar_x, bar_y, bar_width * hp_ratio, bar_height), fill_color)
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), WALL_OUTLINE, false, 1.5)
	_draw_stone_detail(half, t, wall_color)
	# Turret dots
	for turret in turrets:
		if is_instance_valid(turret):
			var rel_pos = turret.global_position - global_position
			draw_circle(rel_pos, 5.0, Color("#AAAAAA"))

func _draw_wall_segment(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos, size), color)
	draw_rect(Rect2(pos, size), WALL_OUTLINE, false, 3.0)

func _draw_electric_fence(half: float, _t: float) -> void:
	# Cyan pulse ring around walls
	var pulse := 0.5 + 0.5 * sin(_fence_pulse * 4.0)
	var alpha := 0.3 + 0.4 * pulse
	var ring_r := half + 50.0
	# Draw fence ring along wall perimeter
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 48, Color(FENCE_COLOR.r, FENCE_COLOR.g, FENCE_COLOR.b, alpha), 3.0)
	# Sparks
	for i in 12:
		var angle := i * TAU / 12.0 + _fence_pulse * 2.0
		var spark_pos := Vector2(cos(angle), sin(angle)) * ring_r
		draw_circle(spark_pos, 3.0 * pulse, Color(FENCE_COLOR.r, FENCE_COLOR.g, FENCE_COLOR.b, alpha * 0.8))

func _draw_missile_battery() -> void:
	# Small turret icon on top-center of north wall
	var pos := Vector2(0, -150 - 18)
	draw_rect(Rect2(pos.x - 8, pos.y - 5, 16, 10), Color("#888888"))
	draw_rect(Rect2(pos.x - 8, pos.y - 5, 16, 10), WALL_OUTLINE, false, 1.5)
	draw_line(pos, Vector2(pos.x, pos.y - 14), Color("#666666"), 4.0)
	draw_circle(Vector2(pos.x, pos.y - 16), 4.0, Color("#FF4444"))

func _draw_stone_detail(half: float, t: float, wall_color: Color) -> void:
	if walls_destroyed:
		return
	var stone_color := Color(wall_color.r * 0.8, wall_color.g * 0.8, wall_color.b * 0.8)
	var block_size := 16.0
	var nx := -half + 8.0
	while nx < half - 8.0:
		draw_rect(Rect2(nx, -half + 2, block_size - 2, t - 4), stone_color)
		nx += block_size + 2
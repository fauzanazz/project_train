extends Node2D
## res://scripts/village.gd
## Village walls, HP, turret management, gate delivery, and visual tier upgrades.

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

var hp: float = BASE_HP
var max_hp: float = BASE_HP
var tier: int = 0
var turrets: Array = []
var _damage_flash: float = 0.0

func _ready() -> void:
	add_to_group("village")
	ResourceManager.village_upgraded.connect(_on_village_upgraded)

func _process(delta: float) -> void:
	_damage_flash = max(0.0, _damage_flash - delta * 3.0)
	queue_redraw()

func take_damage(amount: float) -> void:
	hp -= amount
	_damage_flash = 1.0
	village_damaged.emit(amount, hp)
	if hp <= 0.0:
		hp = 0.0
		village_destroyed.emit()
		GameManager._on_village_destroyed()

func repair(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	village_damaged.emit(0.0, hp)

func _on_village_upgraded(new_tier: int) -> void:
	tier = new_tier
	max_hp = BASE_HP * TIER_HP_BONUS[min(new_tier, TIER_HP_BONUS.size() - 1)]
	hp = min(hp, max_hp)
	if new_tier == 1:
		_spawn_turret("arrow", Vector2(-120, -160))
		_spawn_turret("arrow", Vector2(120, -160))
	elif new_tier == 2:
		_spawn_turret("cannon", Vector2(0, -165))
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
	if _damage_flash > 0.0:
		wall_color = WALL_COLOR.lerp(Color("#FF4444"), _damage_flash * 0.5)
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
	# HP bar
	var bar_width := 200.0
	var bar_height := 14.0
	var bar_x := -bar_width * 0.5
	var bar_y := -half - 30.0
	var hp_ratio := hp / max_hp if max_hp > 0 else 0.0
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

func _draw_stone_detail(half: float, t: float, wall_color: Color) -> void:
	var stone_color := Color(wall_color.r * 0.8, wall_color.g * 0.8, wall_color.b * 0.8)
	var block_size := 16.0
	var nx := -half + 8.0
	while nx < half - 8.0:
		draw_rect(Rect2(nx, -half + 2, block_size - 2, t - 4), stone_color)
		nx += block_size + 2
extends Node2D
## res://scripts/village.gd
## Village walls, HP, turret management, and visual tier upgrades.

signal village_damaged(amount: float, new_hp: float)
signal village_destroyed

const TIER_HP_BONUS: Array[float] = [1.0, 1.25, 1.75, 2.5, 4.0]
const BASE_HP: float = 500.0
const WALL_SIZE: float = 300.0
const WALL_THICK: float = 18.0
const GATE_WIDTH: float = 60.0

# Draw constants
const WALL_COLOR := Color("#8B7355")
const WALL_OUTLINE := Color("#111111")
const HP_BAR_BG := Color("#333333")
const HP_BAR_FG := Color("#22C55E")
const HP_BAR_LOW := Color("#EF4444")

var hp: float = BASE_HP
var max_hp: float = BASE_HP
var tier: int = 0
var turrets: Array = []

func _ready() -> void:
	add_to_group("village")
	ResourceManager.village_upgraded.connect(_on_village_upgraded)

func _process(_delta: float) -> void:
	queue_redraw()

func take_damage(amount: float) -> void:
	hp -= amount
	village_damaged.emit(amount, hp)
	if hp <= 0.0:
		village_destroyed.emit()

func repair(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	village_damaged.emit(0.0, hp)

func _on_village_upgraded(new_tier: int) -> void:
	tier = new_tier
	max_hp = BASE_HP * TIER_HP_BONUS[new_tier]
	hp = min(hp, max_hp)
	queue_redraw()

func _draw() -> void:
	var half := WALL_SIZE * 0.5
	var t := WALL_THICK

	# North wall — full width
	_draw_wall_segment(Vector2(-half, -half), Vector2(WALL_SIZE, t))
	# South wall — with gate gap at center
	var gate_half := GATE_WIDTH * 0.5
	_draw_wall_segment(Vector2(-half, half - t), Vector2(half - gate_half, t))
	_draw_wall_segment(Vector2(gate_half, half - t), Vector2(half - gate_half, t))
	# West wall
	_draw_wall_segment(Vector2(-half, -half + t), Vector2(t, WALL_SIZE - t))
	# East wall
	_draw_wall_segment(Vector2(half - t, -half + t), Vector2(t, WALL_SIZE - t))

	# Gate marker (open area, slightly different color)
	var gate_color := Color("#5C4A2A")
	draw_rect(Rect2(-gate_half, half - t, GATE_WIDTH, t), gate_color)

	# HP bar above the village
	var bar_width := 200.0
	var bar_height := 14.0
	var bar_x := -bar_width * 0.5
	var bar_y := -half - 30.0
	var hp_ratio := hp / max_hp
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), HP_BAR_BG)
	var fill_color := HP_BAR_FG if hp_ratio > 0.3 else HP_BAR_LOW
	draw_rect(Rect2(bar_x, bar_y, bar_width * hp_ratio, bar_height), fill_color)
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), WALL_OUTLINE, false, 1.5)

	# Stone texture hint — small darker squares on walls
	_draw_stone_detail(half, t)

func _draw_wall_segment(pos: Vector2, size: Vector2) -> void:
	draw_rect(Rect2(pos, size), WALL_COLOR)
	draw_rect(Rect2(pos, size), WALL_OUTLINE, false, 3.0)

func _draw_stone_detail(half: float, t: float) -> void:
	var stone_color := Color(WALL_COLOR.r * 0.8, WALL_COLOR.g * 0.8, WALL_COLOR.b * 0.8)
	var block_size := 16.0
	# Draw a few stone block lines on north wall
	var nx := -half + 8.0
	while nx < half - 8.0:
		draw_rect(Rect2(nx, -half + 2, block_size - 2, t - 4), stone_color)
		nx += block_size + 2

extends Node2D
## res://scripts/village_turret.gd
## Auto-aiming turret on village wall. Fires at nearest enemy in range.

enum TurretType { ARROW, CANNON }

@export var turret_type: TurretType = TurretType.ARROW
@export var range_px: float = 200.0
@export var fire_rate: float = 1.5
@export var damage: float = 10.0

var _cooldown: float = 0.0
var _muzzle_flash_time: float = 0.0

const ARROW_RANGE: float = 200.0
const ARROW_FIRE_RATE: float = 1.5
const ARROW_DAMAGE: float = 10.0
const CANNON_RANGE: float = 300.0
const CANNON_FIRE_RATE: float = 3.0
const CANNON_DAMAGE: float = 40.0

func _ready() -> void:
	add_to_group("turrets")
	match turret_type:
		TurretType.ARROW:
			range_px = ARROW_RANGE
			fire_rate = ARROW_FIRE_RATE
			damage = ARROW_DAMAGE
		TurretType.CANNON:
			range_px = CANNON_RANGE
			fire_rate = CANNON_FIRE_RATE
			damage = CANNON_DAMAGE

func _process(delta: float) -> void:
	_cooldown -= delta
	if _muzzle_flash_time > 0.0:
		_muzzle_flash_time -= delta
	_find_and_fire()
	queue_redraw()

func _find_and_fire() -> void:
	if _cooldown > 0.0:
		return
	var enemies = get_tree().get_nodes_in_group("enemies") if get_tree() else []
	var nearest: Node2D = null
	var nearest_dist: float = range_px * range_px
	for e in enemies:
		if not e is Node2D:
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest:
		_fire_at(nearest)
		_cooldown = fire_rate

func _fire_at(target: Node2D) -> void:
	_muzzle_flash_time = 0.1
	var dir := global_position.direction_to(target.global_position)
	if turret_type == TurretType.CANNON:
		_spawn_projectile(global_position, dir, {
			"damage": damage, "range": range_px, "type": "explosive",
			"piercing": 0, "aoe_radius": 60.0, "speed": 350.0
		})
	else:
		_spawn_projectile(global_position, dir, {
			"damage": damage, "range": range_px, "type": "kinetic",
			"piercing": 0, "aoe_radius": 0.0, "speed": 500.0
		})

func _spawn_projectile(origin: Vector2, dir: Vector2, data: Dictionary) -> void:
	var proj_scene: PackedScene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return
	var proj = proj_scene.instantiate()
	proj.setup(origin, dir, data)
	# Add to scene tree — find the world node
	var world = get_tree().get_first_node_in_group("projectiles_parent") if get_tree() else null
	if world:
		world.add_child(proj)
		return
	# Fallback: add to current scene
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(proj)

func _draw() -> void:
	if turret_type == TurretType.ARROW:
		_draw_arrow_turret()
	else:
		_draw_cannon_turret()

func _draw_arrow_turret() -> void:
	# Small arrow icon on wall — gray base, arrow pointing outward
	draw_rect(Rect2(-8, -4, 16, 8), Color("#888888"))
	draw_rect(Rect2(-8, -4, 16, 8), Color("#111111"), false, 1.5)
	# Arrow barrel
	draw_line(Vector2(0, 0), Vector2(0, -10), Color("#AAAAAA"), 2.0)
	# Muzzle flash
	if _muzzle_flash_time > 0.0:
		draw_circle(Vector2(0, -12), 4.0, Color("#FFFF44"))

func _draw_cannon_turret() -> void:
	# Larger cannon icon on wall — dark gray, thick barrel
	draw_rect(Rect2(-10, -5, 20, 10), Color("#666666"))
	draw_rect(Rect2(-10, -5, 20, 10), Color("#111111"), false, 2.0)
	# Cannon barrel
	draw_line(Vector2(0, 0), Vector2(0, -14), Color("#444444"), 4.0)
	# Muzzle flash
	if _muzzle_flash_time > 0.0:
		draw_circle(Vector2(0, -16), 6.0, Color("#FF8800"))
		draw_circle(Vector2(0, -16), 3.0, Color("#FFDD44"))
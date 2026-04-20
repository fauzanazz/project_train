extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_railgun.gd
## Rail Cannon — kinetic, instant raycast that pierces all enemies in line. Bright white line flash.

const BASE_DAMAGE: float = 80.0
const BASE_FIRE_RATE: float = 3.5
const BASE_RANGE: float = 600.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var phase_round: bool = false
var overcharge: bool = false
var _cooldown: float = 0.0
var _flash_timer: float = 0.0
var _flash_end: Vector2 = Vector2.ZERO

func _init() -> void:
	id = "railgun_mk1"
	display_name = "Rail Cannon"
	tier = ModifierTier.ADVANCED
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Sabot Core", "Magnetic Accelerator", "Phase Round", "Overcharge"])
	upgrade_descs = PackedStringArray(["Damage +30", "Cooldown 3.5s → 2.5s", "Full pierce damage", "2s charge = 3x damage"])

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0

func tick(dt: float) -> void:
	_flash_timer = maxf(0.0, _flash_timer - dt)
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	var target = _find_target(range_px)
	if not target:
		return
	_fire_at(target)
	_cooldown = fire_rate

func _fire_at(target: Node) -> void:
	if not _compartment or not target is Node2D:
		return
	var start_pos: Vector2 = _compartment.global_position
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	var end_pos: Vector2 = start_pos + dir * range_px
	var effective_damage: float = damage
	if overcharge:
		effective_damage *= 3.0
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment.get_tree() else []
	var hit_count: int = 0
	for e in enemies:
		if not e is Node2D:
			continue
		var to_enemy: Vector2 = e.global_position - start_pos
		var projection: float = to_enemy.dot(dir)
		if projection < 0 or projection > range_px:
			continue
		var closest_point: Vector2 = start_pos + dir * projection
		var dist_to_line: float = e.global_position.distance_to(closest_point)
		var hit_dmg: float = effective_damage
		if not phase_round and hit_count > 0:
			hit_dmg *= 0.8
		if dist_to_line < 20.0 and e.has_method("take_damage"):
			e.take_damage(hit_dmg, "kinetic")
			hit_count += 1
	_flash_timer = 0.15
	_flash_end = end_pos
	_spawn_rail_effect(start_pos, end_pos)

func _spawn_rail_effect(start: Vector2, end: Vector2) -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	var effect = Node2D.new()
	effect.set_script(_create_rail_flash_script(start, end))
	effect.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(effect)
	ScreenShake.shake(0.1, 5.0)

func _create_rail_flash_script(start: Vector2, end: Vector2) -> Script:
	var start_str := "Vector2(%f, %f)" % [start.x, start.y]
	var end_str := "Vector2(%f, %f)" % [end.x, end.y]
	var src = "
extends Node2D
var _time := 0.15
var _start := %s
var _end := %s
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var alpha := maxf(0, _time / 0.15)
	draw_line(_start, _end, Color(1, 1, 1, alpha), 4.0)
	draw_line(_start, _end, Color(0.7, 0.85, 1.0, alpha * 0.6), 8.0)
	draw_circle(_start, 6.0 * alpha, Color(1, 1, 1, alpha))
	draw_circle(_end, 4.0 * alpha, Color(0.7, 0.85, 1.0, alpha))
" % [start_str, end_str]
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage = BASE_DAMAGE
	fire_rate = BASE_FIRE_RATE
	phase_round = false
	overcharge = false
	if new_level >= 2:
		damage += 30.0
	if new_level >= 3:
		fire_rate = 2.5
	if new_level >= 4:
		phase_round = true
	if new_level >= 5:
		overcharge = true

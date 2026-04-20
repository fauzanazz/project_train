extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_tesla.gd
## Tesla Coil — electric, chains to nearby enemies within range. Lightning arc visual.

const BASE_DAMAGE: float = 30.0
const BASE_FIRE_RATE: float = 1.2
const BASE_RANGE: float = 280.0
const CHAIN_RANGE: float = 150.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var chain_count: int = 3
var ground_arc: bool = false
var storm_core: bool = false
var _cooldown: float = 0.0
var _arc_points: Array = []
var _arc_display_time: float = 0.3

func _init() -> void:
	id = "tesla_mk1"
	display_name = "Tesla Coil"
	tier = ModifierTier.ADVANCED
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Extended Coil", "Surge Capacitor", "Ground Arc", "Storm Core"])
	upgrade_descs = PackedStringArray(["Chains to 5 enemies", "Damage +40%", "Electric ground patch", "Unlimited chain range"])

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0

func tick(dt: float) -> void:
	for arc in _arc_points:
		arc["timer"] -= dt
	_arc_points = _arc_points.filter(func(a): return a["timer"] > 0.0)
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	var target = _find_target(range_px)
	if not target:
		return
	_chain_lightning(target)
	_cooldown = fire_rate

func _chain_lightning(first_target: Node) -> void:
	var origin: Vector2 = _compartment.global_position if _compartment else Vector2.ZERO
	var hit: Array = [first_target]
	if first_target.has_method("take_damage"):
		first_target.take_damage(damage, "electric")
	_add_arc(origin, first_target.global_position if first_target is Node2D else origin)
	var source: Node2D = first_target as Node2D
	for _i in chain_count - 1:
		var next = _find_chain_target(source, hit)
		if not next:
			break
		if next.has_method("take_damage"):
			next.take_damage(damage * 0.7, "electric")
		_add_arc(source.global_position, next.global_position)
		hit.append(next)
		source = next

func _add_arc(from: Vector2, to: Vector2) -> void:
	_arc_points.append({"from": from, "to": to, "timer": _arc_display_time})
	_spawn_lightning_effect(from, to)

func _spawn_lightning_effect(from: Vector2, to: Vector2) -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	var effect = Node2D.new()
	var points := _generate_lightning_points(from, to)
	effect.set_script(_create_lightning_script(points))
	effect.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(effect)

func _generate_lightning_points(from: Vector2, to: Vector2) -> Array:
	var points: Array = [from]
	var dir := (to - from)
	var segments := 6
	for i in range(1, segments):
		var t: float = float(i) / segments
		var point := from + dir * t
		var perp := Vector2(-dir.y, dir.x).normalized()
		point += perp * randf_range(-12.0, 12.0)
		points.append(point)
	points.append(to)
	return points

func _create_lightning_script(points: Array) -> Script:
	var pts_str := "var _points := ["
	for i in points.size():
		if i > 0:
			pts_str += ", "
		pts_str += "Vector2(%f, %f)" % [points[i].x, points[i].y]
	pts_str += "]"
	var src = "
extends Node2D
%s
var _time := 0.3
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var alpha := maxf(0, _time / 0.3)
	var arr := PackedVector2Array()
	for p in _points:
		arr.append(p)
	if arr.size() >= 2:
		draw_polyline(arr, Color(0.0, 0.8, 1.0, alpha), 3.0)
		draw_polyline(arr, Color(0.7, 0.95, 1.0, alpha * 0.6), 1.5)
		draw_circle(arr[0], 4.0, Color(0.7, 0.95, 1.0, alpha))
		draw_circle(arr[arr.size()-1], 4.0, Color(0.7, 0.95, 1.0, alpha))
" % pts_str
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _find_chain_target(source: Node2D, exclude: Array) -> Node:
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment.get_tree() else []
	var nearest: Node = null
	var effective_range: float = CHAIN_RANGE if not storm_core else 9999.0
	var nearest_dist: float = effective_range * effective_range
	for e in enemies:
		if e in exclude or not e is Node2D:
			continue
		var d: float = source.global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage = BASE_DAMAGE
	fire_rate = BASE_FIRE_RATE
	chain_count = 3
	ground_arc = false
	storm_core = false
	if new_level >= 2:
		chain_count = 5
	if new_level >= 3:
		damage = BASE_DAMAGE * 1.4
	if new_level >= 4:
		ground_arc = true
	if new_level >= 5:
		storm_core = true

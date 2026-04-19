extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_devastator.gd
## Devastator — full-screen explosive AoE, camera shake, screen flash.

const BASE_DAMAGE: float = 200.0
const BASE_FIRE_RATE: float = 6.0
const AOE_RADIUS: float = 800.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var _cooldown: float = 0.0

func _init() -> void:
	id = "devastator"
	display_name = "Devastator"
	tier = ModifierTier.ELITE
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Reinforced Chamber", "Quick Load", "Heavy Payload", "Total Annihilation"])
	upgrade_descs = PackedStringArray(["+50 damage", "Cooldown -0.5s", "+50 damage, -0.5s", "+50 damage, -0.5s"])

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0

func tick(dt: float) -> void:
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment and _compartment.get_tree() else []
	if enemies.is_empty():
		return
	var origin: Vector2 = _compartment.global_position if _compartment else Vector2.ZERO
	for e in enemies:
		if not e is Node2D:
			continue
		var dist: float = e.global_position.distance_to(origin)
		if dist <= AOE_RADIUS:
			if e.has_method("take_damage"):
				var falloff: float = 1.0 - (dist / AOE_RADIUS) * 0.5
				e.take_damage(damage * falloff, "explosive")
	_spawn_devastator_effect(origin)
	ScreenShake.shake(0.4, 15.0)
	_cooldown = fire_rate

func _spawn_devastator_effect(pos: Vector2) -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	var flash = Node2D.new()
	flash.set_script(_create_flash_script())
	flash.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(flash)
	var ring = Node2D.new()
	ring.set_script(_create_ring_script(pos))
	ring.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(ring)

func _create_flash_script() -> Script:
	var src = "
extends Node2D
var _time := 0.06
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var alpha := max(0, _time / 0.06)
	draw_rect(Rect2(-2000, -2000, 4000, 4000), Color(1, 1, 1, alpha))"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _create_ring_script(pos: Vector2) -> Script:
	var p_str := "Vector2(%f, %f)" % [pos.x, pos.y]
	var src = "
extends Node2D
var _time := 0.6
var _center := %s
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var ratio := 1.0 - max(0, _time / 0.6)
	var r := 800.0 * ratio
	var alpha := max(0, _time / 0.6)
	draw_arc(_center, r, 0.0, TAU, 64, Color(1, 0.5, 0.1, alpha), 8.0)
	draw_arc(_center, r * 0.7, 0.0, TAU, 48, Color(1, 1.0, 0.3, alpha * 0.5), 4.0)
	draw_circle(_center, r * 0.3, Color(1, 0.8, 0.2, alpha * 0.3))
" % p_str
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage = BASE_DAMAGE + (new_level - 1) * 50.0
	fire_rate = maxf(2.0, BASE_FIRE_RATE - (new_level - 1) * 0.5)

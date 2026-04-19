extends Area2D
## res://scripts/projectile.gd
## Moves in a direction at speed, deals damage on body_entered.
## Supports arc trajectory (mortar), instant raycast (railgun), taser slow.

const LIFETIME: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 8.0
var damage_type: String = "kinetic"
var max_range: float = 300.0
var piercing: int = 0
var aoe_radius: float = 0.0
var slow_factor: float = 0.0
var slow_duration: float = 0.0
var is_arc: bool = false
var arc_height: float = 0.0

var _distance_traveled: float = 0.0
var _lifetime: float = 0.0
var _hit_count: int = 0
var _arc_time: float = 0.0
var _arc_duration: float = 0.0

# Visual colors per type
const TYPE_COLORS := {
	"kinetic": Color("#FFDD44"),
	"fire": Color("#FF4500"),
	"explosive": Color("#FF8800"),
	"electric": Color("#00CCFF"),
}

func setup(origin: Vector2, dir: Vector2, data: Dictionary) -> void:
	global_position = origin
	direction = dir.normalized()
	damage = data.get("damage", 8.0)
	damage_type = data.get("type", "kinetic")
	speed = data.get("speed", 600.0)
	max_range = data.get("range", 300.0)
	piercing = data.get("piercing", 0)
	aoe_radius = data.get("aoe_radius", 0.0)
	slow_factor = data.get("slow_factor", 0.0)
	slow_duration = data.get("slow_duration", 0.0)
	is_arc = data.get("arc", false)
	if is_arc:
		_arc_duration = max_range / speed
		_arc_time = 0.0
	rotation = direction.angle()

func _ready() -> void:
	collision_layer = 4  # projectiles
	collision_mask = 2    # enemies
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if is_arc:
		_arc_time += delta
		var horizontal_step: Vector2 = direction * speed * delta
		global_position += horizontal_step
		_distance_traveled += horizontal_step.length()
		# Parabolic arc height
		var progress: float = _arc_time / _arc_duration if _arc_duration > 0 else 1.0
		arc_height = -200.0 * 4.0 * progress * (1.0 - progress)  # negative = up
		_lifetime += delta
		if _distance_traveled >= max_range or _lifetime >= LIFETIME:
			if aoe_radius > 0.0:
				_aoe_explode()
			queue_free()
	else:
		var step: Vector2 = direction * speed * delta
		global_position += step
		_distance_traveled += step.length()
		_lifetime += delta
		if _distance_traveled >= max_range or _lifetime >= LIFETIME:
			if aoe_radius > 0.0:
				_aoe_explode()
			queue_free()

func _on_body_entered(body: Node) -> void:
	_try_damage(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var parent = area.get_parent()
		if parent and parent.has_method("take_damage"):
			_try_damage(parent)

func _try_damage(target: Node) -> void:
	if not target.has_method("take_damage"):
		return
	target.take_damage(damage, damage_type)
	if slow_factor > 0.0 and target.has_method("apply_slow"):
		target.apply_slow(slow_factor, slow_duration)
	_hit_count += 1
	_spawn_impact_particles()
	if aoe_radius > 0.0 and damage_type == "explosive":
		_aoe_explode()
	if _hit_count > piercing:
		queue_free()

func _aoe_explode() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies") if get_tree() else []
	for e in enemies:
		if not e is Node2D:
			continue
		if e.global_position.distance_to(global_position) <= aoe_radius:
			e.take_damage(damage * 0.6, damage_type)
	# Spawn explosion visual
	_spawn_explosion_visual()

func _spawn_explosion_visual() -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	var effect = Node2D.new()
	effect.set_script(_create_explosion_script())
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)

func _create_explosion_script() -> Script:
	var r := aoe_radius if aoe_radius > 0 else 40.0
	var src = "
extends Node2D
var _time := 0.4
var _radius := %f
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var ratio := max(0, _time / 0.4)
	var r := _radius * (1.0 - ratio * 0.5)
	draw_circle(Vector2.ZERO, r, Color(1, 0.5, 0.1, ratio * 0.5))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1, 1.0, 0.3, ratio * 0.7))
	draw_circle(Vector2.ZERO, r * 0.2, Color(1, 1.0, 0.8, ratio))"
	% r
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _spawn_impact_particles() -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	var spark = Node2D.new()
	spark.set_script(_create_spark_script())
	spark.global_position = global_position
	get_tree().current_scene.add_child(spark)

func _create_spark_script() -> Script:
	var src = "
extends Node2D
var _time := 0.15
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var alpha := max(0, _time / 0.15)
	for i in 3:
		var angle := i * TAU / 3.0 + randf() * 0.5
		var len := 4.0 + randf() * 4.0
		draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * len, Color(1.0, 0.8, 0.2, alpha), 2.0)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.5, alpha))"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var color: Color = TYPE_COLORS.get(damage_type, Color("#FFFFFF"))
	if is_arc:
		# Mortar projectile — draw arc circle that rises/falls with arc_height
		draw_circle(Vector2.ZERO, 8.0, color)
		draw_circle(Vector2.ZERO, 5.0, Color("#FFDD00"))
		# Shadow on ground
		draw_circle(Vector2(0, -arc_height * 0.5), 4.0, Color(0, 0, 0, 0.3))
	elif damage_type == "kinetic":
		# Small bright line/bullet streak
		draw_line(Vector2(-8, 0), Vector2(4, 0), color, 2.0)
		draw_circle(Vector2(4, 0), 2.0, Color.WHITE)
	elif damage_type == "fire":
		draw_circle(Vector2.ZERO, 4.0, color)
		draw_circle(Vector2.ZERO, 2.0, Color("#FFAA00"))
	elif damage_type == "explosive":
		draw_circle(Vector2.ZERO, 5.0, color)
		draw_circle(Vector2.ZERO, 3.0, Color("#DDDD00"))
	elif damage_type == "electric":
		draw_circle(Vector2.ZERO, 3.0, color)
		draw_line(Vector2(-6, 0), Vector2(0, -3), color, 1.5)
		draw_line(Vector2(0, -3), Vector2(6, 0), color, 1.5)
extends Area2D
## res://scripts/projectile.gd
## Moves in a direction at speed, deals damage on body_entered, destroys after max_range or timeout.

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

var _distance_traveled: float = 0.0
var _lifetime: float = 0.0
var _hit_count: int = 0

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
	rotation = direction.angle()

func _ready() -> void:
	collision_layer = 4  # projectiles (layer 3 = bit 3 = value 4)
	collision_mask = 2    # enemies
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
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

func _spawn_impact_particles() -> void:
	# Small impact flash — just a brief visual marker at impact point
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
	var alpha := _time / 0.15
	draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 0.5, alpha))
"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var color: Color = TYPE_COLORS.get(damage_type, Color("#FFFFFF"))
	if damage_type == "kinetic":
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
		# Electric arc flicker
		draw_line(Vector2(-6, 0), Vector2(0, -3), color, 1.5)
		draw_line(Vector2(0, -3), Vector2(6, 0), color, 1.5)
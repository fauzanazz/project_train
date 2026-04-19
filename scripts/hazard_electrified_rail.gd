extends Area2D
## res://scripts/hazard_electrified_rail.gd
## Electrified Rail — deals 30 damage to first compartment crossing.

const RAIL_DAMAGE: float = 30.0

var _triggered: bool = false
var _respawn_timer: float = 30.0
var _flash_time: float = 0.0

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 32  # hazards
	collision_mask = 1    # player
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	# Find train and damage the first compartment or locomotive
	var train = _find_train_from(body)
	if not train:
		return
	_triggered = true
	# Damage first compartment or locomotive
	if train.compartments.size() > 0 and is_instance_valid(train.compartments[0]):
		train.compartments[0].take_damage(RAIL_DAMAGE)
	elif train.locomotive:
		train.take_damage(RAIL_DAMAGE)
	ScreenShake.shake(0.15, 5.0)
	_flash_time = 0.5

func _find_train_from(body: Node) -> Node:
	if body.has_method("try_collect_resource"):
		return body
	var parent = body.get_parent()
	while parent:
		if parent.has_method("try_collect_resource"):
			return parent
		parent = parent.get_parent()
	return null

func _process(delta: float) -> void:
	_flash_time = max(0.0, _flash_time - delta)
	if _triggered:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_triggered = false
			_respawn_timer = 30.0
	queue_redraw()

func _draw() -> void:
	# Bright yellow (#FFD700) sparking line
	const RAIL_COLOR := Color("#FFD700")
	const SPARK_COLOR := Color("#FFFFFF")
	const DARK_RAIL := Color("#AA8800")
	# Rail line
	draw_line(Vector2(-40, 0), Vector2(40, 0), RAIL_COLOR if not _triggered else DARK_RAIL, 6.0)
	draw_line(Vector2(-40, 0), Vector2(40, 0), Color("#111111"), 1.5)
	# Rail ties
	for i in 5:
		var tx := -32.0 + i * 16.0
		draw_line(Vector2(tx, -6), Vector2(tx, 6), Color("#555555"), 2.0)
	# Sparks when active
	if not _triggered:
		var time := Time.get_ticks_msec() / 1000.0
		for i in 3:
			var sx := randf_range(-30.0, 30.0)
			var sy := randf_range(-4.0, 4.0)
			draw_circle(Vector2(sx, sy), 2.0, Color(SPARK_COLOR.r, SPARK_COLOR.g, SPARK_COLOR.b, 0.5 + 0.5 * sin(time * 10.0 + i)))
	# Flash on trigger
	if _flash_time > 0.0:
		var alpha := _flash_time / 0.5
		draw_rect(Rect2(-50, -20, 100, 40), Color(1.0, 1.0, 0.8, alpha * 0.6))
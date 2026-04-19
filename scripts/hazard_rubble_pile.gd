extends StaticBody2D
## res://scripts/hazard_rubble_pile.gd
## Rubble Pile — blocks path, ramming clears it (costs 10 HP to train).

const RAM_COST: float = 10.0

var _cleared: bool = false

func _ready() -> void:
	add_to_group("hazards")

func _physics_process(_delta: float) -> void:
	if _cleared:
		return
	# Check if locomotive is ramming
	var loco = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	if loco:
		var dist: float = global_position.distance_to(loco.global_position)
		if dist < 35.0:
			_clear_rubble(loco)

func _clear_rubble(loco: Node) -> void:
	_cleared = true
	# Damage train
	var train = loco.get_parent() if loco else null
	if train and train.has_method("take_damage"):
		train.take_damage(RAM_COST)
	# Remove collision and visual
	if has_node("CollisionShape2D"):
		var col = get_node("CollisionShape2D")
		col.set_deferred("disabled", true)
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if _cleared:
		return
	# Stone gray (#8B8B8B) irregular pile
	const STONE := Color("#8B8B8B")
	const DARK_STONE := Color("#6B6B6B")
	const OUTLINE := Color("#444444")
	# Irregular pile shape
	var points := PackedVector2Array([
		Vector2(-20, 8), Vector2(-24, 0), Vector2(-18, -10),
		Vector2(-8, -14), Vector2(5, -12), Vector2(15, -8),
		Vector2(22, 0), Vector2(18, 10), Vector2(8, 14),
		Vector2(-5, 12), Vector2(-15, 10)
	])
	draw_polygon(points, [STONE])
	draw_polyline(PackedVector2Array(Array(points) + [points[0]]), OUTLINE, 2.5)
	# Stone detail
	draw_circle(Vector2(-8, -4), 6.0, DARK_STONE)
	draw_circle(Vector2(8, 2), 5.0, DARK_STONE)
	draw_circle(Vector2(-2, 6), 4.0, DARK_STONE)
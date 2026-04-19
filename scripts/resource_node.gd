extends Area2D
## res://scripts/resource_node.gd
## Resource pickup node — drive over to collect into cargo bay.

signal resource_collected(type: String, amount: int, node: Node)

@export var resource_type: String = "lumber"  # "lumber" | "metal" | "medicine"
@export var yield_amount: int = 10
@export var respawn_time: float = 60.0

var depleted: bool = false
var _respawn_timer: Timer

func _ready() -> void:
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_on_respawn)
	add_child(_respawn_timer)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if depleted:
		return
	if not body.is_in_group("train_body"):
		return
	# Try to load into nearest empty cargo compartment
	var train = _find_train(body)
	if train and train.has_method("try_collect_resource"):
		if train.try_collect_resource(resource_type, yield_amount):
			_deplete()

func _find_train(body: Node) -> Node:
	var parent = body.get_parent()
	while parent:
		if parent.has_method("try_collect_resource"):
			return parent
		parent = parent.get_parent()
	return null

func _deplete() -> void:
	depleted = true
	resource_collected.emit(resource_type, yield_amount, self)
	queue_redraw()
	_respawn_timer.start(respawn_time)

func _on_respawn() -> void:
	depleted = false
	queue_redraw()

func _draw() -> void:
	pass  # Visual drawing implemented in Task 1

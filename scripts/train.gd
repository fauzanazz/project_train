extends Node2D
## res://scripts/train.gd
## Manages the compartment chain. Owns compartment list, cargo, and body damage calculation.

signal train_destroyed(cargo: Array)
signal train_respawned

const MAX_COMPARTMENTS: int = 8
const BASE_BODY_DAMAGE: float = 15.0
const BASE_SPEED: float = 200.0

@export var respawn_delay: float = 3.0

var compartments: Array = []
var locomotive: Node = null
var _hp: float = 100.0
var _max_hp: float = 100.0
var _respawn_timer: Timer

func _ready() -> void:
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_do_respawn)
	add_child(_respawn_timer)

func setup(loco: Node) -> void:
	locomotive = loco

func add_compartment(compartment_scene: PackedScene) -> void:
	if compartments.size() >= MAX_COMPARTMENTS:
		return
	var c = compartment_scene.instantiate()
	c.index = compartments.size()
	get_node("CompartmentContainer").add_child(c)
	compartments.append(c)

func get_body_damage(current_speed: float) -> float:
	var speed_ratio: float = current_speed / BASE_SPEED
	return BASE_BODY_DAMAGE * compartments.size() * speed_ratio

func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0.0:
		_on_destroyed()

func _on_destroyed() -> void:
	var cargo: Array = _collect_cargo()
	train_destroyed.emit(cargo)
	_respawn_timer.start(respawn_delay)
	hide()

func _collect_cargo() -> Array:
	var cargo: Array = []
	for c in compartments:
		if c.has_method("get_cargo"):
			cargo.append_array(c.get_cargo())
			c.clear_cargo()
	return cargo

func _do_respawn() -> void:
	_hp = _max_hp
	# Reposition to village gate — World provides spawn point
	if get_parent() and get_parent().has_node("World/Village"):
		var village = get_parent().get_node("World/Village")
		if locomotive:
			locomotive.global_position = village.global_position + Vector2(0, 160)
	show()
	train_respawned.emit()

func remove_compartment(index: int) -> void:
	if index < 0 or index >= compartments.size():
		return
	var c = compartments[index]
	compartments.remove_at(index)
	c.queue_free()
	# Renumber remaining
	for i in compartments.size():
		compartments[i].index = i

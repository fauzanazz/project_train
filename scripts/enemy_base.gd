extends CharacterBody2D
## res://scripts/enemy_base.gd
## Base class for all zombie/enemy types. Owns HP, movement AI, and damage dispatch.

signal zombie_killed(xp: int, position: Vector2, resource_drop: Dictionary)

enum AIType { PATH_TO_VILLAGE, PATH_TO_PLAYER, HYBRID }

@export var max_hp: float = 30.0
@export var base_speed: float = 60.0
@export var body_damage: float = 5.0   # damage dealt to train per second on contact
@export var wall_damage: float = 3.0   # damage dealt to village walls per second
@export var xp_value: int = 10
@export var ai_type: AIType = AIType.PATH_TO_VILLAGE
@export var hybrid_switch_range: float = 400.0  # switch to player targeting within this range

var hp: float = max_hp
var speed: float = base_speed
var slow_multiplier: float = 1.0
var _slow_timer: float = 0.0
var _nav_agent: NavigationAgent2D

func _ready() -> void:
	hp = max_hp
	_nav_agent = $NavigationAgent2D if has_node("NavigationAgent2D") else null
	add_to_group("enemies")
	_on_spawn_scale()

func _on_spawn_scale() -> void:
	var wave: int = WaveManager.current_wave
	hp = DifficultyManager.get_enemy_hp(max_hp, wave)
	speed = DifficultyManager.get_enemy_speed(base_speed, wave)

func _physics_process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
	var effective_speed: float = speed * slow_multiplier if _slow_timer > 0.0 else speed
	var target: Vector2 = _get_target_position()
	if _nav_agent:
		_nav_agent.target_position = target
		var dir: Vector2 = _nav_agent.get_next_path_position() - global_position
		if dir.length_squared() > 1.0:
			velocity = dir.normalized() * effective_speed
	else:
		var dir: Vector2 = (target - global_position)
		if dir.length_squared() > 100.0:
			velocity = dir.normalized() * effective_speed
	move_and_slide()

func _get_target_position() -> Vector2:
	var player_pos: Vector2 = _find_player_position()
	match ai_type:
		AIType.PATH_TO_VILLAGE:
			return _find_village_position()
		AIType.PATH_TO_PLAYER:
			return player_pos
		AIType.HYBRID:
			var dist: float = global_position.distance_to(player_pos)
			if dist <= hybrid_switch_range:
				return player_pos
			return _find_village_position()
	return _find_village_position()

func _find_village_position() -> Vector2:
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	return village.global_position if village else Vector2.ZERO

func _find_player_position() -> Vector2:
	var loco = get_tree().get_first_node_in_group("locomotive") if get_tree() else null
	return loco.global_position if loco else Vector2.ZERO

func take_damage(amount: float, damage_type: String = "kinetic") -> void:
	var effective: float = _apply_resistances(amount, damage_type)
	hp -= effective
	if hp <= 0.0:
		_die()

func _apply_resistances(amount: float, _type: String) -> float:
	return amount  # Override in subclasses for resistances

func apply_slow(factor: float, duration: float) -> void:
	slow_multiplier = factor
	_slow_timer = duration

func _die() -> void:
	zombie_killed.emit(xp_value, global_position, _get_resource_drop())
	PlayerManager.add_xp(xp_value)
	WaveManager.register_enemy_death()
	queue_free()

func _get_resource_drop() -> Dictionary:
	return {}  # Override in subclasses for resource drops

func _draw() -> void:
	pass  # Visual drawing implemented per-subclass in Task 2

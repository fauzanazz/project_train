extends CharacterBody2D
## res://scripts/enemy_base.gd
## Base class for all zombie/enemy types. Owns HP, movement AI, and damage dispatch.

signal zombie_killed(xp: int, position: Vector2, resource_drop: Dictionary)

enum AIType { PATH_TO_VILLAGE, PATH_TO_PLAYER, HYBRID }

@export var max_hp: float = 30.0
@export var base_speed: float = 60.0
@export var body_damage: float = 5.0
@export var wall_damage: float = 3.0
@export var xp_value: int = 10
@export var ai_type: AIType = AIType.PATH_TO_VILLAGE
@export var hybrid_switch_range: float = 400.0
@export var contact_damage: float = 3.0  # damage dealt to train on contact per second

var hp: float = max_hp
var speed: float = base_speed
var slow_multiplier: float = 1.0
var _slow_timer: float = 0.0
var _nav_agent: NavigationAgent2D
var _hit_area: Area2D
var _flash_timer: float = 0.0
var _wall_contact: bool = false

func _ready() -> void:
	hp = max_hp
	_nav_agent = $NavigationAgent2D if has_node("NavigationAgent2D") else null
	_hit_area = $HitArea if has_node("HitArea") else null
	add_to_group("enemies")
	_on_spawn_scale()

func _on_spawn_scale() -> void:
	var wave: int = WaveManager.current_wave
	hp = DifficultyManager.get_enemy_hp(max_hp, wave)
	speed = DifficultyManager.get_enemy_speed(base_speed, wave)

func _physics_process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
	var effective_speed: float = speed * (slow_multiplier if _slow_timer > 0.0 else 1.0) * delta
	var target: Vector2 = _get_target_position()
	if _nav_agent:
		_nav_agent.target_position = target
		var next_pos: Vector2 = _nav_agent.get_next_path_position()
		var dir: Vector2 = (next_pos - global_position)
		if dir.length_squared() > 4.0:
			velocity = dir.normalized() * effective_speed / delta
			rotation = dir.angle()
		else:
			velocity = Vector2.ZERO
	else:
		var dir: Vector2 = (target - global_position)
		if dir.length_squared() > 100.0:
			velocity = dir.normalized() * effective_speed / delta
			rotation = dir.angle()
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	_check_wall_contact(delta)
	_flash_timer = max(0.0, _flash_timer - delta)

func _process(_delta: float) -> void:
	queue_redraw()

func _check_wall_contact(delta: float) -> void:
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if not village:
		return
	var dist := global_position.distance_to(village.global_position)
	if dist < 170.0:  # Within wall radius (village is 300x300, half is 150 + margin)
		_wall_contact = true
		village.take_damage(wall_damage * delta)
		# Slow down at wall
		velocity *= 0.5
	else:
		_wall_contact = false

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
	_flash_timer = 0.12
	if hp <= 0.0:
		_die()

func _apply_resistances(amount: float, _type: String) -> float:
	return amount

func apply_slow(factor: float, duration: float) -> void:
	slow_multiplier = factor
	_slow_timer = duration

func _die() -> void:
	# Notify before freeing — emit signal first
	zombie_killed.emit(xp_value, global_position, _get_resource_drop())
	PlayerManager.add_xp(xp_value)
	WaveManager.register_enemy_death()
	# Check for resource drop position
	var drop = _get_resource_drop()
	if not drop.is_empty():
		ResourceManager.deliver_resources(drop.get("type", ""), drop.get("amount", 0))
	queue_free()

func _get_resource_drop() -> Dictionary:
	return {}

func _draw() -> void:
	_draw_body()
	_draw_hp_bar()
	# Flash white on hit
	if _flash_timer > 0.0:
		var r := _get_radius()
		draw_circle(Vector2.ZERO, r, Color(1.0, 1.0, 1.0, 0.4))

func _draw_body() -> void:
	# Override in subclass
	draw_circle(Vector2.ZERO, 12.0, Color("#6B8E6B"))

func _draw_hp_bar() -> void:
	if hp >= max_hp:
		return
	var bar_width: float = 24.0
	var bar_height: float = 3.0
	var y_offset: float = -(_get_radius() + 8.0)
	var ratio: float = hp / max_hp
	draw_rect(Rect2(-bar_width * 0.5, y_offset, bar_width, bar_height), Color("#333333"))
	var fill_color := Color("#22CC22") if ratio > 0.5 else Color("#FF4444")
	draw_rect(Rect2(-bar_width * 0.5, y_offset, bar_width * ratio, bar_height), fill_color)

func _get_radius() -> float:
	return 12.0
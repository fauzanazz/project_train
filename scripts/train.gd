extends Node2D
## res://scripts/train.gd
## Manages compartment chain, cargo, body damage, weapon tick, and resource delivery.

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
var _weapon: Node = null
var body_damage_multiplier: float = 1.0
var damage_reduction: float = 0.0  # 0 to 0.25 for armor
var _bounce_slow_pending: bool = false

var locomotive_cargo: String = ""
var locomotive_cargo_amount: int = 0

func _ready() -> void:
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_do_respawn)
	add_child(_respawn_timer)
	locomotive = get_node_or_null("Locomotive")
	# Stagger compartment setup
	await get_tree().process_frame
	# Ensure train starts with at least 1 compartment
	if compartments.is_empty():
		var comp_scene = load("res://scenes/compartment.tscn")
		if comp_scene:
			add_compartment(comp_scene)
	# Give starting weapon — gatling on locomotive
	_attach_starting_weapon()

func _physics_process(delta: float) -> void:
	# Tick weapon
	if _weapon and _weapon.has_method("tick"):
		_weapon.tick(delta)
	# Tick compartment modifiers
	for comp in compartments:
		if comp and comp.modifier and comp.modifier.has_method("tick"):
			comp.modifier.tick(delta)
	# Handle body damage to enemies
	_deal_body_damage(delta)
	# Check for village gate delivery
	_check_village_delivery()

func _attach_starting_weapon() -> void:
	if not locomotive:
		return
	var slot = locomotive.get_node_or_null("WeaponSlot")
	if not slot:
		return
	for child in slot.get_children():
		child.queue_free()
	var weapon = Node.new()
	weapon.set_script(load("res://scripts/weapon_gatling.gd"))
	weapon.name = "Weapon"
	slot.add_child(weapon)
	weapon.on_attach(locomotive)
	if weapon.has_signal("projectile_spawn"):
		weapon.projectile_spawn.connect(_on_projectile_spawn)
	_weapon = weapon

func _deal_body_damage(delta: float) -> void:
	if not locomotive:
		return
	var speed_ratio: float = locomotive.get_speed_ratio() if locomotive.has_method("get_speed_ratio") else 1.0
	if speed_ratio < 0.3:
		return  # Not moving fast enough for body damage
	var damage_per_sec := BASE_BODY_DAMAGE * body_damage_multiplier * speed_ratio
	var hit_damage: float = damage_per_sec * delta
	# Check locomotive body damage area
	var bda = locomotive.get_node_or_null("BodyDamageArea")
	if bda and bda is Area2D:
		for body in bda.get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				var enemy_hp_before: float = body.hp if "hp" in body else 999.0
				body.take_damage(hit_damage, "kinetic")
				_spawn_sparks_at(body.global_position)
				# Check if enemy survived
				var enemy_hp_after: float = body.hp if "hp" in body else 0.0
				if enemy_hp_after > 0.0:
					# Enemy survived — bounce both apart
					_apply_bounce(locomotive, body)
	# Check compartment body damage areas
	for comp in compartments:
		if not comp:
			continue
		var comp_bda = comp.get_node_or_null("BodyDamageArea")
		if comp_bda and comp_bda is Area2D:
			for body in comp_bda.get_overlapping_bodies():
				if body.is_in_group("enemies") and body.has_method("take_damage"):
					var comp_damage: float = hit_damage * 0.7
					var enemy_hp_before: float = body.hp if "hp" in body else 999.0
					body.take_damage(comp_damage, "kinetic")
					_spawn_sparks_at(body.global_position)
					var enemy_hp_after: float = body.hp if "hp" in body else 0.0
					if enemy_hp_after > 0.0:
						_apply_bounce(comp, body)

func _apply_bounce(train_segment: Node2D, enemy: Node2D) -> void:
	var push_dir: Vector2 = train_segment.global_position.direction_to(enemy.global_position)
	var bounce_strength := 150.0
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(push_dir, bounce_strength)
	# Only apply speed slow if not already pending (prevents accumulation)
	if locomotive and not _bounce_slow_pending:
		_bounce_slow_pending = true
		locomotive.speed_multiplier = maxf(0.3, locomotive.speed_multiplier - 0.2)
		get_tree().create_timer(0.3).timeout.connect(func():
			if is_instance_valid(locomotive):
				locomotive.speed_multiplier = minf(locomotive.speed_multiplier + 0.2, 2.0)
			_bounce_slow_pending = false
		)

func _spawn_sparks_at(pos: Vector2) -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	# Throttle spark spawning to avoid performance issues
	if randf() > 0.15:
		return
	var spark = Node2D.new()
	spark.set_script(_create_spark_script())
	spark.global_position = pos
	get_tree().current_scene.add_child(spark)

func _create_spark_script() -> Script:
	var src = "
extends Node2D
var _time := 0.2
func _process(delta):
	_time -= delta
	if _time <= 0:
		queue_free()
	queue_redraw()
func _draw():
	var alpha := maxf(0, _time / 0.2)
	for i in 3:
		var angle := i * TAU / 3.0 + randf() * 0.5
		var len := 4.0 + randf() * 4.0
		draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * len, Color(1.0, 0.8, 0.2, alpha), 2.0)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.5, alpha))"
	var script = GDScript.new()
	script.source_code = src
	script.reload()
	return script

func _check_village_delivery() -> void:
	if not locomotive:
		return
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if not village:
		return
	# Check if locomotive is near village gate (south side)
	var gate_pos: Vector2 = village.global_position + Vector2(0, 160)
	var dist: float = locomotive.global_position.distance_to(gate_pos)
	if dist < 60.0:
		_deliver_resources()

func _deliver_resources() -> void:
	# Unload locomotive fallback cargo
	if not locomotive_cargo.is_empty():
		ResourceManager.deliver_resources(locomotive_cargo, locomotive_cargo_amount)
		locomotive_cargo = ""
		locomotive_cargo_amount = 0
	# Unload all cargo from compartments
	for comp in compartments:
		if not comp:
			continue
		if comp.cargo and not comp.cargo.is_empty():
			ResourceManager.deliver_resources(comp.cargo, comp.cargo_amount)
			comp.clear_cargo()

func _on_projectile_spawn(origin: Vector2, direction: Vector2, data: Dictionary) -> void:
	var proj_scene: PackedScene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return
	var proj = proj_scene.instantiate()
	proj.setup(origin, direction, data)
	# Find world node to add projectile to
	var world = get_tree().current_scene.get_node_or_null("World") if get_tree() else null
	if world:
		world.add_child(proj)
	elif get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(proj)

func add_compartment(compartment_scene: PackedScene) -> void:
	if compartments.size() >= MAX_COMPARTMENTS:
		return
	var c = compartment_scene.instantiate()
	c.index = compartments.size()
	get_node("CompartmentContainer").add_child(c)
	c.compartment_destroyed.connect(_on_compartment_destroyed)
	compartments.append(c)

func _on_compartment_destroyed(comp_index: int) -> void:
	# Remove the compartment from the chain
	var to_remove: Node = null
	for i in compartments.size():
		if compartments[i] and compartments[i].index == comp_index:
			to_remove = compartments[i]
			compartments.remove_at(i)
			break
	# Re-index remaining compartments
	for i in compartments.size():
		if compartments[i]:
			compartments[i].index = i
	# Screen shake on compartment loss
	ScreenShake.shake(0.3, 8.0)

func try_collect_resource(type: String, amount: int) -> bool:
	for c in compartments:
		if c.has_method("load_cargo") and c.cargo.is_empty():
			return c.load_cargo(type, amount)
	# Fallback: locomotive holds cargo if no compartment has space
	if locomotive_cargo.is_empty():
		locomotive_cargo = type
		locomotive_cargo_amount = amount
		return true
	return false

func get_body_damage(current_speed: float) -> float:
	var speed_ratio: float = current_speed / BASE_SPEED
	return BASE_BODY_DAMAGE * body_damage_multiplier * compartments.size() * speed_ratio

func take_damage(amount: float) -> void:
	var effective := amount * (1.0 - damage_reduction)
	_hp -= effective
	if _hp <= 0.0:
		_on_destroyed()

func _on_destroyed() -> void:
	var cargo: Array = _collect_cargo()
	train_destroyed.emit(cargo)
	# Hide train, respawn after delay
	if locomotive:
		locomotive.visible = false
		locomotive.set_physics_process(false)
	for comp in compartments:
		if is_instance_valid(comp):
			comp.visible = false
			comp.set_physics_process(false)
	_respawn_timer.start(respawn_delay)

func _collect_cargo() -> Array:
	var cargo: Array = []
	if not locomotive_cargo.is_empty():
		cargo.append({"type": locomotive_cargo, "amount": locomotive_cargo_amount})
		locomotive_cargo = ""
		locomotive_cargo_amount = 0
	for c in compartments:
		if c and c.has_method("get_cargo"):
			cargo.append_array(c.get_cargo())
			c.clear_cargo()
	return cargo

func _do_respawn() -> void:
	_hp = _max_hp
	var village = get_tree().get_first_node_in_group("village") if get_tree() else null
	if village and locomotive:
		locomotive.global_position = village.global_position + Vector2(0, 180)
		locomotive.visible = true
		locomotive.set_physics_process(true)
	for comp in compartments:
		if is_instance_valid(comp):
			comp.visible = true
			comp.set_physics_process(true)
	train_respawned.emit()

func remove_compartment(index: int) -> void:
	if index < 0 or index >= compartments.size():
		return
	var c = compartments[index]
	compartments.remove_at(index)
	if is_instance_valid(c):
		c.queue_free()
	for i in compartments.size():
		compartments[i].index = i
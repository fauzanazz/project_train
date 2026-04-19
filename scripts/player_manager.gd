extends Node
## res://scripts/player_manager.gd
## Owns XP ledger, player level, and level-up card dispatch. Singleton autoloaded as PlayerManager.

signal xp_changed(new_xp: int, max_xp: int)
signal level_changed(new_level: int)
signal level_up_offer(choices: Array)

var current_xp: int = 0
var current_level: int = 1
var _xp_for_next: int = 100

# Expanded level-up card pool including Task 3 weapons and modifiers
const CARD_POOL := [
	{"id": "gatling", "name": "Gatling Gun", "desc": "Auto-aims nearest enemy, 8 dmg", "type": "weapon"},
	{"id": "flamethrower", "name": "Flamethrower", "desc": "Continuous cone, 5 dmg/s", "type": "weapon"},
	{"id": "mortar", "name": "Mortar", "desc": "Lobbed explosive, 35 dmg AoE", "type": "weapon"},
	{"id": "taser", "name": "Taser Mk1", "desc": "Electric, 50% slow on hit", "type": "weapon"},
	{"id": "railgun", "name": "Rail Cannon", "desc": "Instant pierce, 80 dmg", "type": "weapon"},
	{"id": "tesla", "name": "Tesla Coil", "desc": "Chains lightning to 3 enemies", "type": "weapon"},
	{"id": "devastator", "name": "Devastator", "desc": "Full-screen AoE, 200 dmg", "type": "weapon"},
	{"id": "turbo_engine", "name": "Turbo Engine", "desc": "+15% train speed", "type": "passive"},
	{"id": "heavy_frame", "name": "Heavy Frame", "desc": "+20% body damage", "type": "passive"},
	{"id": "armor_plating", "name": "Armor Plating", "desc": "25% damage reduction", "type": "passive"},
	{"id": "cargo_expansion", "name": "Cargo Expansion", "desc": "+1 compartment", "type": "passive"},
	{"id": "resource_magnet", "name": "Resource Magnet", "desc": "Attract resources within 200px", "type": "utility"},
	{"id": "repair_drone", "name": "Repair Drone", "desc": "Repairs 2 HP/s on compartment", "type": "utility"},
	{"id": "shield_bubble", "name": "Shield Bubble", "desc": "Absorbs 100 dmg, 30s cooldown", "type": "utility"},
]

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	current_xp = 0
	current_level = 1
	_xp_for_next = _xp_threshold(1)

func _xp_threshold(level: int) -> int:
	return int(100.0 * pow(level, 1.4))

func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, _xp_for_next)
	while current_xp >= _xp_for_next:
		current_xp -= _xp_for_next
		current_level += 1
		_xp_for_next = _xp_threshold(current_level)
		level_changed.emit(current_level)
		_offer_level_up()

func _offer_level_up() -> void:
	var choices := _generate_choices(3)
	level_up_offer.emit(choices)

func _generate_choices(count: int) -> Array:
	var pool := CARD_POOL.duplicate()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

func apply_choice(choice: Dictionary) -> void:
	var train = _find_train()
	if not train:
		return
	match choice["id"]:
		"gatling":
			_attach_weapon_to_train("res://scripts/weapon_gatling.gd")
		"flamethrower":
			_attach_weapon_to_train("res://scripts/weapon_flamethrower.gd")
		"mortar":
			_attach_weapon_to_train("res://scripts/weapon_mortar.gd")
		"taser":
			_attach_weapon_to_train("res://scripts/weapon_taser.gd")
		"railgun":
			_attach_weapon_to_train("res://scripts/weapon_railgun.gd")
		"tesla":
			_attach_weapon_to_train("res://scripts/weapon_tesla.gd")
		"devastator":
			_attach_weapon_to_train("res://scripts/weapon_devastator.gd")
		"turbo_engine":
			if train.locomotive:
				train.locomotive.speed_multiplier += 0.15
		"heavy_frame":
			train.body_damage_multiplier += 0.2
		"armor_plating":
			train.damage_reduction += 0.25
		"cargo_expansion":
			train.add_compartment(load("res://scenes/compartment.tscn"))
		"resource_magnet":
			_attach_utility_to_train("res://scripts/modifier_resource_magnet.gd")
		"repair_drone":
			_attach_utility_to_train("res://scripts/modifier_repair_drone.gd")
		"shield_bubble":
			_attach_utility_to_train("res://scripts/modifier_shield_bubble.gd")

func _attach_weapon_to_train(script_path: String) -> void:
	var train = _find_train()
	if not train or not train.locomotive:
		return
	var slot = train.locomotive.get_node_or_null("WeaponSlot")
	if not slot:
		return
	for child in slot.get_children():
		child.queue_free()
	var weapon = Node.new()
	weapon.set_script(load(script_path))
	weapon.name = "Weapon"
	slot.add_child(weapon)
	weapon.on_attach(train.locomotive)
	if weapon.has_signal("projectile_spawn"):
		weapon.projectile_spawn.connect(train._on_projectile_spawn)

func _attach_utility_to_train(script_path: String) -> void:
	var train = _find_train()
	if not train or not train.locomotive:
		return
	# Attach to first compartment's utility slot, or locomotive's utility slot
	var target = null
	if train.compartments.size() > 0 and is_instance_valid(train.compartments[0]):
		target = train.compartments[0]
	else:
		target = train.locomotive
	if not target:
		return
	var util_slot = target.get_node_or_null("UtilitySlot")
	if not util_slot:
		return
	var mod = Node.new()
	mod.set_script(load(script_path))
	mod.name = "Utility"
	util_slot.add_child(mod)
	mod.on_attach(target)

func _find_train() -> Node:
	if get_tree():
		var locos = get_tree().get_nodes_in_group("locomotive")
		if locos.size() > 0:
			return locos[0].get_parent() if locos[0].get_parent() else null
	return null

func _on_zombie_killed(xp: int, _position: Vector2, _resource_drop: Dictionary) -> void:
	add_xp(xp)

func _on_train_destroyed(_cargo: Array) -> void:
	# XP is kept on train destruction
	pass
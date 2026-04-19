extends Node
## res://scripts/player_manager.gd
## Owns XP ledger, player level, and level-up card dispatch. Singleton autoloaded as PlayerManager.

signal xp_changed(new_xp: int, max_xp: int)
signal level_changed(new_level: int)
signal level_up_offer(choices: Array)

var current_xp: int = 0
var current_level: int = 1
var _xp_for_next: int = 100

const WEAPON_DEFS := {
	"gatling_mk1": {"name": "Gatling Gun", "desc": "Auto-aims nearest, 8 dmg", "script": "res://scripts/weapon_gatling.gd"},
	"flamethrower_mk1": {"name": "Flamethrower", "desc": "Continuous cone, 5 dmg/s", "script": "res://scripts/weapon_flamethrower.gd"},
	"mortar_mk1": {"name": "Mortar", "desc": "Lobbed explosive, 35 dmg AoE", "script": "res://scripts/weapon_mortar.gd"},
	"taser_mk1": {"name": "Taser", "desc": "Electric, 50% slow on hit", "script": "res://scripts/weapon_taser.gd"},
	"railgun_mk1": {"name": "Rail Cannon", "desc": "Instant pierce, 80 dmg", "script": "res://scripts/weapon_railgun.gd"},
	"tesla_mk1": {"name": "Tesla Coil", "desc": "Chains lightning to 3 enemies", "script": "res://scripts/weapon_tesla.gd"},
	"devastator": {"name": "Devastator", "desc": "Full-screen AoE, 200 dmg", "script": "res://scripts/weapon_devastator.gd"},
}

const UTILITY_DEFS := {
	"resource_magnet": {"name": "Resource Magnet", "desc": "Attract resources within 200px", "script": "res://scripts/modifier_resource_magnet.gd"},
	"repair_drone": {"name": "Repair Drone", "desc": "Repairs 2 HP/s on compartment", "script": "res://scripts/modifier_repair_drone.gd"},
	"shield_bubble": {"name": "Shield Bubble", "desc": "Absorbs 100 dmg, 30s cooldown", "script": "res://scripts/modifier_shield_bubble.gd"},
}

const PASSIVE_DEFS := {
	"turbo_engine": {"name": "Turbo Engine", "desc": "+15% train speed"},
	"heavy_frame": {"name": "Heavy Frame", "desc": "+20% body damage"},
	"armor_plating": {"name": "Armor Plating", "desc": "25% damage reduction"},
	"cargo_expansion": {"name": "Cargo Expansion", "desc": "+1 compartment"},
}

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
	var pool: Array = []
	var scan := _scan_equipped()
	var equipped_weapon_ids: Array = []
	var equipped_utility_ids: Array = []

	for mod in scan.weapons:
		equipped_weapon_ids.append(mod.id)
		if mod.upgrade_level < mod.get_max_level():
			pool.append({
				"id": mod.id,
				"name": mod.display_name,
				"type": "weapon_upgrade",
				"current_level": mod.upgrade_level,
				"next_level": mod.upgrade_level + 1,
				"upgrade_name": mod.get_next_upgrade_name(),
				"upgrade_desc": mod.get_next_upgrade_desc(),
			})

	for mod in scan.utilities:
		equipped_utility_ids.append(mod.id)
		if mod.upgrade_level < mod.get_max_level():
			pool.append({
				"id": mod.id,
				"name": mod.display_name,
				"type": "utility_upgrade",
				"current_level": mod.upgrade_level,
				"next_level": mod.upgrade_level + 1,
				"upgrade_name": mod.get_next_upgrade_name(),
				"upgrade_desc": mod.get_next_upgrade_desc(),
			})

	if _has_empty_slot("WeaponSlot"):
		for w_id in WEAPON_DEFS:
			if w_id not in equipped_weapon_ids:
				var def = WEAPON_DEFS[w_id]
				pool.append({
					"id": w_id,
					"name": def["name"],
					"desc": def["desc"],
					"type": "weapon_new",
				})

	if _has_empty_slot("UtilitySlot"):
		for u_id in UTILITY_DEFS:
			if u_id not in equipped_utility_ids:
				var def = UTILITY_DEFS[u_id]
				pool.append({
					"id": u_id,
					"name": def["name"],
					"desc": def["desc"],
					"type": "utility_new",
				})

	for p_id in PASSIVE_DEFS:
		var def = PASSIVE_DEFS[p_id]
		pool.append({
			"id": p_id,
			"name": def["name"],
			"desc": def["desc"],
			"type": "passive",
		})

	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

func apply_choice(choice: Dictionary) -> void:
	var card_type: String = choice.get("type", "")
	match card_type:
		"weapon_upgrade", "utility_upgrade":
			var mod = _find_equipped_modifier(choice["id"])
			if mod:
				mod.on_level_up(choice["next_level"])
		"weapon_new":
			_attach_modifier("WeaponSlot", WEAPON_DEFS[choice["id"]]["script"])
		"utility_new":
			_attach_modifier("UtilitySlot", UTILITY_DEFS[choice["id"]]["script"])
		"passive":
			_apply_passive(choice["id"])

func _apply_passive(passive_id: String) -> void:
	var train = _find_train()
	if not train:
		return
	match passive_id:
		"turbo_engine":
			if train.locomotive:
				train.locomotive.speed_multiplier += 0.15
		"heavy_frame":
			train.body_damage_multiplier += 0.2
		"armor_plating":
			train.damage_reduction += 0.25
		"cargo_expansion":
			train.add_compartment(load("res://scenes/compartment.tscn"))

func _attach_modifier(slot_name: String, script_path: String) -> void:
	var train = _find_train()
	if not train:
		return
	var slot = _find_empty_slot(slot_name)
	if not slot:
		return
	var mod = Node.new()
	mod.set_script(load(script_path))
	mod.name = "Weapon" if slot_name == "WeaponSlot" else "Utility"
	slot.add_child(mod)
	var compartment = slot.get_parent()
	mod.on_attach(compartment)
	if mod.has_signal("projectile_spawn") and train.has_method("_on_projectile_spawn"):
		mod.projectile_spawn.connect(train._on_projectile_spawn)

func _scan_equipped() -> Dictionary:
	var weapons: Array = []
	var utilities: Array = []
	var train = _find_train()
	if not train:
		return {"weapons": weapons, "utilities": utilities}
	var candidates: Array = []
	if train.locomotive:
		candidates.append(train.locomotive)
	if "compartments" in train:
		for comp in train.compartments:
			if is_instance_valid(comp):
				candidates.append(comp)
	for node in candidates:
		_collect_modifiers(node, "WeaponSlot", weapons)
		_collect_modifiers(node, "UtilitySlot", utilities)
	return {"weapons": weapons, "utilities": utilities}

func _collect_modifiers(node: Node, slot_name: String, out_array: Array) -> void:
	var slot = node.get_node_or_null(slot_name)
	if not slot:
		return
	for child in slot.get_children():
		if child.has_method("get_next_upgrade_name") and "upgrade_level" in child:
			out_array.append(child)

func _find_equipped_modifier(mod_id: String) -> Node:
	var scan := _scan_equipped()
	for mod in scan.weapons:
		if mod.id == mod_id:
			return mod
	for mod in scan.utilities:
		if mod.id == mod_id:
			return mod
	return null

func _has_empty_slot(slot_name: String) -> bool:
	return _find_empty_slot(slot_name) != null

func _find_empty_slot(slot_name: String) -> Node:
	var train = _find_train()
	if not train:
		return null
	var candidates: Array = []
	if train.locomotive:
		candidates.append(train.locomotive)
	if "compartments" in train:
		for comp in train.compartments:
			if is_instance_valid(comp):
				candidates.append(comp)
	for node in candidates:
		var slot = node.get_node_or_null(slot_name)
		if not slot:
			continue
		var has_modifier := false
		for child in slot.get_children():
			if child.has_method("get_next_upgrade_name"):
				has_modifier = true
				break
		if not has_modifier:
			return slot
	return null

func _find_train() -> Node:
	if get_tree():
		var locos = get_tree().get_nodes_in_group("locomotive")
		if locos.size() > 0:
			return locos[0].get_parent() if locos[0].get_parent() else null
	return null

func _on_zombie_killed(xp: int, _position: Vector2, _resource_drop: Dictionary) -> void:
	add_xp(xp)

func _on_train_destroyed(_cargo: Array) -> void:
	pass

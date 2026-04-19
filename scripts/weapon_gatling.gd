extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_gatling.gd
## Gatling Gun Mk1 — kinetic, auto-aims nearest enemy within range.

const BASE_DAMAGE: float = 8.0
const BASE_FIRE_RATE: float = 0.12
const BASE_RANGE: float = 300.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var _cooldown: float = 0.0
var _spin_up: float = 0.0

var armor_piercing: bool = false
var dual_barrel: bool = false
var instant_spin: bool = false

func _init() -> void:
	id = "gatling_mk1"
	display_name = "Gatling Gun"
	tier = ModifierTier.BASIC
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Overclocked Barrel", "Armor Piercing", "Dual Barrel", "Minigun Mode"])
	upgrade_descs = PackedStringArray(["Fire rate +20%", "+50% vs armored", "Fires 2 projectiles", "No spin-up time"])

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0
	_spin_up = 0.0

func tick(dt: float) -> void:
	if instant_spin:
		_spin_up = 1.0
	else:
		_spin_up = move_toward(_spin_up, 1.0, dt)
	_cooldown -= dt * _spin_up
	if _cooldown <= 0.0:
		var target = _find_target(range_px)
		if target:
			var shots: int = 2 if dual_barrel else 1
			for _i in shots:
				_fire_at(target)
			_cooldown = fire_rate

func _fire_at(target: Node) -> void:
	if not _compartment or not target is Node2D:
		return
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	projectile_spawn.emit(_compartment.global_position, dir, {
		"damage": damage,
		"range": range_px,
		"type": "kinetic",
		"piercing": 0,
		"aoe_radius": 0.0,
		"armor_piercing": armor_piercing,
	})

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage = BASE_DAMAGE + (new_level - 1) * 3.0
	fire_rate = BASE_FIRE_RATE
	armor_piercing = false
	dual_barrel = false
	instant_spin = false
	if new_level >= 2:
		fire_rate *= 0.8
	if new_level >= 3:
		armor_piercing = true
	if new_level >= 4:
		dual_barrel = true
	if new_level >= 5:
		instant_spin = true

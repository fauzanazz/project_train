extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_taser.gd
## Taser Mk1 — electric, slows target 50% on hit.

const BASE_DAMAGE: float = 12.0
const BASE_FIRE_RATE: float = 0.8
const BASE_RANGE: float = 250.0
const BASE_SLOW_FACTOR: float = 0.5
const SLOW_DURATION: float = 2.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var slow_factor: float = BASE_SLOW_FACTOR
var chain_bolt: bool = false
var stun_chance: float = 0.0
var tesla_overload: bool = false
var _cooldown: float = 0.0
var _muzzle_flash_timer: float = 0.0

func _init() -> void:
	id = "taser_mk1"
	display_name = "Taser"
	tier = ModifierTier.BASIC
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Deep Shock", "Chain Bolt", "Stun Round", "Tesla Overload"])
	upgrade_descs = PackedStringArray(["Slow 50% → 70%", "Arcs to 1 extra enemy", "20% stun for 1s", "Every 5 hits, AoE burst"])

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0

func tick(dt: float) -> void:
	_muzzle_flash_timer = maxf(0.0, _muzzle_flash_timer - dt)
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	var target = _find_target(range_px)
	if not target:
		return
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	projectile_spawn.emit(_compartment.global_position, dir, {
		"damage": damage,
		"range": range_px,
		"type": "electric",
		"piercing": 0,
		"aoe_radius": 0.0,
		"slow_factor": slow_factor,
		"slow_duration": SLOW_DURATION,
		"speed": 500.0,
		"chain_bolt": chain_bolt,
		"stun_chance": stun_chance,
		"tesla_overload": tesla_overload,
	})
	_cooldown = fire_rate
	_muzzle_flash_timer = 0.06

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage = BASE_DAMAGE + (new_level - 1) * 4.0
	fire_rate = BASE_FIRE_RATE
	slow_factor = BASE_SLOW_FACTOR
	chain_bolt = false
	stun_chance = 0.0
	tesla_overload = false
	if new_level >= 2:
		slow_factor = 0.7
	if new_level >= 3:
		chain_bolt = true
	if new_level >= 4:
		stun_chance = 0.2
	if new_level >= 5:
		tesla_overload = true

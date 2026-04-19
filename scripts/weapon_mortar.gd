extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_mortar.gd
## Mortar Mk1 — lobbed projectile, explosive AoE on landing. Arc trajectory.

const BASE_DAMAGE: float = 35.0
const BASE_FIRE_RATE: float = 2.0
const BASE_RANGE: float = 400.0
const BASE_AOE_RADIUS: float = 60.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var range_px: float = BASE_RANGE
var aoe_radius: float = BASE_AOE_RADIUS
var incendiary: bool = false
var barrage: bool = false
var _cooldown: float = 0.0
var _muzzle_flash_timer: float = 0.0

func _init() -> void:
	id = "mortar_mk1"
	display_name = "Mortar"
	tier = ModifierTier.BASIC
	slot_type = SlotType.WEAPON
	upgrade_names = PackedStringArray(["Heavy Shell", "Rapid Reload", "Incendiary Round", "Barrage Mode"])
	upgrade_descs = PackedStringArray(["AoE +30%", "Cooldown 2.0s → 1.4s", "Leaves fire patch", "Fires 3 shells"])

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
	_fire_at(target)
	_cooldown = fire_rate
	_muzzle_flash_timer = 0.08

func _fire_at(target: Node) -> void:
	if not _compartment or not target is Node2D:
		return
	var dir: Vector2 = _compartment.global_position.direction_to(target.global_position)
	var shell_count: int = 3 if barrage else 1
	for i in shell_count:
		var spread_angle: float = 0.0
		if shell_count > 1:
			spread_angle = deg_to_rad((i - 1) * 8.0)
		var adjusted_dir := dir.rotated(spread_angle)
		projectile_spawn.emit(_compartment.global_position, adjusted_dir, {
			"damage": damage,
			"range": range_px,
			"type": "explosive",
			"piercing": 0,
			"aoe_radius": aoe_radius,
			"arc": true,
			"speed": 300.0,
			"incendiary": incendiary,
		})
	ScreenShake.shake(0.1, 3.0)

func on_level_up(new_level: int) -> void:
	super(new_level)
	damage = BASE_DAMAGE + (new_level - 1) * 10.0
	aoe_radius = BASE_AOE_RADIUS
	fire_rate = BASE_FIRE_RATE
	incendiary = false
	barrage = false
	if new_level >= 2:
		aoe_radius *= 1.3
	if new_level >= 3:
		fire_rate = 1.4
	if new_level >= 4:
		incendiary = true
	if new_level >= 5:
		barrage = true

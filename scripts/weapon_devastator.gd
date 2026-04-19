extends "res://scripts/modifier_base.gd"
## res://scripts/weapon_devastator.gd
## Devastator — full-screen explosive AoE, triggers camera shake.

const BASE_DAMAGE: float = 200.0
const BASE_FIRE_RATE: float = 6.0
const AOE_RADIUS: float = 800.0  # effectively full screen

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var _cooldown: float = 0.0

func _init() -> void:
	id = "devastator"
	display_name = "Devastator"
	tier = ModifierTier.ELITE
	slot_type = SlotType.WEAPON

func on_attach(compartment: Node, slot_index: int = 0) -> void:
	super(compartment, slot_index)
	_cooldown = 0.0

func tick(dt: float) -> void:
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	var enemies = _compartment.get_tree().get_nodes_in_group("enemies") if _compartment.get_tree() else []
	if enemies.is_empty():
		return
	# Fire at map center — full screen explosion
	projectile_spawn.emit(_compartment.global_position, Vector2.RIGHT, {
		"damage": damage,
		"range": AOE_RADIUS,
		"type": "explosive",
		"piercing": 999,
		"aoe_radius": AOE_RADIUS,
		"camera_shake": 1.0,
	})
	_cooldown = fire_rate

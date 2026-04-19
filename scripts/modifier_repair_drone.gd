extends "res://scripts/modifier_base.gd"
## res://scripts/modifier_repair_drone.gd
## Repairs HP on the compartment it's mounted on. Upgrades increase heal rate and area.

const BASE_HEAL_PER_SEC: float = 2.0

var heal_per_sec: float = BASE_HEAL_PER_SEC
var heals_adjacent: bool = false

func _init() -> void:
	id = "repair_drone"
	display_name = "Repair Drone"
	tier = ModifierTier.BASIC
	slot_type = SlotType.UTILITY
	upgrade_names = PackedStringArray(["Double Repair", "Area Repair"])
	upgrade_descs = PackedStringArray(["4 HP/s repair", "Repairs adjacent compartment"])

func get_max_level() -> int:
	return 3

func tick(dt: float) -> void:
	if not _compartment:
		return
	if _compartment.has_method("take_damage"):
		_compartment.hp = min(_compartment.hp + heal_per_sec * dt, _compartment.max_hp)
	if heals_adjacent:
		_heal_adjacent(dt)

func _heal_adjacent(dt: float) -> void:
	var train = _compartment.get_parent()
	if not train or not "compartments" in train:
		return
	var compartments = train.compartments
	var my_index := -1
	for i in compartments.size():
		if compartments[i] == _compartment:
			my_index = i
			break
	if my_index < 0:
		return
	var adjacent_indices: Array = []
	if my_index > 0:
		adjacent_indices.append(my_index - 1)
	if my_index < compartments.size() - 1:
		adjacent_indices.append(my_index + 1)
	for idx in adjacent_indices:
		var comp = compartments[idx]
		if is_instance_valid(comp) and "hp" in comp and "max_hp" in comp:
			comp.hp = min(comp.hp + heal_per_sec * 0.5 * dt, comp.max_hp)

func on_level_up(new_level: int) -> void:
	super(new_level)
	heal_per_sec = BASE_HEAL_PER_SEC
	heals_adjacent = false
	if new_level >= 2:
		heal_per_sec = 4.0
	if new_level >= 3:
		heals_adjacent = true

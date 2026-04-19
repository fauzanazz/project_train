# Iron Rail: Last Conductor

## Dimension: 2D

## Input Actions

| Action | Keys |
|--------|------|
| steer_up | W |
| steer_down | S |
| steer_left | A |
| steer_right | D |
| level_up_1 | 1 |
| level_up_2 | 2 |
| level_up_3 | 3 |
| horn | Space |
| village_panel | Escape |

Mouse position drives locomotive steering direction (mouse-toward targeting).

## Physics Layers

| Layer | Name | Used By |
|-------|------|---------|
| 1 | player | Locomotive, Compartment (collision body) |
| 2 | enemies | All zombie/boss nodes |
| 3 | projectiles | Weapon projectiles |
| 4 | village | Village walls, gate area |
| 5 | resources | ResourceNode pickup areas |
| 6 | hazards | ToxicPuddle, RubblePile, ElectrifiedRail |

## Scenes

### Main
- **File:** res://scenes/main.tscn
- **Root type:** Node2D
- **Children:** World, Train, HUD

### World
- **File:** res://scenes/world.tscn
- **Root type:** Node2D
- **Children:** Ground, Village, ResourceNodes (Node2D container), HazardNodes (Node2D container), SpawnCorridors (Node2D container), NavigationRegion2D

### Train
- **File:** res://scenes/train.tscn
- **Root type:** Node2D
- **Children:** Locomotive (instantiated), CompartmentContainer (Node2D)

### Locomotive
- **File:** res://scenes/locomotive.tscn
- **Root type:** CharacterBody2D (collision_layer=1, collision_mask=2|4|6)
- **Children:** CollisionShape2D, BodyDamageArea (Area2D, collision_layer=1, collision_mask=2), WeaponSlot (Node2D), UtilitySlot (Node2D)

### Compartment
- **File:** res://scenes/compartment.tscn
- **Root type:** Node2D
- **Children:** CollisionShape2D (as part of Area2D), BodyDamageArea (Area2D, collision_layer=1, collision_mask=2), WeaponSlot (Node2D), UtilitySlot (Node2D), CargoIndicator (Node2D)

### EnemyBase
- **File:** res://scenes/enemy_base.tscn
- **Root type:** CharacterBody2D (collision_layer=2, collision_mask=1|4)
- **Children:** CollisionShape2D, HitArea (Area2D, collision_layer=2, collision_mask=1|3), HPBar (Node2D custom draw), NavigationAgent2D

### HUD
- **File:** res://scenes/hud.tscn
- **Root type:** CanvasLayer (layer=10)
- **Children:** Control (full-rect)
  - TopLeft: VBoxContainer → VillageHPBar (ProgressBar), XPBar (ProgressBar), LevelLabel (Label)
  - TopCenter: WaveLabel (Label), WaveTimerLabel (Label)
  - BottomCenter: CargoDisplay (HBoxContainer of slot icons)
  - BottomRight: MiniMap (SubViewportContainer → SubViewport → Node2D)
  - LevelUpPanel (Control, hidden by default) — slides in from right edge

### Projectile
- **File:** res://scenes/projectile.tscn
- **Root type:** Area2D (collision_layer=3, collision_mask=2)
- **Children:** CollisionShape2D, VisualNode (Node2D)

## Scripts

### GameManager (Autoload)
- **File:** res://scripts/game_manager.gd
- **Extends:** Node
- **Signals emitted:** game_over(wave_index: int), game_started, wave_started(wave_index: int), wave_ended(wave_index: int)
- **Signals received:** (root signal hub — all managers emit through it)
- **Owns:** pause/resume, scene lifecycle, global event bus signals

### PlayerManager (Autoload)
- **File:** res://scripts/player_manager.gd
- **Extends:** Node
- **Signals emitted:** xp_changed(new_xp: int, max_xp: int), level_changed(new_level: int), level_up_offer(choices: Array)
- **Signals received:** GameManager.game_started → reset; zombie_killed (from EnemyBase) → add_xp
- **Owns:** XP ledger, player level, level-up card logic, level-up timeout timer

### WaveManager (Autoload)
- **File:** res://scripts/wave_manager.gd
- **Extends:** Node
- **Signals emitted:** wave_started(wave_index: int), wave_ended(wave_index: int), all_clear
- **Signals received:** GameManager.game_started → begin; enemy killed → check_wave_clear
- **Owns:** wave scheduling (Timer), enemy spawn dispatch, active enemy tracking

### DifficultyManager (Autoload)
- **File:** res://scripts/difficulty_manager.gd
- **Extends:** Node
- **Signals emitted:** (none)
- **Signals received:** WaveManager.wave_started → update scaling
- **Owns:** stat scaling formulas — get_enemy_hp(base, wave), get_enemy_speed(base, wave), get_elite_chance(wave)

### ResourceManager (Autoload)
- **File:** res://scripts/resource_manager.gd
- **Extends:** Node
- **Signals emitted:** resources_changed(lumber: int, metal: int, medicine: int), village_upgraded(new_tier: int)
- **Signals received:** resource_delivered → add; wave_ended → passive_generator_tick
- **Owns:** village resource ledger, village tier state, upgrade threshold logic

### Train
- **File:** res://scripts/train.gd
- **Extends:** Node2D
- **Attaches to:** Train:Train
- **Signals emitted:** train_destroyed(cargo: Array), train_respawned
- **Signals received:** (none external — manages internal compartment chain)
- **Owns:** compartment chain list, adding/removing compartments, total body damage calculation

### Locomotive
- **File:** res://scripts/locomotive.gd
- **Extends:** CharacterBody2D
- **Attaches to:** Train:Locomotive
- **Signals emitted:** (none — movement data consumed by Train)
- **Owns:** mouse-cursor steering, speed calculation, position history push, weapon slot management

### Compartment
- **File:** res://scripts/compartment.gd
- **Extends:** Node2D
- **Attaches to:** Compartment:Compartment
- **Signals emitted:** compartment_destroyed(index: int)
- **Signals received:** BodyDamageArea.area_entered → deal_body_damage
- **Owns:** lerp movement (follows position history of segment ahead), modifier slot, cargo bay, HP

### EnemyBase
- **File:** res://scripts/enemy_base.gd
- **Extends:** CharacterBody2D
- **Attaches to:** EnemyBase:EnemyBase
- **Signals emitted:** zombie_killed(xp: int, position: Vector2, resource_drop: Dictionary)
- **Signals received:** HitArea.area_entered → take_damage (from projectiles/body contact)
- **Owns:** HP, movement AI dispatch, wall damage on contact, NavigationAgent2D target update

### Village
- **File:** res://scripts/village.gd
- **Extends:** Node2D
- **Attaches to:** World:Village
- **Signals emitted:** village_damaged(amount: float, new_hp: float), village_destroyed
- **Signals received:** ResourceManager.village_upgraded → apply_tier_upgrade; enemy body_entered wall → take_damage
- **Owns:** wall HP, tier visuals, turret spawning/management

### ResourceNode
- **File:** res://scripts/resource_node.gd
- **Extends:** Area2D
- **Attaches to:** World:ResourceNodes:ResourceNode*
- **Signals emitted:** resource_collected(type: String, amount: int, node: Node)
- **Signals received:** body_entered (player) → on_train_overlap
- **Owns:** resource type, yield amount, depletion/respawn timer, visual pulse

### ModifierBase
- **File:** res://scripts/modifier_base.gd
- **Extends:** Node
- **Attaches to:** WeaponSlot or UtilitySlot (child node)
- **Signals emitted:** projectile_spawn(origin: Vector2, direction: Vector2, data: Dictionary)
- **Owns:** tick logic, onAttach/onDetach lifecycle, level-up upgrade logic

### WeaponGatling
- **File:** res://scripts/weapon_gatling.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** cooldown timer, nearest-enemy targeting, kinetic projectile spawn

### WeaponFlamethrower
- **File:** res://scripts/weapon_flamethrower.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** continuous cone AoE area, fire damage per second to overlapping enemies

### WeaponMortar
- **File:** res://scripts/weapon_mortar.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** arc projectile with AoE explosion on landing, explosive damage type

### WeaponTaser
- **File:** res://scripts/weapon_taser.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** electric projectile, 50% slow debuff on hit

### WeaponRailgun
- **File:** res://scripts/weapon_railgun.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** instant raycast piercing all enemies in line, kinetic high damage

### WeaponTesla
- **File:** res://scripts/weapon_tesla.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** primary target + chain lightning to up to 3 nearby enemies

### WeaponDevastator
- **File:** res://scripts/weapon_devastator.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** full-screen AoE explosion, camera shake trigger, explosive damage

### ModifierResourceMagnet
- **File:** res://scripts/modifier_resource_magnet.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** attract nearby resource nodes toward train per tick

### ModifierRepairDrone
- **File:** res://scripts/modifier_repair_drone.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** 2 HP/s heal on parent compartment

### ModifierShieldBubble
- **File:** res://scripts/modifier_shield_bubble.gd
- **Extends:** res://scripts/modifier_base.gd
- **Owns:** absorb-100-damage shield, 30s cooldown, visual bubble

### HUD
- **File:** res://scripts/hud.gd
- **Extends:** CanvasLayer
- **Attaches to:** Main:HUD
- **Signals received:** PlayerManager.xp_changed, PlayerManager.level_changed, PlayerManager.level_up_offer, ResourceManager.resources_changed, Village.village_damaged, WaveManager.wave_started, WaveManager.wave_ended
- **Owns:** all HUD widget updates, level-up panel slide animation, mini-map rendering, cargo slot display

### World
- **File:** res://scripts/world.gd
- **Extends:** Node2D
- **Attaches to:** Main:World
- **Owns:** map layout, navigation region setup, spawn corridor positions export, hazard placement

## Signal Map

- EnemyBase.zombie_killed → PlayerManager._on_zombie_killed
- EnemyBase.zombie_killed → ResourceManager._on_zombie_killed
- ResourceNode.resource_collected → Train._on_resource_collected
- Train.train_destroyed → ResourceManager._on_train_destroyed
- Train.train_destroyed → PlayerManager._on_train_destroyed
- Village.village_damaged → HUD._on_village_damaged
- Village.village_destroyed → GameManager._on_village_destroyed
- PlayerManager.xp_changed → HUD._on_xp_changed
- PlayerManager.level_changed → HUD._on_level_changed
- PlayerManager.level_up_offer → HUD._on_level_up_offer
- WaveManager.wave_started → HUD._on_wave_started
- WaveManager.wave_ended → HUD._on_wave_ended
- ResourceManager.resources_changed → HUD._on_resources_changed
- ResourceManager.village_upgraded → Village._on_village_upgraded
- GameManager.game_over → HUD._on_game_over

## Asset Hints

- Locomotive sprite: top-down view, ~60×30px, warm gray body with rust orange cab, chunky wheels, bold black outline
- Compartment sprite: top-down view, ~50×28px, gray cargo box with rust orange accents, wheel silhouettes
- Shambler zombie: top-down view, ~24×24px, desaturated green, wobbly proportions
- Runner zombie: top-down view, ~18×18px, purple-tinted, thin and fast-looking
- Bloater zombie: top-down view, ~32×32px, green, very fat round body
- Crawler zombie: top-down view, ~20×20px, gray-green, low flat silhouette
- Village walls: top-down stone wall segments, earthy brown/gray
- Resource node (Lumber): ~20×20px, bright green log bundle
- Resource node (Metal Scrap): ~20×20px, bright gold metal pile
- Resource node (Medicine): ~20×20px, bright blue medical cross
- Ground tileable texture: wasteland dirt, cracked earth, muted brown/tan

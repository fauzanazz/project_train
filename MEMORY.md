# Memory — Iron Rail: Last Conductor

## Scaffold (2026-04-19)

- Godot 4.6.2 stable at `/Applications/Godot.app/Contents/MacOS/Godot`
- No `timeout` command on macOS — use `gtimeout` or just `godot` directly
- RID leak warnings in headless mode are benign — ignore them
- HUD @onready paths must match build_hud.gd exactly:
  - Mini-map: `$Control/MiniMap` (NOT `$Control/BottomRight/MiniMap`)
  - Cargo display: `$Control/CargoDisplayParent/CargoDisplay`
- All visuals drawn procedurally via GDScript `draw_*` calls — no PNG assets needed
- NavigationRegion2D bake in headless build_world.gd uses NavigationServer2D.bake_from_source_geometry_data — may need actual geometry for working enemy pathfinding; consider baking at runtime in world._ready() instead
- Enemy AI uses group "enemies" — all enemy types must add_to_group("enemies") in _ready()
- Locomotive must add_to_group("locomotive") so enemies can find player position
- Village must add_to_group("village") so enemy AI can find target
- Train.try_collect_resource() method implemented in Task 2 on train.gd
- Autoload order: GameManager → PlayerManager → WaveManager → DifficultyManager → ResourceManager (all needed by enemy_base.gd at spawn)

## Task 2 — Combat, Enemies & Game Loop (2026-04-19)

- Individual `godot --headless --script X.gd` checks fail for autoload-referencing scripts (WaveManager, ResourceManager, etc.) — only `--headless --quit` gives valid full-project parsecheck
- Dynamic GDScript creation via `GDScript.new()` + `source_code` + `reload()` works for spark/explosion effects but runs in limited scope — cannot access parent HUD variables
- Scene builder pattern: build_*.gd scripts create scenes headlessly via `_initialize()` → `PackedScene.pack()` → `ResourceSaver.save()`
- Enemy types each need their own .tscn with NavigationAgent2D child; `build_enemies.gd` creates all 4 at once
- `draw_ellipse()` does not exist in Godot 4.x `CanvasItem` — use `draw_polygon()` with computed points instead
- `var dist := ...` type inference fails when right side may be null; use `var dist: float = ...` explicitly
- BodyDamageArea collision setup: layer 1 (player), mask 2 (enemies) — must match on both sides
- Projectile layer: layer 4 (bit 3 = projectiles), mask 2 (enemies) — enemies HitArea mask must include 4
- Village turret projectile spawning needs entity in scene tree — added to World node or scene root
- Level-up cards are generated via PlayerManager.CARD_POOL array; HUD dynamically creates VBoxContainers for display
- Game over display uses label overlay added to HUD Control node at runtime
- Weapon attachment: train._attach_starting_weapon() creates Weapon node, sets script, adds to Locomotive/WeaponSlot, connects `projectile_spawn` signal to train handler
- Bloater death AoE: damages train compartments and locomotive within EXPLOSION_RADIUS before queue_free()
- Wave spawning uses staggered groups with Timer-based dispatch; 10s grace period between waves

## Task 3 — Elite Content & Polish (2026-04-19)

- Added elite enemy family scenes/scripts: brute, screamer, swarmer queen, chain zombie; each keeps custom draw + base AI integration.
- Boss wave support added with `boss_locomotive` scene/script and wave-10 spawn hook in `wave_manager.gd`.
- Hazard scenes/scripts are split by type (`hazard_toxic_puddle`, `hazard_rubble_pile`, `hazard_electrified_rail`) and spawned from `world.gd`.
- Resource nodes now auto-detect outer-ring distance: >1000 units gives 3x yield and 120s respawn.
- `screen_shake.gd` autoload added for heavy-impact feedback; call through singleton instead of direct camera mutation.
- Projectile visuals and weapon effects (railgun beam, tesla arcs, devastator flash/ring) rely on short-lived draw timers rather than particle assets.
- Compatibility note: screenshot/video capture is stable when using GPU movie mode (`--write-movie`) and can crash under strict headless dummy renderer.

## Bug Fix Session (2026-04-19)

- All 9 enemy `.tscn` files were missing `[ext_resource]` script references — must add both `[ext_resource]` header AND `script = ExtResource("X")` in node properties
- `var t := max(...)` Variant inference fails silently in Godot 4.6 — `--headless --quit` only does syntax checking; use `maxf()`/`mini()` with explicit types
- `class_name` NOT registered during `--headless --quit` or when scripts loaded via `load()` at runtime if base class not preloaded. Solution: `const _Base = preload("res://scripts/enemy_base.gd")` in wave_manager.gd
- `draw_polygon()` takes at most 4 args in Godot 4.x (points, colors, uvs, texture). Use `draw_polyline()` for outlines
- Train starts with 0 compartments — auto-spawn 1 in `_ready()` + locomotive fallback cargo storage
- `_spawning` flag in wave_manager must be reset to false at spawn completion

## Task 5 — A/D Drift & Dual Targeting (2026-04-19)

- Movement changed from mouse-steering to A/D key drift: always moves forward, A/D rotates
- `modifier_base.gd` has `class_name ModifierBase` with `TargetingMode` enum and static targeting state vars
- Shared `_find_target(search_range)` in modifier_base.gd used by all weapons — respects active targeting mode
- TAB toggles between PLAYER_CENTER and MOUSE_POINTER targeting modes
- Targeting line drawn in locomotive `_draw()` using `ModifierBase.targeting_origin`/`targeting_position`
- HUD shows "Target: Player" / "Target: Mouse" indicator

## Task 6 — Card Upgrade System (2026-04-19)

- `modifier_base.gd` now has `upgrade_level: int`, `upgrade_names`/`upgrade_descs: PackedStringArray`, `get_max_level()`, `get_next_upgrade_name()`/`get_next_upgrade_desc()`
- `on_level_up(new_level)` param changed from `upgrade_count` to `new_level` — weapons apply cumulative upgrades idempotently
- `player_manager.gd` has typed registries (WEAPON_DEFS, UTILITY_DEFS, PASSIVE_DEFS) instead of flat CARD_POOL
- Card generation scans train for equipped modifiers, builds upgrade cards with specific names/descriptions
- Each weapon has 5 levels with named upgrades; utilities have 3 levels
- Weapons use flags (e.g. `dual_barrel`, `barrage`, `overcharge`) for upgrade effects
- `apply_choice()` dispatches by card type: weapon_upgrade, weapon_new, utility_upgrade, utility_new, passive
- HUD shows colored icon bars, level arrows (Lv2→3), gold upgrade name, gray description

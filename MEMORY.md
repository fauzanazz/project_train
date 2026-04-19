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
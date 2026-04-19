# Memory — Iron Rail: Last Conductor

## Scaffold (2026-04-19)

- Godot 4.6.2 stable at `/Applications/Godot.app/Contents/MacOS/Godot`
- No `timeout` command on macOS — use `gtimeout` or just `godot` directly
- RID leak warnings in headless mode are benign — ignore them
- HUD @onready paths must match build_hud.gd exactly:
  - Mini-map: `$Control/MiniMap` (NOT `$Control/BottomRight/MiniMap`)
  - Cargo display: `$Control/CargoDisplayParent/CargoDisplay`
- All visuals in Task 1 are drawn procedurally via GDScript `draw_*` calls — no PNG assets needed
- NavigationRegion2D bake in headless build_world.gd uses NavigationServer2D.bake_from_source_geometry_data — may need actual geometry in Task 2 for working enemy pathfinding; consider baking at runtime in world._ready() instead
- Enemy AI uses group "enemies" — all enemy types must add_to_group("enemies") in _ready()
- Locomotive must add_to_group("locomotive") so enemies can find player position
- Village must add_to_group("village") so enemy AI can find target
- Train.try_collect_resource() method expected by resource_node.gd — must be implemented in Task 2 on train.gd
- Autoload order: GameManager → PlayerManager → WaveManager → DifficultyManager → ResourceManager (all needed by enemy_base.gd at spawn)

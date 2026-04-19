# Game Plan: Iron Rail: Last Conductor

## Game Description

You are a **container conductor** — the driver of an armored freight train in a post-apocalyptic wasteland. A village sits at the center of the map, walled and starving. Zombie hordes close in from all directions. You ram them with your train body, haul resources back to the village, and upgrade both yourself and the village to survive escalating waves.

**Genre:** 2D Top-Down Tower Defense | **Art Style:** Cartoonist (bold outlines, flat shading, exaggerated proportions) | **Platform:** PC

**Core loop:** Zombies spawn → Player rams/shoots zombies for XP → Player hauls resources to village for upgrades → survive wave → repeat.

**Train movement:** slither.io model — locomotive steers toward mouse cursor, compartments lerp through position history with fixed delay. Body contact damages zombies.

**Dual economy:** XP (zombie kills) → player level-up → modifier/weapon choices. Resources (haul to village) → village tier upgrades → better walls and turrets.

---

## 1. Train Foundation & World

- **Depends on:** (none)
- **Status:** in_progress
- **Targets:** project.godot, scenes/main.tscn, scenes/world.tscn, scenes/train.tscn, scenes/locomotive.tscn, scenes/compartment.tscn, scenes/hud.tscn, scripts/game_manager.gd, scripts/train.gd, scripts/locomotive.gd, scripts/compartment.gd, scripts/world.gd, scripts/village.gd, scripts/resource_node.gd, scripts/hud.gd, scenes/build_*.gd
- **Goal:** Establish the playable foundation — a steerable cartoonist train with compartment chain physics navigating an open wasteland map with a walled village at center and pulsing resource nodes. No enemies yet; focus on feel, visuals, and the slither.io movement model.
- **Requirements:**
  - Locomotive steers toward mouse cursor at 200 units/s base speed. Turning radius is inversely proportional to speed.
  - Compartment chain: each compartment follows a position history of the segment ahead of it, lerping to the stored position from N frames ago (creating the slither.io wave effect). Start with 2 compartments attached.
  - Body damage aura: compartments have Area2D collision — contact with enemy (layer 2) deals `bodyDamage × (currentSpeed / baseSpeed)` per second. No enemies yet, but collision mask must be in place.
  - Map is 3200×3200 open wasteland. Village occupies center 300×300, surrounded by stone walls. 12 resource nodes scattered in the mid and outer rings. 4 spawn corridors at map edges.
  - Resource nodes: three types (Lumber=green, Metal Scrap=gold, Medicine=blue). Pulse gently when active, gray/inert when depleted. Drive-over collection: nearest empty cargo compartment fills.
  - Village: stone wall visual with HP indicator above it. Gate area on south side where train docks to deliver cargo.
  - Camera: top-down, follows locomotive. Slight zoom-out at higher speeds (80%–120% zoom range).
  - HUD: village HP bar (top-left), XP bar + level (top-left below HP bar), wave counter + wave timer (top-center), cargo slots display (bottom-center), mini-map (bottom-right, 180×180, shows village, train, resource nodes).
  - All sprites drawn procedurally with GDScript using `draw_*` calls (no external PNG assets needed for task 1) — the cartoonist look via filled polygons, thick outlines, bold flat color shapes.
- **Assets needed:** None — all visuals drawn procedurally via GDScript draw calls in this task.
- **Verify:** Screenshots show the cartoon train (locomotive + 2 compartments) navigating the wasteland map toward the mouse. Compartments visibly wave/snake behind the locomotive like slither.io. Village is visible at map center with walls. Resource nodes glow in their colors. HUD overlays correctly placed. Camera follows the locomotive and zooms out when moving fast.

---

## 2. Combat, Enemies & Game Loop

- **Depends on:** 1
- **Status:** pending
- **Targets:** scenes/enemy_base.tscn, scenes/enemy_shambler.tscn, scenes/enemy_runner.tscn, scenes/enemy_bloater.tscn, scenes/enemy_crawler.tscn, scenes/projectile.tscn, scenes/weapon_gatling.tscn, scenes/weapon_flamethrower.tscn, scripts/game_manager.gd, scripts/enemy_base.gd, scripts/enemy_shambler.gd, scripts/enemy_runner.gd, scripts/enemy_bloater.gd, scripts/enemy_crawler.gd, scripts/wave_manager.gd, scripts/difficulty_manager.gd, scripts/player_manager.gd, scripts/resource_manager.gd, scripts/modifier_base.gd, scripts/weapon_gatling.gd, scripts/weapon_flamethrower.gd, scripts/level_up_ui.gd, scripts/village.gd
- **Goal:** Full core game loop — all 4 basic zombie types with AI, wave spawning with escalating difficulty, dual economy running end-to-end, body contact combat, two starter weapons with auto-aim, level-up card system, and village tier 1–2 upgrades with turrets. Win/lose conditions active.
- **Requirements:**
  - 4 basic enemies: Shambler (30 HP, 60 spd, PATH_TO_VILLAGE), Runner (15 HP, 140 spd, PATH_TO_PLAYER), Bloater (80 HP, 40 spd, PATH_TO_VILLAGE — explodes on death), Crawler (20 HP, 90 spd, HYBRID). Each drawn as bold cartoonist sprite via draw calls.
  - Enemy AI: PATH_TO_VILLAGE → NavigationAgent2D beelines to village. PATH_TO_PLAYER → chases train position. HYBRID → targets train if within 400 px, else village. All enemies deal wall damage on contact.
  - Body contact combat: train compartments deal `bodyDamage × (speed/baseSpeed)` per second to overlapping enemies. Visual feedback: sparks + squash on zombie, screen shake on heavy impact.
  - Two weapons on Locomotive weapon slot (player starts with Gatling Mk1): Gatling Gun (8 dmg, 0.12s cooldown, kinetic, auto-aims nearest enemy within 300px), Flamethrower (5/s dmg, continuous cone, fire, short range 150px).
  - Wave system: WaveManager spawns waves from 4 map-edge corridors. Wave 1–5: slow, low count, no elites. Between waves: 10s grace period. Timer displayed in HUD. Difficulty scales per formula: `enemyHP = baseHP × (1 + 0.15 × waveIndex)`.
  - XP economy: killing zombie grants XP (Shambler=10, Runner=15, Bloater=20, Crawler=12). XP bar fills. Level-up threshold: `100 × N^1.4`.
  - Level-up UI: slides in from screen edge without pausing. 3 cards shown (random weighted). Cards: modifier name + key stat. Keyboard 1/2/3 to pick. 15s auto-select timeout. Available choices: Gatling→Flamethrower swap, Turbo Engine (+15% speed), Heavy Frame (+20% body damage), Armor Plating (25% dmg reduction), Cargo Expansion (+1 cargo per compartment).
  - Resource delivery: drive train to village gate area → all cargo unloads → animated resource count-up ticks in HUD → ResourceManager ledger updates.
  - Village upgrade tiers: Tier 0 (start: stone walls, 500 HP). Tier 1 (50 Lumber: +25% HP, arrow turret spawns on wall). Tier 2 (50 Metal + 30 Lumber: +50% HP, cannon turret). Turrets auto-aim closest enemy in range and fire independently.
  - Game over: village HP → 0 shows game over screen with wave reached and score. Train destruction: 3s auto-respawn at village gate, cargo lost, XP kept.
  - Village wall HP bar updates in HUD in real time. Red pulse flash when wall is hit.
- **Assets needed:** None — all enemy and weapon visuals drawn procedurally.
- **Verify:** Screenshots show: (1) a wave of cartoon zombies approaching from map edge — Shamblers shuffling, Runners dashing; (2) train ramming zombies with spark effect, XP bar filling; (3) level-up card panel sliding in with 3 choices visible; (4) cargo delivery animation at village gate; (5) arrow turret on village wall firing at nearest zombie.

---

## 3. Full Content, Elite Enemies & Polish

- **Depends on:** 2
- **Status:** pending
- **Targets:** scenes/enemy_brute.tscn, scenes/enemy_screamer.tscn, scenes/enemy_swarmer_queen.tscn, scenes/enemy_chain.tscn, scenes/boss_locomotive.tscn, scenes/hazard.tscn, scripts/enemy_brute.gd, scripts/enemy_screamer.gd, scripts/enemy_swarmer_queen.gd, scripts/enemy_chain.gd, scripts/boss_locomotive.gd, scripts/weapon_mortar.gd, scripts/weapon_taser.gd, scripts/weapon_railgun.gd, scripts/weapon_tesla.gd, scripts/weapon_devastator.gd, scripts/modifier_resource_magnet.gd, scripts/modifier_repair_drone.gd, scripts/modifier_shield_bubble.gd, scripts/village.gd, scripts/world.gd, scripts/hud.gd
- **Goal:** Complete the content — 4 elite enemy types, first boss (Wave 10), all remaining weapons (mortar, taser, railgun, tesla, devastator), utility modifiers, village tiers 3–4 (electric fence, missile battery, generator), hazards, resource node respawn timers, and full game-feel polish (squash-and-stretch, muzzle flashes, screen shake, particle effects for all weapon types).
- **Requirements:**
  - 4 elite enemies: Armored Brute (300 HP, kinetic-resistant), Screamer (60 HP, buffs nearby zombies), Swarmer Queen (150 HP, spawns Crawlers every 5s), Chain Zombie (200 HP, electric-resistant). Elites appear starting wave 6, increasing chance per wave (capped at 40%).
  - Boss: The Locomotive (wave 10, 2000 HP) — a zombie-infested enemy train that tracks and rams the player. Distinctive visual — dark, rusted, larger than player train.
  - Weapons: Mortar Mk1 (35 dmg, 2s, explosive, lobs arc), Taser Mk1 (12 dmg, 0.8s, slows 50%), Railgun Mk1 (80 dmg, 3.5s, pierces all targets in line), Tesla Coil (30 dmg, 1.2s, chains to 3 enemies), Devastator (200 dmg, 6s, full-screen AoE, camera shake). All available through level-up cards at appropriate player level thresholds.
  - Utility modifiers: Resource Magnet (attracts nodes to train), Repair Drone (2 HP/s on compartment), Shield Bubble (absorbs 100 dmg, 30s cooldown).
  - Village tiers 3–4: Tier 3 (100 Metal + 50 Lumber: electric fence aura, generator unlocks passive resource trickle between waves). Tier 4 (150 Metal + 100 Lumber + 50 Medicine: fortress walls immune to basic zombies, missile battery targets elites first).
  - Hazards on map: Toxic Puddle (5 HP/s + 20% slow on contact), Rubble Pile (blocks path, rammed to clear), Electrified Rail (30 dmg to first compartment crossing).
  - Resource nodes: respawn timer system — base 60s, outer ring 120s. Visual pulse animation when ready, gray/shrunk when depleted.
  - Compartment can be destroyed by elite zombie (permanent run loss of that segment — reduces chain length and body damage).
  - Full game-feel: all weapon types have distinct muzzle flash (one-frame pop, large and punchy). Zombie deaths use exaggerated squash-and-stretch ragdoll. Screen shake on body ram and devastator fire. Village upgrade triggers brief construction flash animation.
  - Endless mode: after wave 20, scaling continues indefinitely with score tracking.
- **Assets needed:** None — all elite/boss/hazard visuals drawn procedurally.
- **Verify:** Screenshots show: (1) Armored Brute with visible armor effect approaching village; (2) The Locomotive boss on screen — large, menacing, different from player train; (3) Tesla Coil chain lightning connecting 3 zombies; (4) Village at Tier 3 with electric fence aura glowing around walls; (5) Toxic puddle hazard on map with train avoiding it; (6) Devastator explosion covering large screen area.

---

## 4. Presentation Video

- **Depends on:** 3
- **Status:** pending
- **Targets:** test/presentation.gd, screenshots/presentation/gameplay.mp4
- **Goal:** Create a ~30-second cinematic video showcasing the completed game.
- **Requirements:**
  - Write test/presentation.gd — a SceneTree script (extends SceneTree)
  - Showcase representative gameplay via simulated input or scripted animations
  - ~900 frames at 30 FPS (30 seconds)
  - Use Video Capture from godot-capture (AVI via --write-movie, convert to MP4 with ffmpeg)
  - Output: screenshots/presentation/gameplay.mp4
  - **2D games:** camera pans and smooth scrolling, zoom transitions between overview and close-up, trigger representative gameplay sequences, tight viewport framing
  - Show: train snaking through zombie horde → resource pickup → village delivery → level-up card selection → village wall upgrade → boss encounter
- **Verify:** A smooth MP4 video showing polished gameplay with no visual glitches.

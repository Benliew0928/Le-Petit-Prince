# 🪐 Le Petit Prince — Mini 3D Game
## Project Context File (paste this at the start of every AI session)

> **How to use:** Copy the entire contents of this file and paste it at the beginning of any new AI chat session. Update the "Current Status" and "Progress Tracker" sections after every work session.

---

## Project Overview

| Field | Detail |
|---|---|
| **Game title** | Le Petit Prince: The Little Planet |
| **Genre** | 3D adventure / exploration |
| **Inspiration** | *Le Petit Prince* novel by Antoine de Saint-Exupéry |
| **Art style** | Cel-shaded, toon-outlined, low-poly — inspired by Zelda: Wind Waker / Breath of the Wild |
| **Scope** | Mini game, solo vibe-coded project |
| **Target platform** | Web (HTML5 export via Godot), optionally Windows |
| **Target playtime** | 30–60 minutes |

---

## Tech Stack

| Layer | Tool | Notes |
|---|---|---|
| **Engine** | Godot 4.6 | GDScript, built-in Forward+ rendering, Autoloads |
| **3D Modeling** | Blender | Low-poly characters, planets, props |
| **Textures / UI** | Krita / Aseprite | Flat-color hand-painted textures / Emoji HUD icons |
| **Shaders** | Godot ShaderLab (GLSL) | Toon ramp shader + outline pass shader |
| **Version control** | Git + GitHub | Godot .gitignore applied |

---

## Folder Structure

Below is the current, actual directory structure of the project:

```
le-petit-prince-game/
├── GAME_CONTEXT.md                  ← this file, always at root
├── project.godot                    ← project config (Autoloads, main scene)
├── default_env.tres
├── shaders/
│   ├── toon_ramp.gdshader            ← main cel shader
│   └── outline_pass.gdshader         ← post-process outline
├── scenes/
│   ├── test_world.tscn              ← UNIFIED WORLD (contains B-612, Desert, King)
│   ├── player.tscn                  ← Player scene with camera rig
│   ├── airplane.tscn                ← Boardable airplane
│   ├── rose.tscn                    ← Interactive rose with swaying anims
│   ├── baobab_sprout.tscn           ← Baobab tree sprout
│   ├── crop.tscn                    ← Growing crop (wheat)
│   ├── garden_plot.tscn             ← Interactive farming plot
│   ├── seed_item.tscn               ← Wheat seed pickup
│   ├── wheat_item.tscn              ← Harvested wheat pickup
│   ├── shovel.tscn                  ← Shovel tool pickup
│   ├── watering_can.tscn            ← Watering can tool pickup
│   ├── house_exterior.tscn          ← B-612 house exterior
│   ├── house_interior.tscn          ← B-612 house interior
│   ├── planet_b612.tscn             ← B-612 planet scene
│   ├── planet_desert.tscn           ← Sandy Desert planet scene
│   ├── planet_king.tscn             ← Royal King's planet scene
│   └── desert_rock.tscn             ← Decorative desert rock prop
├── scripts/
│   ├── player/
│   │   ├── player_controller.gd      ← Spherical gravity + multi-planet check + movement
│   │   └── camera_orbit.gd           ← Sphere-safe orbit / FP camera + flight chase cam
│   ├── systems/
│   │   ├── dialogue_system.gd        ← DialogueManager autoload (show_dialogue)
│   │   ├── held_item.gd              ← HeldItem autoload (one-item-at-a-time logic)
│   │   ├── hunger.gd                 ← Hunger autoload (5-min cycle, starvation debuffs)
│   │   ├── inventory.gd              ← Item/tool tracking
│   │   └── planet_gravity.gd         ← PlanetGravity helper class
│   ├── npcs/
│   │   ├── rose.gd                   ← Rose behavior + unprompted dialogue intervals
│   │   ├── rose_dialogue.gd          ← Proud/moody dialogue lines
│   │   ├── fox.gd                    ← Fox taming AI, flee/approach, patience
│   │   ├── fox_dialogue.gd           ← Taming stage dialogues
│   │   ├── king.gd                   ← King puzzle controller (3 commands)
│   │   └── king_dialogue.gd          ← Royal commands & dialogues
│   └── objects/
│       ├── airplane.gd               ← W/S throttle, A/D turn (banking), mouse fly control
│       ├── baobab.gd                 ← Baobab interactive trimming (requires shovel + E presses)
│       ├── baobab_spawner.gd         ← Spawns baobabs periodically
│       ├── crop.gd                   ← Crop growth stages and harvesting
│       ├── garden_plot.gd            ← Tilling/watering/planting actions
│       ├── gate.gd                   ← Gate (remnant / unused)
│       ├── house_exterior.gd         ← House teleport trigger (B-612)
│       ├── house_interior.gd         ← House interior exit trigger
│       ├── seed_shelf.gd             ← Infinite seed grab spot
│       ├── tool_pickup.gd            ← General pickup script for shovel/watering can
│       ├── watering_can.gd           ← Watering can functionality
│       ├── star_pickup.gd            ← Fallen star pickup (held item)
│       └── sunset_zone.gd            ← Sun dimming + timer area for King's puzzle
└── ui/
    ├── dialogue_box.gd               ← Renders narrative/dialogue text
    ├── dialogue_box.tscn             ← Dialogue box overlay scene
    └── hud.tscn                      ← HUD (hunger bar, planet name, narative, emoji items, FP crosshair)
```

---

## Core Systems (How They Work)

### 🪐 Unified World & Multi-Planet Gravity
Rather than separate levels with loading screens, the game uses a single, seamless world (`test_world.tscn`):
* **B-612 Planet**: At origin `(0, 0, 0)` with radius `15`
* **Desert Planet**: Spaced away at `(80, 30, -60)` with radius `12`
* **King's Planet**: Spaced away at `(-70, -40, 50)` with radius `6`

Each planet is registered in the `"planet"` group. The player’s movement script (`player_controller.gd`) constantly evaluates distance to all planets, setting gravity dynamically toward the center of the nearest one.
```gdscript
# From planet_gravity.gd
static func orient_to_surface(node: Node3D, center: Vector3 = Vector3.ZERO) -> void:
    var up = (node.global_position - center).normalized()
    var forward = -node.global_transform.basis.z
    if abs(forward.dot(up)) > 0.99:
        forward = node.global_transform.basis.y
    var right = up.cross(forward).normalized()
    forward = right.cross(up).normalized()
    node.global_transform.basis = Basis(right, up, -forward)
```

### ✈️ Airplane Flight Controls
Seamless interstellar flight is implemented via a Golden Biplane (`airplane.tscn`):
* **Boarding**: Approaching the plane and pressing `E` boards it.
* **Control Scheme**: 
  - `W`: Accelerate / Increase throttle
  - `S`: Decelerate / Decrease throttle
  - `A` / `D`: Yaw left/right (animates visual banking/roll)
  - **Mouse Movement**: Directs pitch and yaw, controlling the direction and flight angle.
* **Landing**: Landing is automated. Flying close to any planet surface auto-lands the plane safely, enabling the player to press `E` to unboard.

### 🎥 Multi-Mode Camera Rig
The camera orbit rig (`camera_orbit.gd`) supports three distinct modes:
1. **Third-Person View (Orbit)**: Standard camera orbiting behind the player capsule.
2. **First-Person View**: Persistent look-direction vector projected onto the current planet's tangent plane. Toggled dynamically with `V` (shows crosshair HUD overlay). This avoids camera flipping or weird spinning at the spherical planet poles.
3. **Airplane Flight Cam**: Rigidly locked behind the plane, dampening sudden motions to avoid dizziness.

### 💬 Dialogue Manager Autoload
An autoloaded singleton (`DialogueManager`) queues and displays dialogue scripts.
* Triggering Dialogue:
```gdscript
DialogueManager.show_dialogue([
    {"speaker": "The King", "text": "Approach, so that I may look upon you!"},
    {"speaker": "Prince", "text": "It is a bit small here, Majesty."}
])
```
* Integrates seamlessly with all NPC interactions (Rose, Fox, King). Prevents overlap using the `DialogueManager.is_active` check.

### 🎒 Single Held Item Singleton (`HeldItem`)
The player can only carry **one item at a time**, visible in their hand and displayed as a clear Emoji HUD icon:
* `HeldItem.hold(item_id)`: Equips an item (e.g. `"watering_can"`, `"shovel"`, `"wheat"`, `"star"`).
* `HeldItem.consume()`: Drops or uses up the item.
* `HeldItem.is_holding(item_id)` / `HeldItem.is_empty()` checking.

### 🌾 Farming, Baobabs, & Hunger System
* **Hunger**: The player has a 5-minute hunger cycle. Hunger is visible on the HUD. If starving, player movement speed is penalized.
* **Farming**: Grab wheat seeds from the shelf → plant on tilled soil → water with watering can → wait for crop growth stages → harvest wheat → eat wheat to replenish hunger.
* **Baobab Trees**: Periodic spawn. If left unchecked, they grow. Player must equip the Shovel and press `E` up to 15 times to trim/pull them before they choke the planet.

---

## Game Progression & Planets

### Completed Planets & Mechanics

| Planet | NPC | Core Mechanics | Status |
|---|---|---|---|
| **B-612 (Home)** | Rose | Rose mood cycle (based on watering), ambient swaying, unprompted dialogue intervals (25–50s). Periodic baobab spawning (must trim with shovel, multiple E taps). Wheat farming loop to cure hunger. | ✅ **Completed** |
| **Desert** | Fox | Fox bonding system with 5 states (`STRANGER`, `CURIOUS`, `FAMILIAR`, `FRIEND`, `TAMED`). Fox flees or approaches depending on movement speed, distance, and player patience (sitting still). Fully tamed fox follows the player. | ✅ **Completed** |
| **King's Planet** | King | Progression-based authority puzzle. The player must obey three "logical orders" in order: <br>1. **Sitting Order**: Sit on the royal throne (auto-detected via physics area with a 2s sitting timer). <br>2. **Bring Star Order**: Retrieve the fallen star using `HeldItem` (`HeldItem.hold("star")`). <br>3. **Sunset Order**: Stand in the designated sunset zone (Area3D dims the main sun, holds a 15s countdown timer). | ✅ **Completed** |
| **Lamplighter's Planet** | Lamplighter | Rhythm-based light challenge: assist the exhausted Lamplighter by lighting/extinguishing his streetlamp exactly at sunset and sunrise (within a 1-second window) for 4 consecutive day/night cycles (one cycle every 8s). | ✅ **Completed** |
| **Geographer's Planet** | Geographer | Collect factual statistics from other planets. | ⬜ **Planned / Not Started** |

---

## Progress Tracker
> ✅ Done · 🔄 In progress · ⬜ Not started · ❌ Blocked

### Phase 1 — Foundation (Completed)
- [x] Godot 4 project created
- [x] Toon ramp shader written and applied
- [x] Outline pass shader implemented
- [x] Spherical planet scene setup with gravity body
- [x] Player capsule with spherical gravity physics
- [x] Multi-mode camera orbit rig supporting First/Third person (V key)
- [x] Seamless spherical movement (upright orientation)

### Phase 2 — Core Loop (Completed)
- [x] B-612 home planet fully dressed (Rose, baobab spawner, house interior/exterior teleportation)
- [x] Rose interaction + mood system + unprompted dialogue intervals + watering loop
- [x] Shovel tool + multi-press Baobab sprout weeding mechanic (up to 15 presses)
- [x] DialogueBox UI overlay and DialogueManager Autoload logic
- [x] Multi-stage wheat farming cycle (tilth, water, grow, harvest, eat)
- [x] Hunger management system (5-minute loop, speed debuff when starving)
- [x] HeldItem singleton (forces single-held-item constraint, shows visual item model / emoji HUD indicator)

### Phase 3 — Interstellar Travel & Planets (In Progress)
- [x] Unified World configuration (`test_world.tscn`) containing B-612, Desert, and King's Planet
- [x] Seamless flight mechanics with the golden airplane (W/S speed, A/D banking, mouse look direction, auto-landing)
- [x] First-person camera stabilization over spherical poles (persistent vector projection)
- [x] Fox NPC on Desert Planet with 5-stage bonding AI (Stranger -> Tamed)
- [x] King NPC on King's Planet with progress-based puzzle validation (Sitting, Star gathering, Sunset timing)
- [x] Narration system & planet-entry notifications in the HUD
- [x] Lamplighter's Planet + rhythm puzzle
- [ ] Geographer's Planet + data-gathering puzzle

### Phase 4 — Polish (Planned)
- [ ] Particle systems (stars, rose petals, flight dust)
- [ ] BGM and SFX integration
- [ ] Save/load system (`user://save.json`)
- [ ] Main menu + Title screen
- [ ] Screen shake + UI popup juice

### Phase 5 — Ship (Planned)
- [ ] Full playthrough bug bash
- [ ] HTML5 export configuration
- [ ] itch.io upload

---

## Current Status
> **Update this section at the end of every work session.**

**Last updated:** 2026-05-27
**Current phase:** Phase 3 — Interstellar Travel & Planets
**What was just completed:** 
* Shifted B-612 from a tiny object-cluster planet into a larger, deliberately composed home-island vertical slice.
* Tuned the third-person controller for snappier, more grounded feel with acceleration/deceleration, coyote time, jump buffering, stronger gravity, and grounded snap.
* Upgraded the camera with closer Zelda-like framing, soft auto-follow behind movement, manual orbit grace, and collision avoidance.
* Reworked global lighting toward warm stylized daylight with softer ambient fill, subtle bloom, and painterly atmospheric fog.
* Enlarged and recomposed B-612 landmarks so the house, rose courtyard, garden, volcanoes, and baobab threat read as intentional level composition.
* Preserved the Little Prince identity through the prince model, rose dome, volcano trio, cozy house, and baobab storytelling.

**Currently working on:** B-612 vertical-slice polish: authored level composition, controller feel, camera, and stylized lighting.
**Blockers / open questions:** None.

---

## Technical & Design Decisions Log

| Date | Decision | Reason / Detail |
|---|---|---|
| — | **Engine: Godot 4.6** | Free, lightweight, and supports excellent cel/toon shading pipelines. |
| — | **Art Style: Low-Poly Cel-Shaded** | Matches the soft storybook watercolor aesthetic of Saint-Exupéry's novel. |
| — | **Seamless Multi-Planet Space** | User explicitly rejected separate scene loading. All planets are visible and reachable in a single world scene (`test_world.tscn`) via aircraft flight. |
| 2026-05-26 | **FP Camera Persistent Vector** | Standard basis look vectors break at spherical poles. We use a persistent 3D vector projected on each frame to the tangent plane. |
| 2026-05-26 | **Obey Progression-Based King Gates** | Switched from physical gate doors (which players could easily walk around on a spherical surface) to a sequence of story-based visibility triggers. |
| 2026-05-26 | **Sitting Auto-Detection** | Removed E-press sitting checks (since E also causes the player to stand/interact). Instead, sitting is auto-detected via a continuous `_physics_process` timer when in range. |
| 2026-05-26 | **Single Held Item Constraint** | Ensured the player cannot carry multiple objects. `HeldItem.hold(item_id)` handles drop/equip cleanly, and HUD features matching emojis. |

---

*Le Petit Prince © Antoine de Saint-Exupéry. This is a fan game / learning project.*

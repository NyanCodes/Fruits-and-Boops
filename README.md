# Fruits and Boops

A 2D platformer built with **Godot 4.7** (GL Compatibility renderer).

## Getting started

1. Install [Godot 4.7](https://godotengine.org/download) or newer.
2. Clone the repo:
   ```bash
   git clone https://github.com/NyanCodes/Fruits-and-Boops.git
   ```
3. In the Godot Project Manager, click **Import**, select `project.godot`, and open it.

On first open Godot regenerates the `.godot/` folder (import cache). That folder is
git-ignored on purpose — never commit it.

## What's in so far

- **Player movement** — walk, jump, gravity, and platform collision
  (`Scripts/player.gd`). Falling into a pit respawns you at the start.
- **Stage 1: Basic Platforming** — `Scenes/Stage1.tscn`.
- **Stage 2: Unexpected Obstacles** — `Scenes/Stage2.tscn`, three floors joined by ladders.
- **Stage 3: Final Challenge** — `Scenes/Stage3.tscn`. Combines every mechanic:
  a troll block over the first pit, a bridge of crumbling and invisible-but-solid
  platforms, a secret fruit cave under a hole that looks like a death pit, a
  three-floor ladder tower, a crumbling descent, and a fake floor before the goal.
- **Cat Mario traps** — Stage 2 introduces blocks that escape or reveal spikes,
  a falling wheel, a saw that drops and rolls toward the player, an enemy-spawning
  pipe, and a harmless decoy goal. The other cave saws stay stationary. Stage 3
  also has a harmless decoy goal near the finish. Active traps reset after death.
- Fruit to collect, enemies to stomp, traps, checkpoints and a goal in every stage.

Power-ups are not built yet.

Remaining Cat Mario-style follow-ups are poison or fake power-ups, deadly
background scenery, approach-triggered enemy spawns, and switch-controlled or
moving platforms.

## Quick level testing

The game opens on the main menu (`Scenes/MainMenu.tscn`). **Start Game** leads
to a stage select with all three stages. To jump straight into one level instead,
open `Scenes/Stage1.tscn`, `Scenes/Stage2.tscn` or `Scenes/Stage3.tscn` and choose
**Run Current Scene** (`Cmd + R` on macOS, `F6` on Windows/Linux).

Stage 1 is 4,480 pixels wide and ends at its own finish flag. Stage 2 is
4,544 pixels wide and contains only the later section, starting at x=0.
Stage 3 is 4,608 pixels wide with four checkpoints. All stages have unlimited
respawns. Edit each level in its own scene.

## Controls

| Action | Keys                    |
| ------ | ----------------------- |
| Move   | `A` / `D` or `←` / `→`  |
| Jump   | `Space`, `W`, or `↑`    |
| Climb  | `W` / `S` or `↑` / `↓` on a ladder; `Space` jumps off |

## Layout

| Path                                | Contents                                     |
| ----------------------------------- | -------------------------------------------- |
| `Scenes/MainMenu.tscn`              | Title screen and stage select — the main scene |
| `Scenes/Stage1.tscn`                | Stage 1                                      |
| `Scenes/Stage2.tscn`                | Stage 2                                      |
| `Scenes/Stage3.tscn`                | Stage 3                                      |
| `Scenes/Player.tscn`                | The player; its origin sits at its feet        |
| `Scenes/Game.tscn`                  | Older sandbox scene, kept for reference       |
| `Scenes/hidden_block.tscn`          | Surprise block, not placed in a stage yet     |
| `Scenes/Props/Ladder.tscn`          | Climbable ladder; set `height` in 16 px steps |
| `Assets/Tilemap/world_tileset.tres` | Shared `TileSet` — 18x18 tiles, used by every stage |
| `Scripts/`                          | GDScript files                                |
| `Assets/`                           | Sprites and tilemaps                          |

## Level editing

Stage 1 is two `TileMapLayer` nodes: `Terrain` (solid) and `Decor` (plants, no
collision). Both share `world_tileset.tres`, so paint them with the TileMap
editor as usual. The jump tuning in `Scripts/player.gd` clears roughly a 110 px
gap and a 63 px rise — keep new gaps under that or the stage becomes impossible.

## Working together

- The `*.import` and `*.uid` files next to assets **are** tracked. They keep resource
  IDs identical across machines, so commit them along with the asset itself.
- `.tscn` files are text but merge badly. Avoid editing the same scene at the same
  time — split work by scene, or use short-lived branches and pull before you start.
- Use branches and pull requests rather than pushing straight to `main`.

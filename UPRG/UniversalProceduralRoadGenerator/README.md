# UPRG — Universal Procedural Road Generator

**Status:** version 0.1.0 (tag `uprg-v0.1.0`)
**Target engine:** Godot 4.7.2 (GDScript)

A private development tool: it takes a terrain baked by UPTG and writes a new world file with terrain changes, roads, rings and junctions, places with streets and buildings, 3D models and custom textures, optionally cut into tiles. A game opens the result without any UPTG or UPRG code.

## Folders

| Folder | Content |
|---|---|
| `addons/uprg/` | The generator: `core/`, `builders/`, `assets/` |
| `tools/` | `uprg_bake.gd`, the command-line entry point; `uprg_library.gd`, builds the model library |
| `presets/` | Road descriptions saved as `.tres` |
| `demo/` | `uprg_viewer.tscn`, shows any baked world file |
| `tests/` | Headless test suite |
| `documentation/` | Architecture and testing |

## Usage

Open a command prompt in this folder (the first command is needed once, after a fresh clone or a new script):

```
godot --headless --editor --quit
godot --headless --path . -s res://tools/uprg_bake.gd -- --in=C:/Temp/island.scn --world=res://presets/example_world_island.tres --out=C:/Temp/world.scn
godot --path . res://demo/uprg_viewer.tscn -- --file=C:/Temp/world.scn
```

The world description is one `.tres` file: open `presets/example_world_island.tres` in the Godot editor, or duplicate it for a new world.

| Section | What you set |
|---|---|
| `terrain_edits` | Circular areas to raise, lower (`ADD`) or level (`LEVEL`) |
| `places` | Name, center, radius, number and size of buildings, wall and roof colors, seed; `streets` adds streets joined to the nearest road, with the buildings along them |
| `roads` | Points in meters from the terrain center, width, slope; `closed` makes a ring |
| `skin` | Images for roads, terrain and buildings, and color tints |
| `dressing` | How many trees, plants, rocks and roadside objects, and how far they stay visible |

A road alone also works: `--road=<road.tres>`, repeatable.

## Junctions

Roads that cross, or a road that ends on another, become a junction by themselves: they meet at one height, with one surface and rounded corners. Roads listed first keep their height and the others adapt to them. All crossings are at ground level, and two roads must meet at 25 degrees or more.

## 3D models

A world with `dressing` takes its buildings, trees, rocks and roadside objects from a model library. The library is built once from a models folder (with a Markdown credits table listing number, author, source, license and link of each model) and stays out of the repository; `presets/models_catalog.json` lists the chosen models. The example world needs it:

```
godot --headless --path . -s res://tools/uprg_library.gd -- --models=<models folder>
```

The bake writes `<world>.credits.md` next to the world file: CC BY 4.0 models listed there must be credited in any game that uses the world.

## Very large worlds

A big world can be cut into tiles that a game loads while the player drives. Each tile has a detailed mesh, a light mesh for the distance and its own collision. Tile cells must divide the terrain grid:

```
godot --headless --path . -s res://tools/uprg_tiles.gd -- --in=C:/Temp/world.scn --out=C:/Temp/world_tiles --cells=64
```

`--road-colors` writes, in the red vertex color, how close the ground is to a road, for a game shader that textures the ground itself.

## Documentation

- [Architecture 0.2](documentation/UPRG_ARCHITECTURE_0.2.md) (supersedes [0.1](documentation/UPRG_ARCHITECTURE_0.1.md))
- [Testing](documentation/TESTING.md)
- [Changelog](CHANGELOG.md)

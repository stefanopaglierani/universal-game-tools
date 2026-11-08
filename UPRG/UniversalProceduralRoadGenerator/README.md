**English** | [Italiano](README.it.md)

# UPRG — Universal Procedural Road Generator

**Status:** first version in development (0.1.0, not tagged yet)
**Target engine:** Godot 4.7.2 (GDScript)

A private development tool: it adds roads to a terrain baked by UPTG and writes a new world file. It flattens the terrain under the road and adds the road surface and its collision. A game opens the result without any UPTG or UPRG code.

## Folders

| Folder | Content |
|---|---|
| `addons/uprg/` | The generator: `core/`, `builders/` |
| `tools/` | `uprg_bake.gd`, the command-line entry point |
| `presets/` | Road descriptions saved as `.tres` |
| `demo/` | `uprg_viewer.tscn`, shows any baked world file |
| `tests/` | Headless test suite |
| `documentation/` | Architecture and testing |

## Usage

Open a command prompt in this folder (the first command is needed once, after a fresh clone or a new script):

```
godot --headless --editor --quit
godot --headless --path . -s res://tools/uprg_bake.gd -- --in=C:/Temp/island.scn --road=res://presets/example_road_island.tres --out=C:/Temp/island_road.scn
godot --path . res://demo/uprg_viewer.tscn -- --file=C:/Temp/island_road.scn
```

The road follows the points in the `.tres` file, in meters from the center of the terrain. Open it in the Godot editor to change points, width and slope, or duplicate it for a new road. Repeat `--road=` to add more roads.

## Documentation

- [Architecture](documentation/UPRG_ARCHITECTURE_0.1.md)
- [Testing](documentation/TESTING.md)
- [Changelog](CHANGELOG.md)

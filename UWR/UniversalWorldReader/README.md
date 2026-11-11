# UWR — Universal World Reader

**Status:** version 0.1.0 in development
**Target engine:** Godot 4.7.2 (GDScript)

A small runtime addon that lets any Godot game open the worlds made with the Universal Game Tools (UPTG, UPRG and, later, UPWG). It is the only piece of the tools meant to ship inside a game (ADR-0014).

## What it does

- Opens a single-file world, or a tiled world (`world.scn` plus `tile_x_z.scn`), with one node: `UWRWorld`.
- Streams the tiles around a node (by default the active camera) in the background, one new tile per frame, and removes the far ones.
- Paints the ground with a built-in shader: grass, rock on steep slopes, sand by the sea, gravel next to the roads. Colors by default, textures optional, or the game's own material.
- Adds an optional animated sea.
- Gives the game the world data: roads, junctions, places, sea level, and the nearest point of a road.

## Use in a game

1. Copy `addons/uwr/` into the game project.
2. Copy the world folder (for example the output of `uprg_tiles.gd`) into the project.
3. Add a `UWRWorld` node, set `world_file` to the world's `world.scn`, and run.

```gdscript
var world := UWRWorld.new()
world.world_file = "res://worlds/island/world.scn"
world.sea_size = 20000.0
add_child(world)
var road_start: Dictionary = world.nearest_road_point(player.global_position)
```

## Folders

| Folder | Content |
|---|---|
| `addons/uwr/` | `UWRWorld`, ground and sea shaders |
| `demo/` | `uwr_demo.tscn`: fly over a world |
| `tests/` | Headless tests and two small sample worlds made by UPRG |
| `documentation/` | Architecture and testing |

## Demo

```
godot --path . res://demo/uwr_demo.tscn -- --world=C:/Temp/island_tiles/world.scn
```

Drag with the mouse to turn, W A S D to move, Q and E to go down and up, Shift to go faster. `--tour` flies along the first road by itself.

## Documentation

- [Architecture](documentation/UWR_ARCHITECTURE_0.1.md)
- [Testing](documentation/TESTING.md)
- [Changelog](CHANGELOG.md)

# UPWG — Universal Procedural World Generator

**Status:** version 0.1.0 in development (stage 2 of the editor plan)
**Target engine:** Godot 4.7.2 (GDScript), runs on Windows, Linux and macOS

The standalone world editor of the Universal Game Tools. It builds a complete 3D world without writing code: choose a starting point and a seed, shape the terrain with sliders while a 3D preview follows, save the project, and export the world for Godot or for any other program. Under the hood it uses UPTG (terrain), UPRG (roads, places, objects, tiles) and UWR (the reader games use).

## What it does today

1. **Start:** a template (island, continent, coast, highlands, flat land) and a seed. The same template and seed always give the same world; "Random" picks a new seed.
2. **Terrain:** land shape (island, continent or coast), world size up to 8 km, detail, land and hill heights, hill width, coast roughness and line, sea depth.
3. **Mountains:** how many, how high and how wide; "Move the mountains" places them elsewhere with the same seed.
4. **Save and export:** the project is one `.upwg.tres` file. Export writes, in a folder:

| File | For |
|---|---|
| `godot/world.scn` | Godot: open as a scene, or with UWR |
| `godot/tiles/` | Godot: big worlds streamed by UWR |
| `heightmap/height.r16` | Unity, Unreal and most terrain tools (16-bit RAW) |
| `heightmap/height.exr` | Blender, Houdini (32-bit float heights) |
| `heightmap/height.json` | Size, cell and height range of the two heightmaps |
| `gltf/terrain.glb` | Any 3D program or engine |
| `world.json` | Summary: template, seed, size and the files written |

Roads, places, rivers, lakes, single houses, user models, textures and shaders come in the next stages (see the plan in `Documentation`).

## Run

```
godot --path .
```

Drag in the preview to turn around the world, use the mouse wheel to zoom.

## Folders

| Folder | Content |
|---|---|
| `editor/` | The window (`upwg_editor`), the project (`UPWGProject`) and the exporter (`UPWGExporter`) |
| `addons/` | Copies of UPTG, UPRG and UWR, made by `tools/sync_vendor.gd` (do not edit here) |
| `tools/` | `sync_vendor.gd` |
| `tests/` | Headless tests |
| `documentation/` | Architecture and testing |

After changing UPTG, UPRG or UWR, run `godot --headless --path . -s res://tools/sync_vendor.gd`; the tests fail while the copies differ from their sources (ADR-0015).

## Documentation

- [Architecture](documentation/UPWG_ARCHITECTURE_0.1.md)
- [Testing](documentation/TESTING.md)
- [Changelog](CHANGELOG.md)

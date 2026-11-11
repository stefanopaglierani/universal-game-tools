# UPTG — Universal Procedural Terrain Generator

**Status:** version 0.1.0 released (tag `uptg-v0.1.0`)
**Target engine:** Godot 4.7.2 (GDScript)

A reusable, game-agnostic terrain generation module for Godot. Version 0.1 is a deterministic, configurable procedural island generator: irregular coastline, hills, plains, mountain regions, mesh generation and static collision.

## Folders

| Folder | Content |
|---|---|
| `addons/uptg/` | The generator: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` |
| `demo/` | Standalone demo scene |
| `tests/` | Headless test suites, collision test and benchmark |
| `tools/` | Bake tool: writes a generated world to a file for a game |
| `presets/` | Reserved and empty in v0.1: the default preset is `addons/uptg/presets/uptg_island_default.tres` |
| `documentation/` | Architecture, testing procedures, verification results and screenshots |

## Documentation

- [Addon guide](addons/uptg/README.md): installation, quick start, configuration
- [Architecture specification 0.2](documentation/UPTG_ARCHITECTURE_0.2.md)
- [Architecture draft 0.1](documentation/UPTG_ARCHITECTURE.md), kept as a historical reference
- [Testing](documentation/TESTING.md): test suites, benchmark, manual checks, screenshots
- [Milestone 0 verification](documentation/M0_VERIFICATION.md)
- [Changelog](CHANGELOG.md)

## Usage

UPTG is a private development tool and does not go inside a game (ADR-0009). To see it working, open this folder as a project and run `res://demo/uptg_demo.tscn`.

To give a game a world, bake it from this folder (the first command is needed once, after a fresh clone or a new script):

```
godot --headless --editor --quit
godot --headless --path . -s res://tools/uptg_bake.gd -- --out=C:/path/to/game/world/island.scn --seed=12345
```

The `.scn` file holds the mesh, material, collision and height data, with no scripts and no reference to UPTG. In the game, instance it like any other scene. Bake again after a Godot upgrade.

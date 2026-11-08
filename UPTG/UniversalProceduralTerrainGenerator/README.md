**English** | [Italiano](README.it.md)

# UPTG — Universal Procedural Terrain Generator

**Status:** version 0.1.0 released (tag `uptg-v0.1.0`)
**Target engine:** Godot 4.7.2 (GDScript)

A reusable, game-agnostic terrain generation module for Godot. Version 0.1 is a deterministic, configurable procedural island generator: irregular coastline, hills, plains, mountain regions, mesh generation and static collision.

## Folders

| Folder | Content |
|---|---|
| `addons/uptg/` | The portable addon, and the only folder to copy into a game: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` |
| `demo/` | Standalone demo scene |
| `tests/` | Headless test suites, collision test and benchmark |
| `presets/` | Reserved and empty in v0.1: the default preset is `addons/uptg/presets/uptg_island_default.tres` |
| `documentation/` | Architecture, testing procedures, verification results and screenshots |

## Documentation

- [Addon guide](addons/uptg/README.md): installation, quick start, configuration
- [Architecture specification 0.2](documentation/UPTG_ARCHITECTURE_0.2.md), in Italian
- [Architecture draft 0.1](documentation/UPTG_ARCHITECTURE.md), kept as a historical reference
- [Testing](documentation/TESTING.md): test suites, benchmark, manual checks, screenshots
- [Milestone 0 verification](documentation/M0_VERIFICATION.md)
- [Changelog](CHANGELOG.md)

## Usage

Follow the [addon guide](addons/uptg/README.md) to copy `addons/uptg/` into a Godot 4.7.2 project. To see the generator working, open this folder as a project and run `res://demo/uptg_demo.tscn`.

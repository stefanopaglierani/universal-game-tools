**English** | [Italiano](CHANGELOG.it.md)

# UPTG Changelog

All notable changes to UPTG are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the module uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- English version of architecture 0.2 (`documentation/UPTG_ARCHITECTURE_0.2.md`). The Italian text, unchanged, is now `documentation/UPTG_ARCHITECTURE_0.2.it.md`.
- Demo screenshots from Milestones B, C and D in `documentation/screenshots/`, listed in `documentation/TESTING.md`.

### Changed
- Module README updated for version 0.1.0 and the R12 addon layout.

## [0.1.0] - 2026-11-06

First working island generator. `ALGORITHM_VERSION` is 1.

### Added
- Godot 4.7.2 project (`project.godot`) for the module.
- Addon folder structure `addons/uptg/` (`core/`, `builders/`, `nodes/`, `materials/`, `presets/`) and `tests/`, as defined in architecture 0.2 (R12).
- `addons/uptg/LICENSE`, a copy of the repository license (all rights reserved).
- Architecture specification 0.2 (`documentation/UPTG_ARCHITECTURE_0.2.md`, Italian), revision 0.2-r3 with Milestone 0 results.
- Milestone 0 verification results (`documentation/M0_VERIFICATION.md`).
- ADR-0001 to ADR-0006 in `Documentation/architecture/decisions/`.
- Milestone A, data and height field (no scene yet), in `addons/uptg/core/`: `UPTGConfig` (parameters, validation, cost estimate), `UPTGMountainRegion`, `UPTGSeed` (sub-seed derivation), `UPTGTerrainData` (height field, land mask, checksums, height and normal queries) and `UPTGHeightfieldGenerator`. Noise is sampled with seed-derived offsets (architecture 0.2-r4), so the island center also varies with the seed.
- Headless test runner and suites in `tests/` (seed, validation and cost protection, determinism), documented in `documentation/TESTING.md`.
- Milestone B: `UPTGMeshBuilder` (indexed mesh, height-field normals, planar UVs, sand/grass/rock vertex colors), default material `addons/uptg/materials/uptg_terrain_default.tres`, node `UPTGTerrain` (atomic regeneration, signals, statistics, world-space height query; collision follows in Milestone C), demo scene `demo/uptg_demo.tscn`, tests `test_mesh.gd` and `test_terrain_node.gd`.
- Milestone C: `UPTGCollisionBuilder` (`HEIGHTMAP`, `TRIMESH`, `NONE`), collision children `UPTGBody/UPTGShape` with exported `collision_layer` and `collision_mask` in `UPTGTerrain`, collision test scene `tests/collision/collision_test.tscn` (A8, A9, verified on Godot Physics and Jolt), "Drop balls" in the demo.
- Milestone D: island preset `addons/uptg/presets/uptg_island_default.tres`, used by the demo; addon guide `addons/uptg/README.md`; benchmark script `tests/benchmark.gd` with the measurements of architecture section 13 in `documentation/TESTING.md`.

### Changed
- Island preset tuned after the demo (D7): `land_base_height` 8 m, `min_land_height` 2.5 m, `terrain_noise_amplitude` 10 m, `rock_slope_degrees` 38, `rock_height` 60 m; default mountain region `radius` 0.22, `peak_height` 80 m, `falloff` 1.2.
- Vertex colors: sand now takes priority over rock, so low coastal slopes stay sand.
- Cost estimate calibrated with real measurements: `BYTES_PER_CELL` 48 (was 24), `BYTES_PER_CELL_TRIMESH` 320 (was 72); thresholds unchanged. Architecture revision 0.2-r5.
- `UPTGTerrain.generate()` ignores a call made while a generation is running, with a warning, and warns when it generates a `LARGE` configuration; the demo shows the cost estimate before generating.
- The A9 collision checks use their own moderate terrain, independent of the preset tuning.

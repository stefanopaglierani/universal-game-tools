# UPRG Changelog

## [Unreleased]

### Added
- `UPRGTerrainEdit.square` (a square area), `level_mode` (LEVEL: both, only lower, only raise) and `strength` (LEVEL: how far toward the height). Old edits keep their behavior.
- `UPRGTileBuilder.split_grid()`: tiles and `world.scn` written straight from a height grid, for worlds too big to be baked as one mesh (ADR-0017). `split()` shares the same tile code.
- Terrain edits `SMOOTH` (softens the ground, `amount` = strength 0..1) and `ROUGHEN` (adds bumps of `amount` meters and `bump_size` width, repeatable from `noise_seed`). Every edit now only visits the cells inside its area, so thousands of brush dabs stay fast.
- Water (`UPRGWater`, `UPRGWaterBuilder`, `UPRGWorldConfig.water`): lakes at any height, whose level is taken from the lowest point of their rim so they can never spill (a lake on a mountain top works), and rivers whose water only flows downhill along the drawn points. The baker digs them after the terrain edits and adds `Water/Lake<n>` and `Water/River<n>` surfaces and `terrain_data.water`. Tested by `tests/test_sculpt_water.gd`.

### Changed
- English only: the model catalog is `presets/models_catalog.json`, the credits table is found by content in any `.md` file of the models folder, and the example places have English names.

## [0.1.0] - 2026-11-11

### Added
- Roads on terrains baked by UPTG: smooth path from control points, height profile with a slope limit, terrain flattening with blending, road surface and collision.
- Command-line bake tool, world viewer, example road and test suite.
- World description in one `.tres` file: terrain edits (`ADD`, `LEVEL`), places with buildings, and skins with images stored in the world file.
- 3D models in worlds: a lightweight library built from a models folder, buildings from models, scattered trees, plants and rocks, roadside objects, simple collision, view distances, and a credits file written with each world.
- Junctions: roads that cross or end on each other meet at one height on a shared surface with rounded corners.
- Streets inside places, joined to the nearest road, with buildings along them and turned toward the street.
- Tiles for very large worlds: `tools/uprg_tiles.gd` writes terrain tiles with two detail levels and collision, and an example world five times wider.
- `--road-colors` for tiles: the red vertex color marks the ground next to the roads.
- Levels of detail: the model library stores up to six lighter versions of each model, and the renderer picks them by distance. `UPRGDressing.chunk_size` sets how objects are grouped.
- The x5 example world has two villages with streets, trees, rocks and roadside objects.
- `UPRGWorldConfig.connected_roads`: the bake fails, naming the roads, when a road is not joined to the rest of the network. The x5 world uses it.
- Closed roads (`UPRGRoadConfig.closed`): a ring that goes back to its first point, with a smooth closing and junctions kept away from it. The x5 example world has the Costa circuit as a ring on its west coast, joined to the main ring by a link road.

### Fixed
- Slopes are rounded only next to junctions, so the rest of each road keeps its own profile.

### Fixed
- Model parts made of lines or points no longer enter the model library.

### Changed
- Road edges stay clean on a coarse terrain grid.

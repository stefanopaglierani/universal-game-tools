**English** | [Italiano](CHANGELOG.it.md)

# UPRG Changelog

## [Unreleased]

### Added
- Roads on terrains baked by UPTG: smooth path from control points, height profile with a slope limit, terrain flattening with blending, road surface and collision.
- Command-line bake tool, world viewer, example road and test suite.
- World description in one `.tres` file: terrain edits (`ADD`, `LEVEL`), places with buildings, and skins with images stored in the world file.
- 3D models in worlds: a lightweight library built from a models folder, buildings from models, scattered trees, plants and rocks, roadside objects, simple collision, view distances, and a credits file written with each world.
- Junctions: roads that cross or end on each other meet at one height on a shared surface with rounded corners.
- Streets inside places, joined to the nearest road, with buildings along them and turned toward the street.

### Fixed
- Model parts made of lines or points no longer enter the model library.

### Changed
- Road edges stay clean on a coarse terrain grid.

# UPWG Changelog

## [Unreleased]

### Added
- Standalone editor window: templates (island, continent, coast, highlands, flat land) and seeds, terrain and mountain sliders, live 3D preview.
- `UPWGProject`: a whole world in one `.upwg.tres` file, saved and opened from the editor.
- `UPWGExporter`: Godot scene, Godot tiles, 16-bit RAW and EXR heightmaps with their description, glTF terrain mesh and `world.json`.
- Copies of UPTG, UPRG and UWR kept in sync by `tools/sync_vendor.gd` and checked by the tests.

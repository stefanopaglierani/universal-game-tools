# UPWG Changelog

## [Unreleased]

### Added
- Standalone editor window: templates (island, continent, coast, highlands, flat land) and seeds, terrain and mountain sliders, live 3D preview.
- `UPWGProject`: a whole world in one `.upwg.tres` file, saved and opened from the editor.
- `UPWGExporter`: Godot scene, Godot tiles, 16-bit RAW and EXR heightmaps with their description, glTF terrain mesh and `world.json`.
- Sculpting with the mouse: Raise, Lower, Flatten, Smooth and Roughen brushes with size, strength and soft edge, a ring under the mouse, undo and redo (Ctrl+Z, Ctrl+Y), and Clear all. Strokes are stored as UPRG terrain edits, so they work at any detail.
- Water tools: Lake (click, at any height) and River (click the points, right-click or Enter to finish), with size and depth.
- Worlds up to 30 720 m per side (15 km from the center to the edge). Past 2048 cells per side the world is exported straight from its heights: tiles and heightmap at full detail (up to 8192 cells per side, 4 m cells at 30 km), a lighter glTF, no single scene (ADR-0016, ADR-0017).
- Copies of UPTG, UPRG and UWR kept in sync by `tools/sync_vendor.gd` and checked by the tests.

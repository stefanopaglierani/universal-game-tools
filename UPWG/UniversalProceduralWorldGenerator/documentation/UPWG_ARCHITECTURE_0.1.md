# UPWG — Architecture 0.1

**Status:** first version (2026-11-11), stage 2 of the editor plan
**Target engine:** Godot 4.7.2, exported for Windows, Linux and macOS

## 1. Role

UPWG is the standalone editor of the Universal Game Tools: one window where a person who does not program builds a complete world and exports it. It holds no generator logic of its own: terrain comes from UPTG, roads, places, objects and tiles from UPRG, and the exported Godot worlds are read by UWR.

## 2. Pieces

| Piece | Job |
|---|---|
| `UPWGProject` | One world in one `.upwg.tres` file: name, template, `UPTGConfig`, `UPRGWorldConfig`, export choices. `from_template()` builds a world from a template and a seed; `set_size()` keeps the grid within UPTG's 2048 cells per side (ADR-0016); `history` holds the undo steps of the editor; `resize()` sets the side (up to 30 720 m) and keeps a finer export cell in `detail_cell` when the world needs more than 2048 cells per side (ADR-0017); `place_mountains()` places mountains from the seed and a shuffle number |
| `UPWGExporter` | Builds the world at full detail (UPTG bake, then UPRG when the world has roads, places or edits) and writes the chosen formats |
| `upwg_editor` | The window: top bar, Create and Edit tabs with their tools and the options of the tool in use on the left, 3D preview on the right, keys under it. Made to be used by a child (8 years and up): pictures, few words, undo for everything, questions before losing work, autosave |
| `UPWGCamera` | The preview camera: fly with the right button and W A S D, wheel toward the mouse, orbit, focus, whole world and sky views |
| `UPWGI18n` | English texts in the code, Italian in a dictionary given to Godot's `TranslationServer`; the choice is saved in `user://upwg_settings.cfg`. A test checks that every text of the window has its Italian version |

## 3. Preview

The preview is a `UPTGTerrain` node built from a copy of the terrain with at most 192 cells per side and no collision, so it follows the sliders within a fraction of a second. A change waits 0.25 s before rebuilding, so dragging a slider does not rebuild on every step. The final detail is used only by the exporter.

## 4. Export formats

- Godot scene (UPTG/UPRG output) and tiles (UPRG `UPRGTileBuilder`, with road colors for the UWR ground shader).
- Heightmaps: unsigned 16-bit little-endian RAW, normalized between the lowest and highest point, and a 32-bit float EXR in meters, described by `height.json`. These are the neutral formats terrain tools import, including the engines used for console games.
- glTF binary with the ground and the road surfaces.
- `world.json` with template, seed, size and the list of files.

## 5. Generators inside the editor

Godot cannot share an addon between projects, so UPWG keeps copies of the UPTG and UPRG addons, the UPTG baker and UWR under `addons/`, made by `tools/sync_vendor.gd` and checked by `tests/test_vendor.gd` (ADR-0015). The sources stay the only place where the generators are edited.

## 6. Known limits

- Terrain only: roads, places, rivers, lakes, single houses, user models, textures and shaders are the next stages.
- A world of 1024 x 1024 cells takes about 20 s to export on the development PC, with the window waiting; 2048 x 2048 takes about 45 s.

## Large worlds (ADR-0017)

When the export has more than 2048 cells per side (`UPWGProject.is_large()`), `UPWGExporter` calls `UPTGHeightfieldGenerator.generate_heights()` at `detail_cell`, applies the brush strokes and digs the water on that grid, then writes the heightmap, `UPRGTileBuilder.split_grid()` tiles and a glTF at the detail of the terrain configuration. The preview always uses the terrain configuration, at most 192 cells per side.

## Sculpting and water

- Each brush dab is one `UPRGTerrainEdit` (ADD for Raise and Lower, LEVEL for Flatten at the height where the stroke started, SMOOTH, ROUGHEN) in `project.world.terrain_edits`. A stroke is one undo step. Edits are in meters, so the preview (at most 192 cells per side) and the export (full detail) give the same shape.
- Lakes and rivers are `UPRGWater` items in `project.world.water`. They are dug after all brush strokes, in the preview and in the export, so they always sit in their basin or bed.
- The preview builds the UPTG height field, applies the edits and the water to a `UPRGTerrainGrid`, then builds the mesh with `UPTGMeshBuilder`. While a stroke is painted only the new dab is applied; the whole preview is rebuilt at the end of the stroke when the world has water.
- The mouse finds the ground by marching along the camera ray and refining the hit by bisection.
- The glTF terrain is one mesh of the whole world.

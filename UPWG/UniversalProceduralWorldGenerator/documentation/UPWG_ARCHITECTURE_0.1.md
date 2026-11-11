# UPWG — Architecture 0.1

**Status:** first version (2026-11-11), stage 2 of the editor plan
**Target engine:** Godot 4.7.2, exported for Windows, Linux and macOS

## 1. Role

UPWG is the standalone editor of the Universal Game Tools: one window where a person who does not program builds a complete world and exports it. It holds no generator logic of its own: terrain comes from UPTG, roads, places, objects and tiles from UPRG, and the exported Godot worlds are read by UWR.

## 2. Pieces

| Piece | Job |
|---|---|
| `UPWGProject` | One world in one `.upwg.tres` file: name, template, `UPTGConfig`, `UPRGWorldConfig`, export choices. `from_template()` builds a world from a template and a seed; `set_size()` keeps the grid within UPTG's 1024 cells; `place_mountains()` places mountains from the seed and a shuffle number |
| `UPWGExporter` | Builds the world at full detail (UPTG bake, then UPRG when the world has roads, places or edits) and writes the chosen formats |
| `upwg_editor` | The window: controls on the left, 3D preview on the right |

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
- A world of 1024 x 1024 cells takes about 20 s to export on the development PC, with the window waiting.
- The glTF terrain is one mesh of the whole world.

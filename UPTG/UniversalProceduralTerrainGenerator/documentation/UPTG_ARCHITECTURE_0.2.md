# UPTG — Universal Procedural Terrain Generator
## Architecture Specification — Version 0.2

**Status:** architecture approved (0.2-r2). Milestone 0 carried out on 2026-11-06: experimental results are marked with the label [VERIFIED M0]. Milestones A, B, C and D completed: version `0.1.0`; real measurements are labeled [VERIFIED MD].
**Revision:** 0.2-r6 (see Appendix B)
**Project:** Universal Game Tools
**Target engine:** Godot 4.7.2
**Language:** GDScript (static typing)
**Owner:** Stefano
**Supersedes:** `UPTG_ARCHITECTURE.md` (Draft 0.1), which stays unchanged as a historical reference.
**Date:** 2026-11-06

---

## 0. How to read this document

The document uses these labels, summarized in section 16:

- **[APPROVED]** — architectural decision approved by Stefano on 2026-11-06. It changes only with a new approval.
- **[TO VERIFY]** — technical hypothesis to be confirmed experimentally in Godot 4.7.2, almost always in Milestone 0. The hypotheses planned for Milestone 0 have been verified (see [VERIFIED M0]); only the items listed in 16.2 remain [TO VERIFY]. If a test disproves a hypothesis, the document is updated and the change is submitted to Stefano.
- **[DEFERRED]** — decision deliberately moved to a later milestone, stating which one.
- **[VERIFIED M0]** — hypothesis confirmed by a test actually run in Godot 4.7.2 during Milestone 0. Commands, output and measured values are in `documentation/M0_VERIFICATION.md`.
- **[VERIFIED MD]** — value measured in Godot 4.7.2 during Milestone D. Procedure and measurements are in `documentation/TESTING.md`.

The official documentation is the one contained in the `universal-game-tools` repository. The copies in the external folder `C:\Progetti Software\Universal Gmaes Tool` are local references only (D8, [APPROVED]).

---

## 1. Purpose and scope

UPTG is a reusable module for generating 3D procedural terrains in Godot. The first operational goal and the first preset are a deterministic, configurable island for a compact game world.

### 1.1 Strategic principles [APPROVED]

- The core is **game-agnostic**: it contains no racing, survival, RPG, quest, vehicle or other game-specific logic.
- The island is the **first preset**, not the only purpose of the core. The generation pipeline is designed in separate stages (shape mask, relief, localized relief, combination) so that in the future it can support continental terrains, plains, hills, mountain ranges, survival and fantasy environments without rewriting the core.
- These extensions **are not implemented in v0.1**; they are only taken into account in the design (section 14).
- Future modules (roads, vegetation, environments, world generation) use `UPTGTerrainData` exclusively and do not depend on the internal details of the generator.

### 1.2 v0.1 features

- Generation of a deterministic height field from a `generation_seed`.
- Island mask with an irregular coastline and a soft falloff toward the sea.
- Hills through fractal noise, one or more configurable mountain regions.
- Indexed mesh with normals, UVs and vertex colors.
- Static collision: `HeightMapShape3D` (default), trimesh (alternative) or none.
- Reusable `UPTGTerrain` node with regeneration without duplicating nodes.
- Configuration through a Resource that can be saved as a `.tres` preset.
- Standalone demo scene and automated tests.
- Documentation: README, TESTING, CHANGELOG.

### 1.3 Out of scope for v0.1

- Roads, paths, bridges, routes.
- Buildings, vegetation, props, settlements.
- Biomes, custom shaders, advanced material blending.
- Deformable or destructible terrain.
- Infinite terrain, streaming, chunking, LOD.
- Generation on separate threads.
- `@tool` scripts, editor preview, editor dock, `EditorPlugin`.
- Baking inside the addon or from the editor (the bake tool of section 12.5 is outside the addon).
- Erosion, rivers, lakes.
- Shape modes other than the island (continental, etc.).
- Gameplay, AI navigation, vehicle logic.
- Empty directories for future modules (UPRG, UPWG).

---

## 2. Design principles

1. **Reusable:** the core does not depend on any game.
2. **Deterministic:** same configuration + same seed + same build on the same platform = same terrain.
3. **Modular:** configuration, generation, mesh, collision and scene node are separate.
4. **Pure where possible:** the height field generator does not access the scene.
5. **Inspectable:** data and results are readable and measurable.
6. **Incremental:** small milestones, each verified before the next.
7. **Measured:** no performance claim without measurements.
8. **Verified:** no API declared compatible with 4.7.2 without a test.
9. **Portable:** everything needed at runtime is in `addons/uptg/`.
10. **Safe:** no change to existing files without approval.

---

## 3. Repository structure [APPROVED]

The repository already exists at `C:\Progetti Software\Universal Gmaes Tool\universal-game-tools`, connected to `github.com/stefanopaglierani/universal-game-tools`, branch `main`. The structure below shows how UPTG fits into what exists; files marked "existing" are not changed by this document.

```text
universal-game-tools/                         root of the Git repository (existing)
├── README.md                                 existing
├── CHANGELOG.md                              existing (repository level)
├── LICENSE                                   existing, "All rights reserved" (D2)
├── Documentation/                            existing: architecture/ (with ADRs), development/
├── UPRG/, UPWG/                              existing, placeholder README only; no content added
└── UPTG/
    └── UniversalProceduralTerrainGenerator/  standalone Godot project (project.godot)
        ├── project.godot
        ├── addons/
        │   └── uptg/                         portable addon: the only folder to copy
        │       ├── core/
        │       │   ├── uptg_config.gd
        │       │   ├── uptg_mountain_region.gd
        │       │   ├── uptg_terrain_data.gd
        │       │   ├── uptg_seed.gd
        │       │   └── uptg_heightfield_generator.gd
        │       ├── builders/
        │       │   ├── uptg_mesh_builder.gd
        │       │   └── uptg_collision_builder.gd
        │       ├── nodes/
        │       │   └── uptg_terrain.gd
        │       ├── materials/
        │       │   └── uptg_terrain_default.tres
        │       ├── presets/
        │       │   └── uptg_island_default.tres
        │       ├── LICENSE                   copy of "All rights reserved"
        │       └── README.md
        ├── demo/
        │   ├── uptg_demo.tscn
        │   └── uptg_demo_controller.gd
        ├── tests/
        │   ├── run_tests.gd
        │   ├── test_validation.gd
        │   ├── test_seed.gd
        │   ├── test_determinism.gd
        │   ├── test_mesh.gd
        │   └── collision/
        │       ├── collision_test.tscn
        │       └── collision_test.gd
        ├── tools/
        │   ├── uptg_baker.gd
        │   └── uptg_bake.gd
        ├── documentation/
        │   ├── UPTG_ARCHITECTURE.md          Draft 0.1, unchanged
        │   ├── UPTG_ARCHITECTURE_0.2.md      this document
        │   └── TESTING.md
        └── CHANGELOG.md
```

Rules:

- Runtime code in `addons/uptg/` uses only `res://addons/uptg/...` paths and does not reference `demo/`, `tests/` or files outside the addon. This is verified with a text search (acceptance criterion A13).
- No `plugin.cfg` or `EditorPlugin` in v0.1: classes with `class_name` are available without enabling a plugin.
- All `class_name` declarations have the `UPTG` prefix to avoid conflicts in the projects that import the addon.
- No new directories for future modules. The `UPRG/` and `UPWG/` folders already exist with a placeholder README; they are not touched.
- The repository follows `Documentation/development/CONVENTIONS.md` (static typing, `##` doc comments, `push_error()`/`push_warning()`, names prefixed with the module) and `WORKFLOW.md` (branches `uptg/<description>` and `docs/<description>`, commits prefixed with `UPTG:`, tags `uptg-v<version>`).
- **D1 [APPROVED]:** the R12 structure applies, with `core/`, `builders/`, `nodes/`, `materials/` and `presets/` inside `addons/uptg/`. `Documentation/architecture/README.md` and the module README still describe `runtime/` + `resources/` and a module-level `presets/` folder: **they are not changed now** and stay temporarily out of line. Their alignment is **[DEFERRED]** to a documentation update to be approved separately. For UPTG, in case of a difference, this document prevails.
- The module-level folder `UPTG/UniversalProceduralTerrainGenerator/presets/` (currently empty, with `.gitkeep`) is not used in v0.1; its fate is decided together with the alignment of the documents.
- **D2 [APPROVED]:** the license stays "All rights reserved". `addons/uptg/LICENSE` will be a copy of the same text. No permissive license and no public distribution are authorized.

---

## 4. Components and responsibilities

```text
UPTGConfig ──► UPTGHeightfieldGenerator ──► UPTGTerrainData ──┬─► UPTGMeshBuilder ──────► ArrayMesh
 (Resource)        (pure, no scene)            (contract)      ├─► UPTGCollisionBuilder ─► Shape3D
                                                               └─► future modules (roads, vegetation...)

UPTGTerrain (Node3D) orchestrates the flow and owns the child nodes.
```

| Component | Type | Responsibility | Does not |
|---|---|---|---|
| `UPTGConfig` | `Resource` | All parameters, validation, saving as a preset | No terrain computation |
| `UPTGMountainRegion` | `Resource` | Parameters of a single mountain region | — |
| `UPTGSeed` | static class | Deterministic derivation of sub-seeds | No global state |
| `UPTGHeightfieldGenerator` | class with static functions only, stateless | Config → `UPTGTerrainData` | No access to the scene, nodes or graphics resources |
| `UPTGTerrainData` | `RefCounted` | Terrain data contract and queries | No generation, no graphics |
| `UPTGMeshBuilder` | static class | `UPTGTerrainData` → `ArrayMesh` | No collision |
| `UPTGCollisionBuilder` | static class | `UPTGTerrainData` → `Shape3D` | No node management |
| `UPTGTerrain` | `Node3D` | Orchestration, child nodes, regeneration, signals, errors | No game logic |

Note on names: `UPTGGenerator` from Draft 0.1 becomes `UPTGHeightfieldGenerator` (the "orchestration" part moves to `UPTGTerrain`); `UPTGTerrainBuilder` becomes `UPTGMeshBuilder`.

---

## 5. Configuration: `UPTGConfig` [APPROVED]

`class_name UPTGConfig extends Resource`. Exported properties with `@export_group`, `@export_range` and tooltips (`##` comments). The default values are provisional and will be tuned in Milestone D.

### 5.1 Parameters

| Group | Property | Type | Valid range | Provisional default | Notes |
|---|---|---|---|---|---|
| Seed | `generation_seed` | `int` | 0 – 2 147 483 647 | 12345 | 31-bit limit, compatible with `FastNoiseLite.seed` |
| Grid | `grid_cells_x` | `int` | 2 – 2048 | 256 | Number of cells; vertices = cells + 1 |
| Grid | `grid_cells_z` | `int` | 2 – 2048 | 256 | As above |
| Grid | `cell_size` | `float` | 0.25 – 64.0 m | 4.0 | Cells are always square |
| Sea | `sea_level` | `float` | any | 0.0 m | Height of the sea level |
| Sea | `sea_floor_depth` | `float` | 0.5 – 500 m | 20.0 m | Depth of the sea floor below `sea_level` where the mask is 0 |
| Island | `island_radius` | `Vector2` | 0.1 – 0.85 per axis | (0.6, 0.6) | Normalized radii of the base ellipse; see the constraint in 5.3 |
| Island | `coastline_irregularity` | `float` | 0.0 – 0.5 | 0.25 | Amplitude of the coastline perturbation |
| Island | `coastline_noise_frequency` | `float` | 0.0001 – 0.1 | 0.004 | Frequency in world units (see 6.1) |
| Island | `coastline_falloff_width` | `float` | 0.01 – 0.8 | 0.25 | Normalized width of the land-sea transition |
| Relief | `land_base_height` | `float` | 0 – 500 m | 8.0 m | Average inland height above `sea_level` |
| Relief | `min_land_height` | `float` | 0 – 50 m | 2.5 m | Minimum inland height (avoids lakes in v0.1) |
| Relief | `terrain_noise_frequency` | `float` | 0.0001 – 0.1 | 0.006 | Frequency in world units |
| Relief | `terrain_noise_amplitude` | `float` | 0 – 500 m | 10.0 m | Amplitude of the hills |
| Relief | `noise_octaves` | `int` | 1 – 8 | 4 | `FastNoiseLite.fractal_octaves` |
| Relief | `noise_lacunarity` | `float` | 1.0 – 4.0 | 2.0 | `FastNoiseLite.fractal_lacunarity` |
| Relief | `noise_gain` | `float` | 0.0 – 1.0 | 0.5 | `FastNoiseLite.fractal_gain` |
| Mountains | `mountain_regions` | `Array[UPTGMountainRegion]` | 0 – 16 elements | 1 region | See 5.2 |
| Collision | `collision_mode` | `enum` | `HEIGHTMAP`, `TRIMESH`, `NONE` | `HEIGHTMAP` | See section 9 |
| Appearance | `uv_tile_size` | `float` | 0.1 – 1000 m | 8.0 m | Meters covered by one UV repeat |
| Appearance | `sand_color`, `grass_color`, `rock_color` | `Color` | — | neutral tones | Vertex colors |
| Appearance | `beach_height` | `float` | 0 – 50 m | 1.5 m | Sand band above `sea_level` |
| Appearance | `rock_slope_degrees` | `float` | 0 – 90 | 38 | Slope beyond which the color tends to rock |
| Appearance | `rock_height` | `float` | 0 – 2000 m | 60 m | Height beyond which the color tends to rock |

### 5.2 `UPTGMountainRegion` [APPROVED]

`class_name UPTGMountainRegion extends Resource`

| Property | Type | Range | Meaning |
|---|---|---|---|
| `center` | `Vector2` | 0.0 – 1.0 per axis | Normalized position on the terrain (0,0 = -X/-Z corner, 1,1 = +X/+Z corner) |
| `radius` | `float` | 0.01 – 1.0 | Radius normalized to the smaller terrain dimension |
| `peak_height` | `float` | 0 – 2000 m | Height added at the center |
| `falloff` | `float` | 0.25 – 8.0 | Exponent of the decay curve (1 = soft, high values = narrower peak) |

The default region of the island preset (D7, tuned in Milestone D) has `center` (0.5, 0.5), `radius` 0.22, `peak_height` 80 m and `falloff` 1.2.

Normalized coordinates keep the mountain in the same relative position when `cell_size` or the number of cells changes.

### 5.3 Validation

`UPTGConfig.validate() -> PackedStringArray` returns the list of errors (empty if valid). Rules:

- all values within the ranges of table 5.1;
- **coastline constraint:** `max(island_radius.x, island_radius.y) / (1 - coastline_irregularity) <= 0.9`. With the perturbation of section 8.2 the coastline can move away from the center up to `radius / (1 - irregularity)`; beyond 0.9 it would be cut by the border band and become a straight stretch. With the default values: 0.6 / 0.75 = 0.8;
- grid size and estimated cost according to section 5.4;
- `mountain_regions` without `null` elements, each region valid;
- all `float` values finite (no NaN or infinity).

If validation fails, generation does not start, the previous terrain stays in the scene and `UPTGTerrain` emits `generation_failed` with the message.

### 5.4 Protection against expensive configurations [APPROVED]

Goal: prevent a preset, a typo or a value changed at runtime from freezing the game or the editor for many seconds or exhausting memory.

**Pre-generation estimate.** `UPTGConfig.estimate_cost() -> Dictionary` computes, without generating anything:

| Key | Computation |
|---|---|
| `cells` | `grid_cells_x * grid_cells_z` |
| `vertices` | `(grid_cells_x + 1) * (grid_cells_z + 1)` |
| `triangles` | `2 * cells` |
| `noise_samples` | `vertices * (noise_octaves + 2)` (fractal relief + 2-octave coastline) |
| `estimated_bytes` | `vertices * 112 + cells * 48`, plus `cells * 320` if `collision_mode == TRIMESH` |
| `level` | `OK`, `LARGE` or `REJECTED` (table below) |

The memory coefficients were calibrated in Milestone D with real measurements **[VERIFIED MD]** (details in `documentation/TESTING.md`). 112 bytes per vertex cover the height field and mask (8), the CPU-side mesh arrays (position, normal, UV, color: 48), the GPU-side copy (48) and the collision heightmap (4, rounded): the measured video memory is about 54 bytes per vertex, consistent with the estimate. 48 bytes per cell cover the indices on the CPU and GPU sides (the a priori estimates counted 24, CPU side only). 320 bytes per cell are the measured cost of `ConcavePolygonShape3D` (about 84 MB at 512 × 512 cells), which includes the internal structures of the physics engine: the a priori estimates (72) underestimated it by more than 4 times. The thresholds in the following table stayed unchanged: with the calibrated coefficients, 512 × 512 cells in `HEIGHTMAP` are estimated at about 40 MB (`OK`) and the worst accepted case, 1024 × 1024 in `TRIMESH`, at about 480 MB, below the 512 MB limit.

**Levels and behavior:**

| Level | Condition | Behavior |
|---|---|---|
| `OK` | `cells <= 262 144` (512 × 512) and `estimated_bytes <= 128 MB` | Normal generation |
| `LARGE` | beyond the `OK` threshold, but `cells <= 4 194 304` and `estimated_bytes <= 1 GB` (ADR-0016; until 2026-11-11: 1 048 576 cells and 512 MB) | Generation **refused** with `generation_failed`, unless the `UPTGTerrain` node has `allow_large_terrain = true`; in that case it proceeds with `push_warning()` |
| `REJECTED` | `grid_cells_x` or `grid_cells_z` above 2048, or beyond the `LARGE` limits | Generation always refused, even with `allow_large_terrain` |

Additional rules:

- `allow_large_terrain` is on the **node**, not in the Resource: a shared or downloaded `.tres` preset cannot bypass the protection on its own.
- With `collision_mode == TRIMESH` the `OK` threshold drops to 65 536 cells (256 × 256), because the trimesh is the most expensive part to build and to query.
- The thresholds are named constants in `UPTGConfig` (`MAX_CELLS_OK`, `MAX_CELLS_HARD`, `MAX_BYTES_OK`, `MAX_BYTES_HARD`, `MAX_CELLS_OK_TRIMESH`), not values scattered through the code. They may be revised after the Milestone D measurements, with approval.
- The estimate and the level are reported by `UPTGTerrain.get_last_stats()` and shown in the demo **before** generating.
- **Regeneration:** `UPTGTerrain.generate()` is not re-entrant: a call during a generation in progress (for example from a `generation_finished` handler) is ignored with `push_warning()`. The demo applies regeneration only on an explicit action (button), not on every change to a field.
- **Time:** no timeout is imposed, because generation is synchronous and cannot be interrupted in v0.1. Time is controlled indirectly by `cells` and `noise_samples`. The Milestone D measurements (`documentation/TESTING.md`) give, on a laptop with Intel UHD 620, about 1.8 s for height field and mesh at 512 × 512 cells and about 1.5 s more for the trimesh: for this reason no threshold in seconds was added.

---

## 6. Coordinate system and grid [APPROVED]

- Godot is Y-up. The terrain lies on the XZ plane, Y is the height.
- The terrain is **centered on the origin** of the `UPTGTerrain` node.
- Vertices per axis: `vx = grid_cells_x + 1`, `vz = grid_cells_z + 1`.
- Dimensions: `size_x = grid_cells_x * cell_size`, `size_z = grid_cells_z * cell_size`.
- Local position of vertex `(ix, iz)`:
  - `x = (ix - grid_cells_x / 2.0) * cell_size`
  - `z = (iz - grid_cells_z / 2.0) * cell_size`
- Array index: `i = iz * vx + ix` (rows along X). This order matches the order of `HeightMapShape3D.map_data` **[VERIFIED M0]** (Godot Physics and Jolt; the transposed hypothesis gives errors of 23 m).
- All noise and mask functions receive coordinates **in meters** (local space), not grid indices: changing the resolution changes the detail, not the shape of the island.

### 6.1 Frequency units

`FastNoiseLite` multiplies the input coordinates by `frequency`. Since the input is in meters, a frequency of 0.004 corresponds to structures with a period on the order of 1 / 0.004 = 250 m. The user documentation will use this rule of thumb.

---

## 7. Seed system and determinism [APPROVED]

### 7.1 Sub-seeds

Each random stage uses its own sub-seed derived from the main seed with a constant "salt":

| Salt | Constant | Use in v0.1 |
|---|---|---|
| 1 | `SALT_COASTLINE` | Coastline `FastNoiseLite` |
| 2 | `SALT_TERRAIN` | Relief `FastNoiseLite` |
| 3 | `SALT_MOUNTAINS` | Reserved (random mountain placement, not in v0.1) |
| 4 | `SALT_COASTLINE_OFFSET` | Sampling offset of the coastline noise (8.2) |
| 5 | `SALT_TERRAIN_OFFSET` | Sampling offset of the relief noise (8.3) |
| 6 – 99 | — | Reserved for UPTG |

Rules: salts are never reordered or reused; a new use gets a new number.

### 7.2 Derivation function

32-bit integer hash ("lowbias32" variant), with multiplication modulo 2^32 implemented without overflowing GDScript's 64-bit `int`:

```gdscript
# addons/uptg/core/uptg_seed.gd  (reference pseudocode, not written yet)
const MASK32 := 0xFFFFFFFF

static func _mul32(a: int, b: int) -> int:
    # (a * b) mod 2^32 without exceeding 2^63
    var lo := (a & 0xFFFF) * b
    var hi := ((a >> 16) * b) & 0xFFFF
    return (lo + (hi << 16)) & MASK32

static func derive(master_seed: int, salt: int) -> int:
    var x := (master_seed ^ _mul32(salt, 0x9E3779B9)) & MASK32
    x = _mul32(x ^ (x >> 16), 0x7FEB352D)
    x = _mul32(x ^ (x >> 15), 0x846CA68B)
    x = x ^ (x >> 16)
    return x & 0x7FFFFFFF   # 31 bits, valid as a FastNoiseLite seed
```

- `String.hash()` and `hash()` are not used: their result is not guaranteed to be stable across engine versions.
- The `test_seed.gd` test pins known reference values ("test vectors") for `derive()`; if they change, the test fails.

### 7.3 Rules on randomness

- `randi()`, `randf()`, `randomize()`, global `seed()` and any global random state are forbidden in the addon code.
- Any random step uses a local `RandomNumberGenerator` with `seed` set by `UPTGSeed.derive()`.
- No dependency on time, frame, loading order or window size.

### 7.4 Determinism guarantee

- **Guaranteed:** same configuration + same `generation_seed` + same Godot build + same platform = bit-for-bit identical height field.
- **Goal, not a guarantee:** identity across different platforms and CPUs. It will be tested when possible and documented.
- `UPTGTerrainData` records `ALGORITHM_VERSION` (integer, starts at 1). Any change to the formula that changes the output for the same seed increments the version and is noted in the CHANGELOG.
- The height field checksum uses its own function (32-bit FNV-1a on the bytes of `heights`), not `hash()`, for the same reason as in 7.2.

---

## 8. Terrain algorithm [APPROVED]

### 8.1 Pipeline

```text
for each vertex (ix, iz):
  1. local position (x, z) in meters                     [section 6]
  2. mask      = shape_mask(x, z)        0 = sea, 1 = inland
  3. hills     = terrain_noise(x, z) * terrain_noise_amplitude
  4. mount     = mountains(x, z)
  5. land      = max(land_base_height + hills + mount, min_land_height)
  6. height    = lerp(sea_level - sea_floor_depth, sea_level + land, mask)
  7. heights[i] = height,  land_mask[i] = mask
```

Stages 2, 3 and 4 are separate functions. In the future other shapes (continental, plain) will replace only stage 2, without changing the others (section 14).

### 8.2 Island mask (`shape_mask`)

Normalized coordinates `u = x / (size_x / 2)`, `v = z / (size_z / 2)`, both in [-1, 1].

```text
d       = sqrt( (u / island_radius.x)^2 + (v / island_radius.y)^2 )   elliptical distance, 1 = base coastline
c       = clamp(coastline_noise(x, z), -1, 1)                          2D noise on position, not on angle
d_pert  = d * (1 + coastline_irregularity * c)
mask    = 1 - smoothstep(1 - coastline_falloff_width, 1, d_pert)
edge    = 1 - smoothstep(0.9, 1.0, max(|u|, |v|))                      guarantees sea at the border
mask    = mask * edge
```

- The coastline noise is sampled on position (x, z) and not on the polar angle, to avoid the seam where the angle goes from -π to π.
- The `edge` factor guarantees that the last 10% of the grid is always sea, whatever the configuration: the edge of the mesh stays below sea level and is not visible.
- The coastline noise uses `FastNoiseLite` with `seed = derive(generation_seed, SALT_COASTLINE)`, Simplex Smooth type, FBM fractal with 2 fixed octaves in v0.1.
- **Sampling offset [APPROVED, 0.2-r4]:** simplex noise is 0 at the origin for any seed, so without a correction the center of the island would never receive coastline variation or hills. The coastline noise is therefore sampled at `(x, z) + coastline_offset`, with `coastline_offset = UPTGSeed.noise_offset(generation_seed, SALT_COASTLINE_OFFSET)`. Each component is a whole number of meters between 1024 and 9215: `h = derive(generation_seed, salt)`, `offset = (1024 + (h & 0x1FFF), 1024 + ((h >> 13) & 0x1FFF))`. The offset is added to the coordinates in meters, so resolution independence (section 6) still holds.

### 8.3 Relief (`terrain_noise`)

A single `FastNoiseLite` [APPROVED]: `seed = derive(generation_seed, SALT_TERRAIN)`, Simplex Smooth type, FBM fractal with `noise_octaves`, `noise_lacunarity`, `noise_gain`, `frequency = terrain_noise_frequency`. The value returned by `get_noise_2d(x, z)` is clamped to [-1, 1]. As for the coastline, sampling happens at `(x, z) + relief_offset`, with `relief_offset = UPTGSeed.noise_offset(generation_seed, SALT_TERRAIN_OFFSET)` (section 8.2, 0.2-r4).

### 8.4 Mountains (`mountains`)

For each region `r`:

```text
center_m  = ((r.center.x - 0.5) * size_x, (r.center.y - 0.5) * size_z)
radius_m  = r.radius * min(size_x, size_z)
t         = 1 - clamp(distance((x, z), center_m) / radius_m, 0, 1)
contrib_r = r.peak_height * pow(smoothstep(0, 1, t), r.falloff)
```

`mountains(x, z) = max(contrib_r)` over all regions. The maximum is used, not the sum, to avoid anomalous peaks where regions overlap. Since the result goes through the `lerp` with the mask (stage 6), a mountain placed in the sea does not emerge.

### 8.5 Coastline

With the formula of stage 6, the height is exactly `sea_level` where:

```text
mask = sea_floor_depth / (sea_floor_depth + land)
```

With the default values (sea floor 20 m, inland about 6 m) the coastline falls where the mask is about 0.77. The user documentation will explain how `sea_floor_depth` and `coastline_falloff_width` control the slope of the beach.

### 8.6 Known limits of the algorithm in v0.1

- No inland lakes (prevented by `min_land_height`; exclusion confirmed, D4 [APPROVED]), no rivers, no erosion.
- Mountains are soft cones, not ranges.
- Maximum slopes depend on `cell_size` and on the noise amplitude; they are to be measured in Milestone D.

---

## 9. Data contract: `UPTGTerrainData` [APPROVED]

`class_name UPTGTerrainData extends RefCounted`. It is the **official contract** between UPTG and any external system. After generation it is to be considered read-only.

### 9.1 Fields

| Field | Type | Meaning |
|---|---|---|
| `ALGORITHM_VERSION` | `const int` | Version of the algorithm that produced the data |
| `generation_seed` | `int` | Seed used |
| `config_checksum` | `int` | 32-bit FNV-1a of `var_to_bytes()` applied to an ordered `Array` of only the parameters that affect heights (seed, grid, sea, island, relief, mountains). Stable within the same Godot version, not guaranteed across versions |
| `heights_checksum` | `int` | 32-bit FNV-1a of `heights` |
| `grid_cells_x`, `grid_cells_z` | `int` | Cells per axis |
| `vertex_count_x`, `vertex_count_z` | `int` | Vertices per axis (cells + 1) |
| `cell_size` | `float` | Cell side in meters |
| `size` | `Vector2` | Total dimensions (X, Z) in meters |
| `sea_level` | `float` | Sea level |
| `sea_floor_depth` | `float` | Sea floor depth below `sea_level` (also used outside the grid) |
| `min_height`, `max_height` | `float` | Extremes of the height field |
| `heights` | `PackedFloat32Array` | Heights in local space, index `iz * vx + ix` |
| `land_mask` | `PackedFloat32Array` | Mask value (0–1) per vertex |

### 9.2 Query methods

All coordinates are in the **local space** of the `UPTGTerrain` node. The node provides the world-space versions.

| Method | Result |
|---|---|
| `get_vertex_height(ix, iz) -> float` | Height of the vertex |
| `get_vertex_position(ix, iz) -> Vector3` | Local position of the vertex |
| `is_inside(x, z) -> bool` | Whether the point falls inside the grid |
| `get_height_at(x, z) -> float` | Height interpolated on the **triangles**, with the same diagonal as the mesh and the collision (section 10.2), so it matches what the player sees and touches |
| `get_normal_at(x, z) -> Vector3` | Interpolated normal |
| `get_mask_at(x, z) -> float` | Interpolated mask |
| `is_land_at(x, z) -> bool` | `get_height_at(x, z) > sea_level` |

Outside the grid, `get_height_at` returns `sea_level - sea_floor_depth` and `is_inside` returns `false`.

### 9.3 Use by future modules

A road or vegetation module receives a `UPTGTerrainData` (directly or through `UPTGTerrain.get_terrain_data()`) and uses only the fields and methods of this section. Any incompatible change to the contract requires a major version increment and a note in the CHANGELOG.

Modification of the terrain by future modules (for example flattening a road) is not planned in v0.1; it will be the subject of a future decision.

---

## 10. Mesh [APPROVED]

`UPTGMeshBuilder.build(data: UPTGTerrainData, config: UPTGConfig) -> ArrayMesh`

### 10.1 Geometric data

- One vertex per grid point (`vx * vz` vertices), **indexed** geometry.
- `PackedVector3Array`, `PackedVector2Array`, `PackedColorArray`, `PackedInt32Array` arrays pre-sized with `resize()`.
- A single surface, created with `ArrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)`.
- Beyond 65 535 vertices the indices stay intact **[VERIFIED M0]**: mesh of 90 000 vertices and 536 406 indices, maximum index 89 999 read back correctly, both headless and with the Forward+ renderer (Vulkan).

### 10.2 Triangles, winding and diagonal

- Each cell produces 2 triangles, hence `2 * grid_cells_x * grid_cells_z` triangles.
- Winding order: the front face is the one with vertices **clockwise as seen by the observer** **[VERIFIED M0]**. Verified in rendering (default `CULL_BACK` culling: the triangle that is clockwise from the camera is visible, the counterclockwise one is not) and in physics (`ConcavePolygonShape3D` with `backface_collision = false`: the ray hits only from the side where the vertices appear clockwise), on both backends. For a terrain seen from above, each triangle must therefore be emitted clockwise as seen from +Y.
- All cells use the **same diagonal**: the one joining vertex `(ix + 1, iz)` to vertex `(ix, iz + 1)` **[VERIFIED M0]**. It is the diagonal used by `HeightMapShape3D` in all cells, with Godot Physics and with Jolt. Each cell therefore splits into triangles `(00, 10, 01)` and `(10, 11, 01)`. With the opposite diagonal the error measured on a test terrain reaches 31.6 cm. The same rule applies to `get_height_at`: if `fx + fz <= 1` it interpolates on triangle `(00, 10, 01)`, otherwise on `(10, 11, 01)`.

### 10.3 Normals

Computed from the height field with central differences (one-sided differences at the edges):

```text
n = normalize( Vector3( h(ix-1, iz) - h(ix+1, iz),  2 * cell_size,  h(ix, iz-1) - h(ix, iz+1) ) )
```

`SurfaceTool.generate_normals()` is not used. Tangents are not generated in v0.1 (no normal map).

### 10.4 UV

Planar projection in meters: `uv = Vector2(x, z) / uv_tile_size`. Known limit: texture stretching on steep slopes. Triplanar projection is postponed.

### 10.5 Vertex colors

Per-vertex color computed from height and slope, with soft transitions (`smoothstep`):

- sand: height within `beach_height` above `sea_level`;
- rock: slope beyond `rock_slope_degrees` or height beyond `rock_height`;
- grass: elsewhere.

Sand takes precedence over rock (`grass.lerp(rock, w_rock).lerp(sand, w_sand)`): a low coastal cliff stays sand and does not become rock. Choice made in Milestone D during the preset tuning.

### 10.6 Material [APPROVED]

A `StandardMaterial3D` (`addons/uptg/materials/uptg_terrain_default.tres`) with `vertex_color_use_as_albedo = true`. No custom shader in v0.1. The node allows replacing it with a game material.

---

## 11. Collision [APPROVED]

`UPTGCollisionBuilder.build(data: UPTGTerrainData, mode) -> Shape3D` (or `null` for `NONE`).

### 11.1 `HEIGHTMAP` (default)

- `HeightMapShape3D` with `map_width = vertex_count_x`, `map_depth = vertex_count_z`.
- `map_data` = `heights` divided by `cell_size`, because the shape uses samples spaced 1 unit apart.
- The `CollisionShape3D` receives a **uniform** scale `Vector3(cell_size, cell_size, cell_size)`; dividing the heights and scaling uniformly avoids non-uniform scale, which is not reliable on collision shapes.
- The shape is centered on its own origin, like the mesh (section 6).
- **[VERIFIED M0]** (D5): the shape is centered on the origin; `map_data` follows the order `iz * vx + ix`; the diagonal is the one of section 10.2; the uniform scale of the `CollisionShape3D` with heights divided by `cell_size` works (tested with `cell_size` 1 and 4, maximum error 0.09 mm with Godot Physics and 0.13 mm with Jolt). The same rules apply to non-square grids (7×4, 4×9, 65×33 vertices; maximum error 0.22 mm). No collision outside the grid.
- **Physics backend (D3, [APPROVED]):** the initial tests use the default backend; the same test is repeated on the other backend and the result is documented.
- **[VERIFIED M0]** With UPTG's `project.godot` the setting `physics/3d/physics_engine` is `DEFAULT` and the actual backend is **Godot Physics**: the ray values match bit for bit those obtained by forcing `GodotPhysics3D` and differ from those with Jolt. `PhysicsServer3D.get_class()` returns `PhysicsServer3D` with both backends and cannot identify them. Jolt was tested through a temporary `override.cfg`: order, centering, diagonal, winding and scale behave identically.

### 11.2 `TRIMESH` (alternative)

`ConcavePolygonShape3D` built from the same triangles as the mesh with `set_faces()`. More expensive in memory and build time; useful if `HEIGHTMAP` showed limits in a specific case. With `backface_collision = false` (the default) the triangles must be clockwise as seen from +Y, as in the mesh, otherwise rays from above do not hit them **[VERIFIED M0]**.

### 11.3 `NONE`

No collision; `UPTGTerrain` removes or disables the `StaticBody3D`.

### 11.4 Rules

- Collision is always on a `StaticBody3D`, never on a dynamic body.
- `collision_layer` and `collision_mask` are exported on the `UPTGTerrain` node.
- The alignment test (A8) casts vertical rays on a grid of points and compares the hit point with `get_height_at`; the difference must stay within the tolerance. **D6:** 1 cm **[VERIFIED M0]**. On a 64 × 64 grid with `cell_size` 4 and 2000 rays, the maximum error with the correct diagonal is 0.19 mm (Godot Physics) and 0.15 mm (Jolt) for `HEIGHTMAP`, 0.20 mm or less for `TRIMESH`: the 1 cm tolerance has a wide margin and is confirmed.

---

## 12. `UPTGTerrain` node [APPROVED]

`class_name UPTGTerrain extends Node3D`. It is the entry point for any game.

### 12.1 Interface

| Type | Name | Description |
|---|---|---|
| `@export` | `config: UPTGConfig` | Preset to use |
| `@export` | `generate_on_ready: bool = true` | Generates in `_ready()` |
| `@export` | `material_override: Material` | Optional; if empty uses the default material |
| `@export` | `allow_large_terrain: bool = false` | Authorizes `LARGE` level configurations (section 5.4) |
| `@export_flags_3d_physics` | `collision_layer`, `collision_mask` | Collision layers |
| method | `generate() -> bool` | Validates, generates, replaces mesh and collision |
| method | `clear()` | Removes mesh and collision |
| method | `get_terrain_data() -> UPTGTerrainData` | Last valid result or `null` |
| method | `get_height_at_world(pos: Vector3) -> float` | World-space query |
| method | `get_last_stats() -> Dictionary` | Times (µs) per stage, vertices, triangles, cost estimate and level (5.4) |
| signal | `generation_started` | — |
| signal | `generation_finished(data: UPTGTerrainData)` | — |
| signal | `generation_failed(message: String)` | — |

### 12.2 Child nodes

```text
UPTGTerrain (Node3D)
├── UPTGMesh       (MeshInstance3D)
└── UPTGBody       (StaticBody3D)
    └── UPTGShape  (CollisionShape3D)
```

- Created at the first generation, with fixed names.
- They do not receive an `owner`: they are not saved in the `.tscn` scene, so scene files stay small and free of generated data.
- On regeneration the **resources are replaced** (`mesh`, `shape`), not the nodes. No duplicated nodes, ever.

### 12.3 Atomicity and errors

- Everything is generated first (data, mesh, shape); only if every step succeeds are the resources in the nodes replaced. In case of error the previous terrain stays intact.
- Errors are emitted with `push_error()` and with the `generation_failed` signal.
- Generation is synchronous; it must not be called inside `_physics_process` or physics callbacks.
- Known limit: physics bodies resting on the terrain during a regeneration may pass through it or be pushed; documented, not handled in v0.1.

### 12.4 Runtime only [APPROVED]

No script uses `@tool`. There is no editor preview or editor dock in v0.1, and the addon itself does not bake.

### 12.5 Bake tool [APPROVED, 0.2-r6]

UPTG and its sub-programs are private development tools: they create worlds and 3D objects for other software and do not ship inside it (D10, ADR-0009). The game receives only the generated result.

- `tools/uptg_baker.gd` (`UPTGBaker.bake(config, out_path, allow_large)`) generates through the public functions of sections 8, 10 and 11, unchanged, and writes one compressed `.scn` file.
- `tools/uptg_bake.gd` is the command-line entry point (`-- --out=<file.scn> [--preset=<res path>] [--seed=<n>] [--allow-large]`).
- The file contains a `Node3D` named `Terrain` with `Mesh` (`MeshInstance3D`) and `Body/Shape` (`StaticBody3D`, `CollisionShape3D`). Mesh, material and shape are stored inside the file: no script, no external dependency, no reference to UPTG.
- Metadata `terrain_data` on the root: `format_version`, `algorithm_version`, `generation_seed`, `config_checksum`, `heights_checksum`, `grid_cells_x`, `grid_cells_z`, `cell_size`, `sea_level`, `sea_floor_depth`, `heights`.
- The file is tied to the Godot version that wrote it. Bake again after an engine upgrade.

---

## 13. Performance

The Milestone D measurements **[VERIFIED MD]** are recorded in `documentation/TESTING.md` and are repeated with `tests/benchmark.gd`. They are valid only for the machine on which they were taken. The following are measured for 128 × 128, 256 × 256 and 512 × 512 cells:

- generation time of the height field, the mesh and the collision (separately);
- number of vertices and triangles;
- estimated memory of mesh and shape;
- collision build time in `HEIGHTMAP` and `TRIMESH`;
- frame time in the demo.

The `TRIMESH` measurement at 512 × 512 cells exceeds the trimesh `OK` threshold (section 5.4) and requires `allow_large_terrain = true` in the measurement scene.

Known risk: the per-vertex loop in GDScript is the most expensive part. The generator is pure precisely so that it can move to `WorkerThreadPool` in the future without being rewritten (out of scope for v0.1).

Known limit: a single mesh means that frustum culling applies to the whole terrain or to none of it.

---

## 14. Future extensibility (design only, not implemented)

| Future | How it fits without rewriting the core |
|---|---|
| Continental terrain, plains | New shape function in place of `shape_mask` (stage 2), selected by an enum in `UPTGConfig` |
| Hills and relief variants | New parameters or noise profiles in stage 3 |
| Mountain ranges | New region type (for example polyline-based) alongside `UPTGMountainRegion` |
| Survival or fantasy environments | Different `.tres` presets and materials; the core does not change |
| Roads, vegetation, world generation | Separate modules that read `UPTGTerrainData` |
| Erosion, lakes, rivers | Post-processing stages on the height field |
| Large worlds | Chunking and LOD built on top of `UPTGTerrainData`, threaded generation |
| Editor preview and baking | `UPTGTerrainData` may become a saveable `Resource`; `@tool` scripts |

---

## 15. Tests and acceptance criteria [APPROVED]

### 15.1 Infrastructure

- Headless tests with GDScript scripts run from the command line (`godot --headless --path <project> -s res://tests/run_tests.gd`) **[VERIFIED M0]**: the script extends `SceneTree`, physics works headless (rays and static bodies), `quit(n)` returns exit code `n` and a parse error returns 1. Headless rendering is a dummy: tests that read pixels require a window.
- Godot 4.7.2 generates a `.gd.uid` file next to each script: it must be committed together with the script **[VERIFIED M0]**.
- No external framework (for example GUT) in v0.1, so as not to introduce dependencies.
- The collision test requires a scene with active physics (`tests/collision/collision_test.tscn`).
- `documentation/TESTING.md` describes how to run each test and how to check the demo by hand.

### 15.2 v0.1 acceptance criteria

| # | Criterion | Verification |
|---|---|---|
| A1 | The project opens in Godot 4.7.2 without new errors or warnings from the addon | Manual |
| A2 | The demo starts on its own | Manual |
| A3 | A 3D island with a visibly irregular coastline is generated | Manual + screenshot |
| A4 | Hills and at least one mountain region are present | Manual |
| A5 | Validation rejects invalid configurations with clear messages | `test_validation.gd` |
| A5b | The protection of section 5.4 correctly classifies `OK`, `LARGE` and `REJECTED`; `LARGE` is refused without `allow_large_terrain`; `REJECTED` is always refused; a refusal does not alter the existing terrain | `test_validation.gd` (estimate only, without generating large terrains) |
| A6 | Valid mesh: indices within bounds, no NaN, unit normals, expected number of triangles | `test_mesh.gd` |
| A7 | Same seed and same configuration produce the same checksum; a different seed changes it; the `UPTGSeed` test vectors are respected | `test_determinism.gd`, `test_seed.gd` |
| A8 | Collision aligned with the mesh within the tolerance, in `HEIGHTMAP` and `TRIMESH` modes, on the default backend; result on the other backend documented | `collision_test` |
| A9 | `RigidBody3D` bodies dropped on a grid of points come to rest on the surface; a `CharacterBody3D` capsule walks across moderate slopes | `collision_test` + demo |
| A10 | 20 consecutive regenerations do not continuously increase the number of nodes or the memory | Test + demo monitor |
| A11 | The grid edge is always below `sea_level` | `test_determinism.gd` |
| A12 | The configuration saves and reloads as a `.tres` preset with an identical result | Test |
| A13 | The code in `addons/uptg/` does not reference paths outside the addon or specific games | Text search |
| A14 | No use of global RNG in the addon (`randi`, `randf`, `randomize`, `seed(`) | Text search |
| A15 | All new files are documented; no unrelated existing file was changed | Review |
| A16 | The measurements of section 13 are recorded in `TESTING.md` | Review |

---

## 16. Status of decisions

### 16.1 Approved decisions [APPROVED]

| # | Decision | Section |
|---|---|---|
| — | The 15 architectural decisions approved on 2026-11-06 (data contract, node, collision, grid, seed, determinism, formula, mountains, noise, mesh, materials, runtime only, portable addon, pure generator, tests) | 1–15 |
| D1 | R12 structure: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` inside `addons/uptg/`; general repository documents not changed now | 3 |
| D2 | "All rights reserved" license; no permissive license or public distribution | 3 |
| D3 | Initial tests on the default physics backend of Godot 4.7.2; documented verification on the other backend | 11.1 |
| D4 | No inland lakes in v0.1 | 8.6 |
| D6 | Initial alignment tolerance: 1 cm (to be confirmed, see 16.2) | 11.4 |
| D8 | The documentation in the repository is official; external copies are local references | 0 |
| D9 | Fundamental decisions have concise ADRs: ADR-0001 … ADR-0006 in `Documentation/architecture/decisions/` (created in Milestone 0) | 16.3 |
| — | Protection against expensive configurations | 5.4 |
| D10 | UPTG and its sub-programs are private tools; only their generated output goes into a game (ADR-0009) | 12.5 |

### 16.2 Experimental verifications

**Carried out in Milestone 0 [VERIFIED M0]** (details in `documentation/M0_VERIFICATION.md`):

| Topic | Result |
|---|---|
| Opening the project in 4.7.2 | Editor headless and with interface (Vulkan Forward+, Intel UHD 620): no errors, exit code 0 |
| Default physics backend | `DEFAULT`, which for this project corresponds to Godot Physics |
| Architecture APIs | All available and working (list in M0_VERIFICATION) |
| `FastNoiseLite` seed | 2 147 483 647 is preserved; 3 000 000 000 becomes -1 294 967 296: the 31-bit limit of section 5.1 is necessary |
| `derive()` function of section 7.2 | Results identical to independently computed values (4 test vectors) |
| D5: `map_data` order and centering | `iz * vx + ix`, centered on the origin, both backends |
| D5: diagonal | `(ix + 1, iz)`–`(ix, iz + 1)` in all cells, both backends, also on non-square grids |
| D5: winding | Front = clockwise as seen by the observer, rendering and physics |
| Uniform scale of `CollisionShape3D` | Works, both backends |
| D6: tolerance | 1 cm confirmed (maximum measured error 0.2 mm) |
| Other backend (Jolt) | Same behavior; numerical differences of about 0.1 mm |
| 32-bit indices | Intact beyond 65 535 vertices |
| Headless tests | They work, with a reliable exit code |

**Carried out in Milestone D [VERIFIED MD]** (details in `documentation/TESTING.md`): memory coefficients of section 5.4, measurements of section 13, collision A8 and A9 repeated on both backends after the tuning.

**Still to verify:**

| Topic | When | Action |
|---|---|---|
| Backend assigned by Godot to a project created by the Project Manager (UPTG's `project.godot` was written by hand) | If needed | Does not affect UPTG: both backends behave the same way |
| Cross-platform determinism | When a second platform is available | Document; it remains a goal, not a guarantee |

### 16.3 Deferred decisions [DEFERRED]

| Topic | Deferred to | Notes |
|---|---|---|
| D7: final values of the island preset | Carried out in Milestone D | Values of table 5.1 and of region 5.2 updated; preset `addons/uptg/presets/uptg_island_default.tres` |
| Alignment of `Documentation/architecture/README.md`, module README and module-level `presets/` folder with the R12 structure | Separate documentation update, to be approved | Until then this document prevails for UPTG |
| Time thresholds in seconds for the protection | Milestone D | After real measurements |
| Moving generation to threads | After v0.1 | Made possible by the pure generator |
| Editor preview, `@tool` | v0.2.0 or later | Out of scope for v0.1 |
| Modification of the terrain by future modules (for example roads) | UPRG design | `UPTGTerrainData` stays read-only in v0.1 |
| Permissive license or distribution | Only with an explicit decision by Stefano | D2 |

---

## 17. Implementation sequence

Each milestone starts only after Stefano's explicit approval and ends with a report: files created or changed, tests actually run, limits, proposal for the next milestone.

### Milestone 0 — Setup and API verification

- On a `uptg/milestone-0-setup` branch of the existing repository, create `project.godot` in `UPTG/UniversalProceduralTerrainGenerator/` and the folders according to decision D1; no change to existing documents without approval.
- Verify that the project opens in 4.7.2 and record the physics backend.
- A temporary script that verifies every API used by the project (`FastNoiseLite`, `ArrayMesh`, `HeightMapShape3D`, `ConcavePolygonShape3D`, exported `Array[Resource]`, raycast, headless execution). Deleted at the end.
- Experimental test on a 4 × 4 grid with known heights to determine D5 and confirm D6, first on the default backend and then on the other (D3).
- Write the concise ADRs planned by D9 (section 16.3), only after approval to start Milestone 0.
- Update the **[TO VERIFY]** parts of this document with the results.
- **Status:** completed on 2026-11-06 (results in `documentation/M0_VERIFICATION.md`).

### Milestone A — Data and height field (no scene)

- `UPTGConfig`, `UPTGMountainRegion`, validation, cost estimate and protection (5.4).
- `UPTGSeed` with test vectors.
- `UPTGTerrainData` with query methods.
- `UPTGHeightfieldGenerator`: mask, noise, mountains, formula.
- Tests: A5, A5b, A7, A11, A12.

### Milestone B — Mesh, node and demo

- `UPTGMeshBuilder`: geometry, normals, UVs, vertex colors, default material.
- `UPTGTerrain`: signals, child nodes, atomic regeneration.
- Demo: generation at startup, regenerate button, seed field, information panel (times, vertices, triangles), wireframe, water plane at `sea_level` (demo only).
- Tests: A2, A3, A4, A6, A10.

### Milestone C — Collision

- `UPTGCollisionBuilder`: `HEIGHTMAP`, `TRIMESH`, `NONE`.
- Test scene with raycasts, falling bodies and a capsule.
- Tests: A8, A9.

### Milestone D — Quality, measurements and documentation

- Tuning of the island preset after the demo (D7).
- Calibration of the memory coefficients and thresholds of section 5.4 with real measurements.
- Measurements of section 13 in `TESTING.md`.
- Addon README, TESTING, CHANGELOG; verification of A1, A13 – A16.
- Version `0.1.0`.
- **Status:** completed on 2026-11-06. Memory coefficients calibrated (5.4), thresholds unchanged, island preset tuned (5.1, 5.2, 10.5), measurements in `documentation/TESTING.md`.

---

## 18. Documentation and versions

- `UPTG_ARCHITECTURE.md` — Draft 0.1, kept unchanged.
- `UPTG_ARCHITECTURE_0.2.md` — this document, updated after Milestone 0.
- `addons/uptg/README.md` — how to use the addon in another project.
- `documentation/TESTING.md` — verification procedures and measurements.
- `CHANGELOG.md` — changes by version, including changes to `ALGORITHM_VERSION`.

Planned versions (provisional): `0.1.0` first working island generator; `0.2.0` improved controls, bake tool, possible editor preview; `1.0.0` stable module after testing and documentation.

---

## 19. Working protocol with Claude

Before each milestone: inspect the files, confirm the plan, wait for approval.
During: small milestones, syntax verification, running the demo and the tests when possible, no changes to unrelated files.
After: list of files created and changed, tests actually run, limits, proposal for the next milestone without starting it.

This document defines the architecture. It does not authorize implementations, destructive changes or out-of-scope systems.

---

## Appendix A — Changes from Draft 0.1

| Area | Draft 0.1 | Version 0.2 |
|---|---|---|
| Output | "return or expose the result" | `UPTGTerrainData` contract with defined fields and queries |
| Integration | Demo scene only | Reusable `UPTGTerrain` node |
| Class names | `UPTGGenerator`, `UPTGTerrainBuilder` | `UPTGHeightfieldGenerator` (pure), `UPTGMeshBuilder`; plus `UPTGSeed`, `UPTGMountainRegion` |
| Grid | `terrain_size_x/z` + `resolution_x/z` | `grid_cells_x/z` + `cell_size`, square cells, centered terrain |
| Collision | Trimesh | `HeightMapShape3D` by default, trimesh as alternative, `NONE` |
| Seed | `seed` with no mechanism | 31-bit `generation_seed`, sub-seeds with a documented function, local RNGs |
| Determinism | Generic requirement | Precise guarantee, `ALGORITHM_VERSION`, checksums |
| Formula | Listed components | Explicit formula, `sea_level`, `sea_floor_depth`, border guaranteed at sea |
| Mountains | List of properties | `UPTGMountainRegion` Resource, normalized coordinates, combination with `max` |
| Noise | Up to three layers | Two `FastNoiseLite` (fractal relief, coastline) |
| Materials | Generic grass/rock/sand | `StandardMaterial3D` with vertex colors |
| Editor | Not specified | Runtime only, no `@tool` or baking |
| Structure | `materials/` outside the addon, presets in demo | Self-contained addon, Godot project per module, `tests/` |
| Tests | Manual criteria, reference to a vehicle and to Nitro Underground | Automated tests, generic physics bodies, verifiable criteria |
| Sequence | Collision in Milestone C with a free grid | API verification Milestone 0; collision constraints fixed before the code |
| Text | Invisible characters in two class names | Removed |

---

## Appendix B — Document history

| Revision | Date | Changes |
|---|---|---|
| 0.2-r1 | 2026-11-06 | First draft in Italian with the 15 approved decisions |
| 0.2-r2 | 2026-11-06 | Incorporated D1–D9; added the protection against expensive configurations (5.4, A5b); section 16 split into approved, to verify, deferred; corrected the coastline radius/irregularity constraint and the default values of `island_radius`, the missing `sea_floor_depth` field in `UPTGTerrainData`, the definition of `config_checksum` and the type of `UPTGHeightfieldGenerator` |
| 0.2-r3 | 2026-11-06 | Milestone 0 results: added the [VERIFIED M0] label; recorded `map_data` order, centering, diagonal `(ix + 1, iz)`–`(ix, iz + 1)`, clockwise winding, uniform scale, 1 cm tolerance confirmed, default backend (Godot Physics), identical behavior of Jolt, 32-bit indices, headless tests and `.gd.uid` files. No architectural decision changed |
| 0.2-r4 | 2026-11-06 | During Milestone A: noise sampling offset derived from the seed (salts 4 and 5, sections 7.1, 8.2 and 8.3), approved by Stefano, because simplex noise is 0 at the origin and the center of the island stayed the same with every seed. `ALGORITHM_VERSION` stays 1, because the earlier formula was never released |
| 0.2-r5 | 2026-11-06 | Milestone D: island preset default values tuned (5.1, 5.2; D7); memory coefficients calibrated with real measurements, 48 bytes per cell for indices and 320 for the trimesh, thresholds unchanged (5.4); sand precedence over rock in vertex colors (10.5); section 13 measurements in `TESTING.md`; new [VERIFIED MD] label. No architectural decision changed |
| 0.2-r6 | 2026-11-08 | Decided by Stefano: UPTG is a private tool and only its output ships in a game (D10, ADR-0009); bake tool outside the addon (12.5, structure in 3). Generator, seed, mesh and collision unchanged |

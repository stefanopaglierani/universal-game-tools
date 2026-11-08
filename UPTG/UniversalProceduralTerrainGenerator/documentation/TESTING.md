**English** | [Italiano](TESTING.it.md)

# UPTG Testing

UPTG tests are plain GDScript files run headless by Godot 4.7.2. No test framework or plugin is needed.

## Running the tests

From the module folder (`UPTG/UniversalProceduralTerrainGenerator/`):

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

- The first command imports the project and registers the `class_name` scripts. It is only needed after adding or renaming scripts, or on a fresh clone (the `.godot/` cache is not in Git).
- `godot` is the Godot 4.7.2 executable. On Windows, use the `_console.exe` build so that the output and the exit code reach the terminal.
- The exit code is `0` when every check passes and `1` when at least one check fails or a script does not compile.

## Output

Each check prints one line:

- `PASS <name> | <detail>`: the check passed.
- `FAIL <name> | <detail>`: the check failed; the detail shows the value that was found.
- `INFO <name> | <detail>`: a measurement, not a check (for example timings).

The last line is `SUMMARY checks=<n> failures=<n>`.

Some tests feed invalid configurations on purpose. The generator and the node report them with `push_error`, so a run that passes still prints four `ERROR: UPTG: ...` lines: an invalid `cell_size` and a large configuration without `allow_large_terrain`, once from `test_validation.gd` and once from `test_terrain_node.gd`. They are expected, together with one `WARNING: UPTG: generate() called while a generation is running; ignored` from the re-entrancy check in `test_terrain_node.gd`.

## Test suites

| File | What it checks | Criteria |
|---|---|---|
| `tests/test_seed.gd` | `UPTGSeed.derive()` reference values, range, distinct sub-seeds | A7 |
| `tests/test_validation.gd` | `UPTGConfig.validate()` rejects each kind of invalid value; cost levels OK / LARGE / REJECTED and refusal without generating; the island preset `uptg_island_default.tres` loads, is valid and matches the defaults | A5, A5b |
| `tests/test_determinism.gd` | Same seed gives the same heights and checksums; border at the sea floor; height queries on the verified diagonal; resolution independence; `.tres` preset round trip; timings | A7, A11, A12 |
| `tests/test_mesh.gd` | `UPTGMeshBuilder`: vertex and triangle counts, index bounds, no NaN, unit normals, clockwise winding seen from +Y, shared diagonal, UVs, bounds, vertex colors | A6 |
| `tests/test_terrain_node.gd` | `UPTGTerrain`: children `UPTGMesh` and `UPTGBody/UPTGShape` without owner, default material, collision modes and layers, signals, statistics, world-space height query, failed generation keeps the previous terrain, 20 regenerations without growth in nodes, objects, resources or static memory, `generate()` called again from `generation_finished` is ignored | A5b, A10 |
| `tests/test_bake.gd` | Bake tool: self-contained `.scn` with no scripts or dependencies, mesh, material, collision and heights identical to the generator, refused inputs | ADR-0009 |

## Collision test

Collision needs running physics, so it is a scene rather than a suite:

```
godot --headless --path . --fixed-fps 60 res://tests/collision/collision_test.tscn
```

`--fixed-fps 60` runs one physics step per frame, so the test does not wait for real time. The output format and exit code are the same as for `run_tests.gd`. It checks:

- **A8:** 2000 vertical rays per case against `UPTGTerrainData.get_height_at()`, with tolerance 1 cm, in `HEIGHTMAP` and `TRIMESH`, on a square grid (128 × 128, cell 4 m) and a non-square one (96 × 48, cell 2.5 m), with the terrain node moved away from the origin; no collision outside the grid; no collision with `NONE`.
- **A9:** 25 spheres dropped on a grid of points come to rest on the surface (`HEIGHTMAP` and `TRIMESH`); a `CharacterBody3D` capsule walks 15 s up the mountain flank without sinking. A9 uses its own moderate terrain (base 6 m, hills 12 m, mountain 40 m), fixed in `collision_test.gd`: criterion A9 is about moderate slopes, and the test must not change when the island preset is tuned. A8 uses the default preset.

**Other physics backend.** The project uses the default backend (Godot Physics). To repeat the test with Jolt, create a temporary `override.cfg` in the module folder containing:

```
[physics]

3d/physics_engine="Jolt Physics"
```

run the scene again, then delete `override.cfg` (it must never be committed). The first output line shows the backend setting in use.

**Results on 2026-11-06, after the Milestone D tuning** (Godot 4.7.2, Windows, 15 checks, 0 failures on both backends):

| Check | Godot Physics (default) | Jolt |
|---|---|---|
| A8 max ray error, HEIGHTMAP 128 × 128 / 96 × 48 | 0.187 / 0.177 mm | 0.171 / 0.261 mm |
| A8 max ray error, TRIMESH 128 × 128 / 96 × 48 | 0.187 / 0.227 mm | 0.247 / 0.305 mm |
| A9 spheres: fell through, max gap, max final speed | 0, 28.5 mm, 0.061 m/s | 0, 38.3 mm, 0.000 m/s |
| A9 capsule: frames on floor, distance, steepest slope | 894/900, 64.4 m, 35.4° | 894/900, 64.4 m, 35.4° |

The sphere gap is measured from the surface below the center along the normal, so on curved ground it overestimates the real distance; it stays well below the 5 cm limit.

## Benchmark (architecture section 13)

`tests/benchmark.gd` measures generation time and memory. It is not a pass/fail test and is not part of `run_tests.gd`. Run it with a window, so that the GPU memory and the demo frame time can be measured:

```
godot --path . --resolution 1280x720 -s res://tests/benchmark.gd
```

Headless also works; GPU figures and the frame time are then reported as `n/a`. Times depend on the machine; the figures below are only a reference.

**Results on 2026-11-06** (Godot 4.7.2, Windows, Intel UHD Graphics 620 laptop, Vulkan Forward+, default island preset, `cell_size` 4 m):

| Cells | Vertices / triangles | Estimate HEIGHTMAP / TRIMESH | Height field | Mesh | Mesh GPU buffers | HEIGHTMAP build, memory | TRIMESH build, memory |
|---|---|---|---|---|---|---|---|
| 128 × 128 | 16 641 / 32 768 | 2.5 / 7.5 MB | 33 ms | 80 ms | 2.5 MB | 4.5 ms, 0.8 MB | 93 ms, 5.3 MB |
| 256 × 256 | 66 049 / 131 072 | 10.1 / 30.1 MB | 166 ms | 348 ms | 3.5 MB | 11 ms, 0.3 MB | 401 ms, 21.0 MB |
| 512 × 512 | 263 169 / 524 288 | 40.1 / 120.1 MB | 524 ms | 1303 ms | 14.0 MB | 46 ms, 1.0 MB | 1478 ms, 84.0 MB |

Demo frame time, 256 × 256 default preset, 300 frames, vsync off: **25.5 ms (39 fps)**. Adding a shape to the world and running one physics frame takes under 20 ms in every case.

How memory is measured: CPU memory is the growth of `Performance.MEMORY_STATIC` while the object is alive, GPU memory is the growth of `RENDERING_INFO_BUFFER_MEM_USED`. After the first size the engine reuses freed blocks, so small CPU figures (0.0 to 0.5 MB) mean "reused", not "free"; the TRIMESH and 512 × 512 figures are the reliable ones. The TRIMESH measure at 512 × 512 uses `allow_large_terrain = true`, because it is above the TRIMESH `OK` threshold.

**Calibration of the cost estimate (architecture 5.4).** The constants in `UPTGConfig` were set from these measurements:

- `BYTES_PER_VERTEX` stays **112**: height field and mask (8), CPU mesh arrays (48), GPU copy (48), collision heights (4). Measured GPU buffers are about 54 bytes per vertex, in line with the estimate.
- `BYTES_PER_CELL` goes from 24 to **48**: indices are held both on the CPU and on the GPU.
- `BYTES_PER_CELL_TRIMESH` goes from 72 to **320**: the measured `ConcavePolygonShape3D` costs about 84 MB at 512 × 512 cells (320 bytes per cell), including the physics engine's own structures.
- The thresholds (`MAX_CELLS_*`, `MAX_BYTES_*`) are unchanged. With the new coefficients the largest accepted case, 1024 × 1024 cells in TRIMESH, is estimated at about 480 MB, below the 512 MB hard limit, and 512 × 512 in HEIGHTMAP at about 40 MB, well within `OK`.

## Checking the demo by hand

Open the project in Godot 4.7.2 and run `res://demo/uptg_demo.tscn` (F6 with the scene open). Check that:

1. the demo starts on its own and shows an island surrounded by sea (A2, A3);
2. the coastline is irregular, with hills and a raised area around the mountain region (A3, A4);
3. **Regenerate** with a different seed, or **Random seed**, changes the island; the panel shows the cost estimate before generating, then the seed, grid, vertices, triangles, times and checksum;
4. **Wireframe** shows the triangle grid;
5. **Drop balls** drops 20 balls that land and stop on the terrain, including below the water (collision, A9);
6. dragging with the mouse orbits the camera and the wheel zooms.

The water plane, sky, light and camera belong to the demo only, not to the addon.

## Screenshots

Captures of the demo running in Godot 4.7.2 are in `documentation/screenshots/`. The folder contains a `.gdignore` file, so Godot does not import the images. The Milestone B and C images predate the preset tuning of Milestone D (heights up to about 47 m instead of about 88 m).

| File | Shows |
|---|---|
| [`milestone-d/preset_seed12345.png`](screenshots/milestone-d/preset_seed12345.png) | Tuned default preset, seed 12345 |
| [`milestone-d/preset_seed777.png`](screenshots/milestone-d/preset_seed777.png) | Tuned default preset, seed 777 |
| [`milestone-c/demo_balls.png`](screenshots/milestone-c/demo_balls.png) | **Drop balls**: balls resting on the terrain and under the water |
| [`milestone-b/demo_seed12345.png`](screenshots/milestone-b/demo_seed12345.png) | First island from the demo, seed 12345 |
| [`milestone-b/demo_seed777_close.png`](screenshots/milestone-b/demo_seed777_close.png) | Closer view, seed 777 |
| [`milestone-b/demo_wireframe.png`](screenshots/milestone-b/demo_wireframe.png) | **Wireframe** view of the triangle grid |

## Adding a suite

1. Create `tests/test_<topic>.gd` extending `RefCounted` with a `func run(t: Object) -> void`.
2. Inside `run`, call `t.check(name, condition, detail)` for each check and `t.info(name, detail)` for measurements.
3. Add the path to `SUITES` in `tests/run_tests.gd`.
4. Commit the script together with its `.gd.uid` file, which Godot creates on import.

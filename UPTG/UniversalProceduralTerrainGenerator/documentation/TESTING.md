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

Some tests feed invalid configurations on purpose. The generator and the node report them with `push_error`, so a run that passes still prints four `ERROR: UPTG: ...` lines: an invalid `cell_size` and a large configuration without `allow_large_terrain`, once from `test_validation.gd` and once from `test_terrain_node.gd`. They are expected.

## Test suites

| File | What it checks | Criteria |
|---|---|---|
| `tests/test_seed.gd` | `UPTGSeed.derive()` reference values, range, distinct sub-seeds | A7 |
| `tests/test_validation.gd` | `UPTGConfig.validate()` rejects each kind of invalid value; cost levels OK / LARGE / REJECTED and refusal without generating | A5, A5b |
| `tests/test_determinism.gd` | Same seed gives the same heights and checksums; border at the sea floor; height queries on the verified diagonal; resolution independence; `.tres` preset round trip; timings | A7, A11, A12 |
| `tests/test_mesh.gd` | `UPTGMeshBuilder`: vertex and triangle counts, index bounds, no NaN, unit normals, clockwise winding seen from +Y, shared diagonal, UVs, bounds, vertex colors | A6 |
| `tests/test_terrain_node.gd` | `UPTGTerrain`: children `UPTGMesh` and `UPTGBody/UPTGShape` without owner, default material, collision modes and layers, signals, statistics, world-space height query, failed generation keeps the previous terrain, 20 regenerations without growth in nodes, objects, resources or static memory | A5b, A10 |

## Collision test

Collision needs running physics, so it is a scene rather than a suite:

```
godot --headless --path . --fixed-fps 60 res://tests/collision/collision_test.tscn
```

`--fixed-fps 60` runs one physics step per frame, so the test does not wait for real time. The output format and exit code are the same as for `run_tests.gd`. It checks:

- **A8:** 2000 vertical rays per case against `UPTGTerrainData.get_height_at()`, with tolerance 1 cm, in `HEIGHTMAP` and `TRIMESH`, on a square grid (128 × 128, cell 4 m) and a non-square one (96 × 48, cell 2.5 m), with the terrain node moved away from the origin; no collision outside the grid; no collision with `NONE`.
- **A9:** 25 spheres dropped on a grid of points come to rest on the surface (`HEIGHTMAP` and `TRIMESH`); a `CharacterBody3D` capsule walks 15 s up the mountain flank without sinking.

**Other physics backend.** The project uses the default backend (Godot Physics). To repeat the test with Jolt, create a temporary `override.cfg` in the module folder containing:

```
[physics]

3d/physics_engine="Jolt Physics"
```

run the scene again, then delete `override.cfg` (it must never be committed). The first output line shows the backend setting in use.

**Results on 2026-11-06** (Godot 4.7.2, Windows, 15 checks, 0 failures on both backends):

| Check | Godot Physics (default) | Jolt |
|---|---|---|
| A8 max ray error, HEIGHTMAP 128 × 128 / 96 × 48 | 0.178 / 0.173 mm | 0.190 / 0.249 mm |
| A8 max ray error, TRIMESH 128 × 128 / 96 × 48 | 0.178 / 0.219 mm | 0.300 / 0.237 mm |
| A9 spheres: fell through, max gap, max final speed | 0, 28.5 mm, 0.061 m/s | 0, 38.3 mm, 0.000 m/s |
| A9 capsule: frames on floor, distance, steepest slope | 894/900, 64.4 m, 35.4° | 894/900, 64.4 m, 35.4° |

The sphere gap is measured from the surface below the center along the normal, so on curved ground it overestimates the real distance; it stays well below the 5 cm limit.

## Checking the demo by hand

Open the project in Godot 4.7.2 and run `res://demo/uptg_demo.tscn` (F6 with the scene open). Check that:

1. the demo starts on its own and shows an island surrounded by sea (A2, A3);
2. the coastline is irregular, with hills and a raised area around the mountain region (A3, A4);
3. **Regenerate** with a different seed, or **Random seed**, changes the island, and the panel shows the seed, grid, vertices, triangles, times and checksum;
4. **Wireframe** shows the triangle grid;
5. **Drop balls** drops 20 balls that land and stop on the terrain, including below the water (collision, A9);
6. dragging with the mouse orbits the camera and the wheel zooms.

The water plane, sky, light and camera belong to the demo only, not to the addon.

## Adding a suite

1. Create `tests/test_<topic>.gd` extending `RefCounted` with a `func run(t: Object) -> void`.
2. Inside `run`, call `t.check(name, condition, detail)` for each check and `t.info(name, detail)` for measurements.
3. Add the path to `SUITES` in `tests/run_tests.gd`.
4. Commit the script together with its `.gd.uid` file, which Godot creates on import.

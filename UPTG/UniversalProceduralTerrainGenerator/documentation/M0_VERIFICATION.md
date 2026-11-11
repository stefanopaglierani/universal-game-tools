# UPTG — Milestone 0 verification results

**Date:** 2026-11-06
**Branch:** `uptg/milestone-0-setup`
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf` (Windows, console build)
**GPU used for rendering tests:** Intel(R) UHD Graphics 620, Vulkan 1.3.215, Forward+

Every result below comes from a test that was actually run. The temporary test scripts (`tests/m0/`) and the temporary `override.cfg` were deleted after the run, as planned; this file is the record of what they did and what they returned.

## How the tests were run

| Run | Command (from the module folder) |
|---|---|
| Project import | `godot --headless --editor --quit --path .` |
| Editor with GUI | `godot --editor --quit --path .` |
| Physics and API tests | `godot --headless --path . -s res://tests/m0/m0_tests.gd` |
| Other physics backend | same as above, with a temporary `override.cfg` setting `physics/3d/physics_engine` to `GodotPhysics3D`, then `Jolt Physics` |
| Rendering tests | `godot --path . -s res://tests/m0/m0_render.gd` (opens a window for about a second) |
| Exit-code probe | `godot --headless --path . -s <script>` with `quit(3)` and with a script containing a parse error |

## Results

| # | Check | Result | Status |
|---|---|---|---|
| T1 | Project opens in 4.7.2 | Headless import and GUI editor both exit with code 0, no errors or warnings. `project.godot` is not rewritten by the editor | PASS |
| T2 | Physics backend actually used | Setting `physics/3d/physics_engine` = `DEFAULT`. Ray hit values are bit-identical to a run forced to `GodotPhysics3D` and differ from a run forced to `Jolt Physics`, so the default backend for this project is **Godot Physics**. `PhysicsServer3D.get_class()` returns `PhysicsServer3D` with both backends and cannot identify them | Recorded |
| T3 | API availability | `FastNoiseLite` (Simplex Smooth, FBM, octaves, lacunarity, gain, frequency), repeatable output, seed changes output; `ArrayMesh.add_surface_from_arrays` with vertex, normal, UV, color and index arrays; `StandardMaterial3D.vertex_color_use_as_albedo`; custom `Resource` with `class_name`, `@export_group`, `@export_range`, enum export and `Array[Resource]` export saved to `.tres` and reloaded with identical values; `HeightMapShape3D` properties; `ConcavePolygonShape3D.set_faces` and `backface_collision`; `PhysicsRayQueryParameters3D.create`; `var_to_bytes`; `PackedFloat32Array.to_byte_array`; `Time.get_ticks_usec` | PASS |
| T3 | `FastNoiseLite` seed range | `2147483647` is kept. `3000000000` reads back as `-1294967296` (32-bit wrap), confirming the 31-bit limit on `generation_seed` | Recorded |
| T3 | FBM output range | 4 octaves, 20 000 samples: observed range [-0.7513, 0.6827] | Recorded |
| T3 | Seed derivation (architecture 7.2) | GDScript results match 4 vectors computed independently: `derive(0,1)=33350994`, `derive(12345,1)=1868776673`, `derive(12345,2)=1162198605`, `derive(2147483647,3)=2090469116` | PASS |
| T4 | `map_data` order and centering | 4×4 planar map `h = ix + 10·iz`, 25 rays: max error 0.085 mm for "row-major `iz*w+ix`, centered on origin"; 23.4 m for the transposed order; 16.5 m for a corner origin. No hit outside the map | PASS |
| T5 | Triangle diagonal | Checkerboard 4×4 map: all 9 cells split along the diagonal from vertex `(ix+1, iz)` to `(ix, iz+1)`; 36/36 off-center probes match it, 0/36 match the other diagonal | PASS |
| T6 | Uniform scale | T4 and T5 repeated with `cell_size = 4` (heights divided by 4, `CollisionShape3D` scaled by 4): identical results | PASS |
| T7a | Winding, physics | `ConcavePolygonShape3D`, `backface_collision = false`: a triangle that is clockwise seen from above is hit from above and not from below; the counter-clockwise one is hit only from below | Recorded |
| T7b | Winding, rendering | Default `CULL_BACK`: the triangle that is clockwise on screen is drawn, the counter-clockwise one is culled; with culling disabled the triangle is drawn (sanity check) | PASS |
| T8 | Collision vs. triangle interpolation | 64×64 cells, `cell_size = 4`, noise heights, 2000 rays. `HEIGHTMAP`: 0.187 mm max error with the T5 diagonal, 316 mm with the other one. `TRIMESH` built with each diagonal: ≤ 0.202 mm against its own diagonal. No misses | PASS |
| T9 | Headless test execution | `-s` scripts extending `SceneTree` run headless, physics works headless, `quit(3)` gives exit code 3, a parse error gives exit code 1 | PASS |
| T10 | 32-bit indices | 300×300 vertices (90 000), 536 406 indices: all indices read back, max index 89 999, correct AABB; headless and Forward+ | PASS |
| T11 | Other backend (Jolt) | T4–T8 repeated with `Jolt Physics`: same order, centering, diagonal, winding and scale behavior. Errors: 0.134 mm (T4), 0.153 mm (`HEIGHTMAP`, T8), ≤ 0.169 mm (`TRIMESH`, T8). `GodotPhysics3D` forced explicitly gives the same values as `DEFAULT` | PASS |
| T12 | Non-square heightmaps (added during the final review) | 7×4, 4×9 and 65×33 vertices, `cell_size = 4`, 1500 random rays each, compared with the T5 diagonal: max error 0.166 mm (Godot Physics) and 0.221 mm (Jolt), no misses | PASS |

## Other findings

- Godot 4.7.2 creates a `.gd.uid` file next to every script. These files must be committed together with their scripts.
- In headless mode rendering is a dummy backend: tests that read pixels need a window.
- The `.godot/` cache is created on first open and is already excluded by `.gitignore`. After the temporary scripts were deleted, the project was re-imported and the global class cache no longer lists the temporary classes.

## Not verified

- Which backend the Godot Project Manager writes into a *new* project: the UPTG `project.godot` was written by hand, so it uses `DEFAULT`. This does not affect UPTG, since both backends behave the same in every test above.
- Cross-platform determinism (only one machine available).

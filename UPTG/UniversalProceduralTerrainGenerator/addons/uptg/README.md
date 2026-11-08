**English** | [Italiano](README.it.md)

# UPTG addon (`addons/uptg/`)

UPTG (Universal Procedural Terrain Generator) generates a deterministic 3D island at runtime in Godot 4.7.2: height field, mesh with vertex colors, and collision. It is written in typed GDScript, has no dependencies and does not reference any game.

Version: **0.1.0** (`ALGORITHM_VERSION` 1). License: all rights reserved, see `LICENSE`.

UPTG is a private development tool: to put a world in a game, bake it with `tools/uptg_bake.gd` (see the module README and ADR-0009). The steps below are for working with the generator in a tool project, not for shipping it.

## Install

1. Copy the whole `addons/uptg/` folder into the `addons/` folder of your Godot 4.7.2 project, keeping the path `res://addons/uptg/`.
2. Open the project once in the editor (or run `godot --headless --editor --quit`) so that Godot registers the `UPTG*` classes.

UPTG is not an editor plugin: there is nothing to enable in **Project Settings > Plugins**.

## Quick start

1. Add a `UPTGTerrain` node to a 3D scene.
2. In the Inspector, set **Config** to `res://addons/uptg/presets/uptg_island_default.tres`, or create a new `UPTGConfig` resource.
3. Run the scene. With **Generate On Ready** enabled, the island is generated when the node enters the tree.

From code:

```gdscript
var terrain := UPTGTerrain.new()
terrain.config = (load("res://addons/uptg/presets/uptg_island_default.tres") as UPTGConfig).duplicate(true)
terrain.config.generation_seed = 777
terrain.generation_finished.connect(func(data: UPTGTerrainData) -> void:
	print("island ready, checksum ", data.heights_checksum))
terrain.generation_failed.connect(func(message: String) -> void:
	push_warning(message))
add_child(terrain)  # generates in _ready()
```

Use `duplicate(true)` before changing a preset at runtime: the `.tres` file is a shared resource, and its mountain regions are sub-resources.

To regenerate, change the config and call `terrain.generate()`. It returns `true` on success. Generation is synchronous: call it on an explicit action (a button, a level load), not every frame and not from physics callbacks.

## The `UPTGTerrain` node

| Member | Description |
|---|---|
| `config: UPTGConfig` | Parameters to generate. Required. |
| `generate_on_ready: bool` | Generates in `_ready()`. Default `true`. |
| `material_override: Material` | Material for the terrain; when empty, the default vertex-color material is used. |
| `allow_large_terrain: bool` | Allows configurations whose cost level is `LARGE` (see below). Default `false`. |
| `collision_layer`, `collision_mask` | Physics layers of the terrain body. |
| `generate() -> bool` | Validates, generates and replaces the terrain. On failure the previous terrain is kept. A call made while a generation is running is ignored with a warning. |
| `clear()` | Removes the generated mesh and collision. |
| `get_terrain_data() -> UPTGTerrainData` | Last successful result, or `null`. |
| `get_height_at_world(pos: Vector3) -> float` | Terrain height under a world position, or `NAN` before the first generation. |
| `get_last_stats() -> Dictionary` | Times per phase in microseconds (`heightfield_us`, `mesh_us`, `collision_us`, `apply_us`, `total_us`), `vertices`, `triangles`, `estimated_bytes`, `cost_level`, `collision_mode`. |
| `generation_started`, `generation_finished(data)`, `generation_failed(message)` | Signals. |

The node creates its children on the first generation: `UPTGMesh` (`MeshInstance3D`) and `UPTGBody` (`StaticBody3D`) with `UPTGShape` (`CollisionShape3D`). They have no owner, so they are never saved in the scene. Do not add or remove them yourself.

The terrain is centered on the node: it covers `grid_cells_x * cell_size` by `grid_cells_z * cell_size` meters around the node origin. Moving or rotating the node around Y is supported; tilting it is not.

## Main parameters (`UPTGConfig`)

| Group | Parameters |
|---|---|
| Seed | `generation_seed` (0 – 2 147 483 647). The same seed and configuration always give the same terrain. |
| Grid | `grid_cells_x`, `grid_cells_z` (2 – 1024), `cell_size` in meters. |
| Sea | `sea_level`, `sea_floor_depth`. The border of the grid is always under the sea. |
| Island | `island_radius`, `coastline_irregularity`, `coastline_noise_frequency`, `coastline_falloff_width`. |
| Relief | `land_base_height`, `min_land_height`, `terrain_noise_frequency`, `terrain_noise_amplitude`, `noise_octaves`, `noise_lacunarity`, `noise_gain`. |
| Mountains | `mountain_regions`: up to 16 `UPTGMountainRegion` (`center` and `radius` normalized, `peak_height` in meters, `falloff`). |
| Collision | `collision_mode`: `HEIGHTMAP` (default, cheapest), `TRIMESH` or `NONE`. |
| Appearance | `uv_tile_size`, `sand_color`, `grass_color`, `rock_color`, `beach_height`, `rock_slope_degrees`, `rock_height`. |

Frequencies are in world units: if you keep the same size in meters (`grid_cells * cell_size`) and change the number of cells, only the resolution changes, not the shape of the island. The full list, with ranges and defaults, is in section 5 of `documentation/UPTG_ARCHITECTURE_0.2.md`.

`config.validate()` returns the list of errors (empty when valid); `generate()` refuses an invalid configuration and emits `generation_failed` with the messages.

## Cost protection

Before generating, `config.estimate_cost()` estimates cells, vertices and memory, and gives a level:

- `OK`: up to 512 × 512 cells (256 × 256 with `TRIMESH`) and 128 MB: generated normally.
- `LARGE`: up to 1024 × 1024 cells and 512 MB: refused unless the node has `allow_large_terrain = true`, then generated with a warning.
- `REJECTED`: anything bigger: always refused.

`allow_large_terrain` is on the node, not in the config, so a shared preset cannot bypass the protection. As a reference, on a laptop with an Intel UHD 620, 256 × 256 cells take about 0.5 s and 512 × 512 cells about 1.9 s with `HEIGHTMAP` collision (measurements in `documentation/TESTING.md`).

## Reading the terrain from code

`UPTGTerrainData` (from `get_terrain_data()` or `generation_finished`) holds the result in the node's local space:

- `get_height_at(x, z)`, `get_normal_at(x, z)`, `get_mask_at(x, z)`, `is_land_at(x, z)`, `is_inside(x, z)`;
- `heights`, `land_mask`, `min_height`, `max_height`, `size`, `cell_size`, grid sizes;
- `generation_seed`, `config_checksum`, `heights_checksum`, `ALGORITHM_VERSION`.

Use it to place objects, spawn points or water without depending on the mesh. Treat it as read-only.

## Limits of v0.1

- Generation runs on the main thread and is not split into chunks: one mesh, one collision shape.
- Runtime only: nothing is generated in the editor viewport.
- No lakes, rivers, caves or erosion; color comes from vertex colors (no textures or custom shader).
- Determinism is guaranteed on the same platform and Godot version; cross-platform results are a goal, not a guarantee.

## Demo and tests

These are in the module project, not in the addon: `demo/uptg_demo.tscn` shows the generator with seed controls, wireframe and falling balls; `documentation/TESTING.md` explains how to run the tests and the benchmark.

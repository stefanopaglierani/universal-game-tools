# UPTG — Universal Procedural Terrain Generator
## Architecture Specification — Draft 0.1

**Status:** Architecture proposal — not yet implemented  
**Project:** Universal Game Tools  
**Target engine:** Godot 4.7.2  
**Primary language:** GDScript  
**Owner:** Stefano  
**Purpose:** Define a reusable terrain-generation module that can be integrated into multiple independent Godot games.

---

## 1. Purpose and scope

UPTG is a reusable tool for generating and previewing terrain in Godot. Its first milestone is a deterministic, configurable island generator suitable for a compact 3D game world.

The core must remain game-agnostic. It must not contain racing, zombie-survival, RPG, quest, vehicle, or other game-specific logic.

### Initial capabilities (v0.1)

- Generate a terrain mesh from configurable parameters.
- Generate an irregular island footprint and coastline.
- Generate hills, plains, and one or more configurable mountain regions.
- Generate valid mesh normals and UV coordinates.
- Generate terrain collision for static-world use.
- Support deterministic generation from a seed.
- Regenerate only on explicit request or scene initialization—not every frame.
- Provide a standalone demo/test scene.
- Expose configuration through a Godot Resource.
- Document limitations and testing instructions.

### Explicitly out of scope for v0.1

- Roads, paths, bridges, or race routes.
- Buildings, vegetation placement, props, or settlements.
- Biome painting or advanced material blending.
- Runtime destruction or deformable terrain.
- Infinite terrain, streaming, or large-world chunk management.
- Gameplay, AI navigation, vehicle logic, race events, or survival systems.
- A polished custom editor dock.
- Automatic export/import between projects.

These may become separate modules or later UPTG versions.

---

## 2. Design principles

1. **Reusable:** Core code is independent of any game.
2. **Deterministic:** Same configuration and seed produce the same terrain.
3. **Modular:** Configuration, generation, mesh construction, collision, and preview responsibilities are separated.
4. **Inspectable:** Generated output and settings can be understood and debugged in Godot.
5. **Incremental:** Build a working small prototype before adding advanced features.
6. **Safe:** Do not modify unrelated project files or existing game systems.
7. **Measured:** Performance claims must be tested, not assumed.
8. **Version-compatible:** Use APIs available in Godot 4.7.2 and verify syntax against that version.
9. **Portable:** The module should eventually be distributable as a Godot addon or copied into another project with documented steps.

---

## 3. Proposed module layout

The exact layout must be reconciled with the actual Universal Game Tools repository before implementation.

```text
UPTG/
└── UniversalProceduralTerrainGenerator/
    ├── addons/
    │   └── uptg/
    │       ├── runtime/
    │       │   ├── uptg_generator.gd
    │       │   ├── uptg_terrain_builder.gd
    │       │   └── uptg_collision_builder.gd
    │       ├── resources/
    │       │   └── uptg_config.gd
    │       └── README.md
    ├── demo/
    │   ├── scenes/
    │   │   └── uptg_demo.tscn
    │   ├── scripts/
    │   │   └── uptg_demo_controller.gd
    │   └── resources/
    │       └── island_default.tres
    ├── materials/
    │   └── terrain/
    ├── documentation/
    │   ├── UPTG_ARCHITECTURE.md
    │   └── TESTING.md
    └── CHANGELOG.md
```

Do not create empty future modules such as road or world generators unless there is a concrete need.

---

## 4. Responsibilities and architecture

### 4.1 `UPTGConfig` — configuration Resource

A custom `Resource` stores all parameters required to generate terrain. Configuration must not be hard-coded into the generator.

Proposed properties:

- `seed`
- `terrain_size_x`
- `terrain_size_z`
- `resolution_x`
- `resolution_z`
- `base_height`
- `terrain_noise_frequency`
- `terrain_noise_amplitude`
- `noise_octaves`
- `coastline_irregularity`
- `coastline_noise_frequency`
- `coastline_falloff_width`
- `mountain_regions` (initially optional/simple; define only if implementation remains manageable)

Use exported properties with sensible ranges and tooltips where practical.

The configuration should be serializable as `.tres` presets.

### 4.2 `UPTGGenerator` — orchestration

Responsibilities:

- Receive a valid `UPTGConfig`.
- Initialize deterministic noise generators.
- Generate a height field and island mask.
- Pass data to the mesh builder.
- Request collision creation when enabled.
- Return or expose the generated terrain result.
- Report errors clearly.

It should not own game-specific logic or perform work every frame.

### 4.3 `UPTGTerrainBuilder` — mesh creation

Responsibilities:

- Convert a height field into vertices and triangle indices.
- Generate UVs.
- Generate normals.
- Create and return an `ArrayMesh` or equivalent mesh resource.
- Validate dimensions and avoid invalid indices.

Prefer efficient indexed geometry over unnecessarily duplicating every triangle vertex, where practical and maintainable.

### 4.4 `UPTGC​​ollisionBuilder` — collision

Responsibilities:

- Create a collision representation from generated terrain.
- Support static terrain use.
- Keep collision creation separate from mesh generation.
- Avoid creating duplicate collision nodes during regeneration.
- Document collision limitations and performance.

For v0.1, a static concave trimesh collision may be acceptable for a prototype. It must be attached to a static physics body and must not be used as a dynamic body's collision shape.

### 4.5 Demo controller

The demo scene should make the module easy to inspect.

At minimum:

- load a configuration preset;
- generate terrain at startup;
- provide an explicit regeneration action;
- allow changing the seed;
- show basic generation/debug information;
- make terrain collision inspectable.

A full custom editor plugin is not required for v0.1.

---

## 5. Terrain generation algorithm

### 5.1 Height-field approach

The initial generator uses a finite two-dimensional grid.

For each grid sample:

1. Convert grid coordinates into normalized coordinates.
2. Convert normalized coordinates into terrain-space coordinates.
3. Calculate an island mask.
4. Calculate terrain noise.
5. Calculate mountain contribution.
6. Combine components into final height.
7. Store the height in a height-field array.
8. Build mesh triangles from neighboring samples.

The height field must be generated once per explicit generation operation.

### 5.2 Island mask and coastline

The island footprint should not be limited to a perfect circle.

Recommended approach:

- Start from an elliptical or radial base footprint.
- Perturb the boundary using seeded low-frequency noise.
- Apply a smooth falloff near the coast.
- Avoid abrupt vertical walls or jagged artifacts.
- Ensure the outer boundary reaches sea level or a defined shoreline elevation.

The implementation must be numerically stable and configurable.

### 5.3 Terrain noise

Use `FastNoiseLite`, available in Godot.

Potential layers:

- low-frequency noise for broad hills;
- medium-frequency noise for terrain variation;
- optional higher-frequency noise for small detail.

Keep the first implementation restrained. Excessive noise creates terrain that is difficult to drive across and unsuitable for roads.

### 5.4 Mountain regions

Mountains should be generated from configurable influence regions rather than relying only on random noise.

For the initial prototype, one or a few simple mountain centers may be sufficient.

Each region can define:

- center;
- influence radius;
- peak height;
- falloff.

The final terrain must retain usable lowlands and flatter areas for future roads and buildings.

### 5.5 Determinism

All procedural randomness must derive from the configured seed.

Requirements:

- same seed + same configuration = same result;
- different seed = a different result with high probability;
- no dependence on frame timing or uncontrolled global randomness.

Document any source of nondeterminism if unavoidable.

---

## 6. Mesh, normals, UVs, and materials

### Mesh

The terrain mesh must:

- use valid triangle winding;
- have no invalid or degenerate indices;
- cover the intended island footprint;
- provide consistent surface normals;
- support a basic material;
- be inspectable in wireframe/debug mode.

### UVs

UV coordinates should map consistently across the terrain. The initial mapping may be simple planar mapping; document limitations.

### Materials

For v0.1, use simple materials only:

- grass/land;
- rock (optional basic height-based distinction);
- sand/coast (optional).

Do not build a complex biome shader yet.

The generator should not depend on a racing or fantasy visual style.

---

## 7. Collision and physics

The terrain must be physically traversable.

Acceptance requirements:

- collision covers the generated land surface;
- no duplicate collision bodies after regeneration;
- collision updates when terrain is regenerated;
- collision is compatible with static terrain;
- demo scene can verify collision with a simple test object or the existing vehicle, if safely available.

If integrating an existing vehicle, inspect its scene and controller first. Do not change vehicle physics or input mappings as part of UPTG.

---

## 8. Scene architecture

Proposed standalone demo scene:

```text
UPTGD​​emo (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── TerrainRoot (Node3D)
│   ├── TerrainMesh (MeshInstance3D)
│   └── TerrainBody (StaticBody3D)
│       └── TerrainCollision (CollisionShape3D)
├── Water (optional simple placeholder)
├── Camera3D
├── Debug
└── DemoController
```

The generated terrain should be replaceable without rebuilding unrelated scene nodes.

---

## 9. Performance and scale

Initial testing parameters may use a terrain footprint around 1200 × 1200 world units with a moderate grid resolution.

These values are provisional—not final game-world dimensions.

The developer must:

- measure generation time;
- measure mesh size and triangle count;
- inspect collision creation cost;
- test editor responsiveness;
- avoid generating terrain every frame;
- avoid unnecessary geometry density.

Do not claim mobile performance is acceptable without testing on a target device.

Future optimization options may include:

- chunking;
- level of detail;
- reduced collision resolution;
- distance-based rendering;
- optimized material/shader complexity.

These are not required for v0.1.

---

## 10. Error handling and regeneration

The generator should validate configuration before generation.

Examples:

- resolution below minimum;
- invalid or zero terrain dimensions;
- invalid noise parameters;
- missing configuration resource;
- failed mesh construction.

Regeneration must clean up or replace previous generated resources safely.

The demo should display useful error messages rather than silently failing.

---

## 11. Testing and acceptance criteria

UPTG v0.1 is accepted only if:

1. The project opens in Godot 4.7.2 without new errors.
2. The demo scene launches independently.
3. A 3D island is generated.
4. Coastline is visibly irregular.
5. Terrain includes hills and at least one elevated region.
6. The generated mesh has valid normals and triangles.
7. Terrain collision is functional.
8. A test object can interact with the terrain physically.
9. Regeneration works without duplicate nodes or resources.
10. Identical seeds reproduce identical terrain.
11. Changing the seed changes terrain.
12. Configuration can be saved and loaded as a Resource preset.
13. The generator does not depend on Nitro Underground files.
14. All new files are documented.
15. No unrelated project systems have been modified.

---

## 12. Development sequence

Implement incrementally:

### Milestone A — Minimal terrain

- Config Resource.
- Seeded height field.
- Basic island mask.
- Mesh generation.
- Standalone demo.

### Milestone B — Island shape

- Irregular coastline.
- Smooth coastal falloff.
- Terrain noise.
- Basic mountain region.

### Milestone C — Physics

- Terrain collision.
- Collision regeneration.
- Physical test.

### Milestone D — Quality

- Basic materials.
- UV validation.
- Debug information.
- Generation measurements.

Do not implement future road, vegetation, or world-generation modules during these milestones.

---

## 13. Documentation and versioning

Maintain:

- `UPTG_ARCHITECTURE.md` — architecture and technical decisions.
- `README.md` — how to use the module.
- `TESTING.md` — verification procedures.
- `CHANGELOG.md` — changes by version.

Versioning:

- `0.1.0` — first working procedural island generator.
- `0.2.0` — improved terrain controls and visual quality.
- `0.3.0` — preset/biome improvements, if approved.
- `1.0.0` — stable reusable module after testing and documentation.

These version targets are provisional.

---

## 14. Claude implementation protocol

Before coding:

1. Inspect the repository and existing conventions.
2. Confirm Godot version and project configuration.
3. Identify any conflicts with the proposed layout.
4. Report the implementation plan.
5. Wait for approval if changes affect existing files or architecture.

During implementation:

- work in small milestones;
- validate GDScript syntax;
- run the demo when possible;
- preserve existing files;
- report failures honestly.

After implementation:

- list files created and modified;
- explain how to launch the demo;
- report tests actually performed;
- document limitations;
- propose the next milestone without automatically starting it.

**This document defines architecture. It does not authorize destructive changes or implementation of out-of-scope systems.**

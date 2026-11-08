**English** | [Italiano](README.it.md)

# Universal Game Tools

A personal collection of reusable, modular and documented game development tools, procedural generators and systems built with **Godot 4.7.2**, **GDScript**, **Blender** and AI-assisted workflows.

The tools are game-agnostic: each one is designed so it can be copied into, or installed as an addon in, an independent Godot project. None of them depends on a specific game.

## Status

| Module | Name | Status |
|---|---|---|
| [UPTG](UPTG/UniversalProceduralTerrainGenerator/) | Universal Procedural Terrain Generator | Version 0.1.0 released (tag `uptg-v0.1.0`): procedural island generator with mesh, collision and demo |
| [UPRG](UPRG/UniversalProceduralRoadGenerator/) | Universal Procedural Road Generator | Planned, not started |
| [UPWG](UPWG/UniversalProceduralWorldGenerator/) | Universal Procedural World Generator | Planned, not started |

Current priority is **UPTG**. Other modules will not start until the first generator has been tested and approved.

## Repository layout

```text
universal-game-tools/
├── README.md                 This file
├── CHANGELOG.md              Repository-level changes
├── LICENSE
├── UPTG/
│   └── UniversalProceduralTerrainGenerator/
│       ├── project.godot     Standalone Godot project for the module
│       ├── addons/uptg/      Portable addon: core, builders, nodes, materials, presets
│       ├── demo/             Standalone demo scene
│       ├── tests/            Headless test suites, collision test, benchmark
│       ├── presets/          Reserved, empty in v0.1 (the preset is in addons/uptg/presets/)
│       ├── documentation/    Architecture, testing, verification, screenshots
│       ├── CHANGELOG.md      Module changes
│       └── README.md
├── UPRG/
│   └── UniversalProceduralRoadGenerator/    (placeholder)
├── UPWG/
│   └── UniversalProceduralWorldGenerator/   (placeholder)
└── Documentation/
    ├── architecture/         Cross-module architecture and decisions
    └── development/          Project instructions, workflow, conventions
```

Each tool should contain: core implementation, configuration resources, optional editor integration, a demo scene, documentation, test procedures and version information.

## Development environment

- Godot 4.7.2 (GDScript)
- Blender
- Claude Desktop / Cowork
- Git and GitHub
- Windows

## Documentation

- [Project instructions](Documentation/development/PROJECT_INSTRUCTIONS.md): identity, principles and AI workflow
- [Development workflow](Documentation/development/WORKFLOW.md): branching, commits, versioning
- [Architecture overview](Documentation/architecture/README.md): shared conventions across modules
- [UPTG architecture 0.2](UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md) ([draft 0.1](UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md) is kept as a historical reference)
- [UPTG addon guide](UPTG/UniversalProceduralTerrainGenerator/addons/uptg/README.md): installation and usage
- [UPTG testing](UPTG/UniversalProceduralTerrainGenerator/documentation/TESTING.md): test suites, benchmark, manual checks

## Development principles

1. Reusability before game-specific customization.
2. Modular architecture.
3. Clear separation between core systems and optional extensions.
4. Compatibility with Godot 4.7.2.
5. Documentation for every completed tool.
6. Incremental development and testing.
7. Preserve working code and existing files.
8. Never overwrite important files without approval.
9. Never assume a feature works without verification.
10. Prefer simple, maintainable solutions over unnecessary complexity.

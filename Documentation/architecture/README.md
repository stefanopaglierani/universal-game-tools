**English** | [Italiano](README.it.md)

# Architecture overview

Shared architecture rules that apply to every module in Universal Game Tools.

## Module anatomy

Each tool lives in `<CODE>/<FullName>/` and should ideally contain:

- **Core implementation**: runtime code under `addons/<code>/`, split by responsibility (UPTG: `core/`, `builders/`, `nodes/`, `materials/`)
- **Configuration resources**: custom `Resource` scripts inside the addon (UPTG: `core/`), presets as `.tres` in `addons/<code>/presets/`
- **Optional editor integration**: kept separate from runtime code
- **Demo scene**: standalone, runnable without other modules
- **Documentation**: architecture, usage, testing
- **Test procedures**: `documentation/TESTING.md`, automated suites in `tests/`
- **Version information**: module `CHANGELOG.md` with semantic versions

## Rules

- Modules are game-agnostic: no gameplay, vehicle, quest or game-specific logic in the core.
- A module must be transferable to an independent Godot project with documented steps.
- Modules are private development tools: only what they generate goes into a game, never their code (ADR-0009).
- Core systems and optional extensions are clearly separated.
- Dependencies between modules are one-directional and documented (e.g. UPRG may depend on UPTG output, never the reverse).
- Generation is deterministic from a seed where randomness is involved.

## Modules

| Module | Architecture doc |
|---|---|
| UPTG | [UPTG_ARCHITECTURE_0.2.md](../../UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md); it supersedes [draft 0.1](../../UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md) |
| UPRG | Not written yet |
| UPWG | Not written yet |

## Decisions

Significant architectural decisions are recorded as ADRs in [`decisions/`](decisions/), using the [template](decisions/ADR-0000-template.md).

- [ADR-0001: UPTG terrain data contract (`UPTGTerrainData`)](decisions/ADR-0001-uptg-terrain-data-contract.md)
- [ADR-0002: UPTG collision: `HeightMapShape3D` by default](decisions/ADR-0002-uptg-heightmap-collision.md)
- [ADR-0003: UPTG grid: square cells defined by cell count and `cell_size`](decisions/ADR-0003-uptg-square-cell-grid.md)
- [ADR-0004: UPTG seed handling and determinism guarantee](decisions/ADR-0004-uptg-seed-and-determinism.md)
- [ADR-0005: UPTG addon layout (R12)](decisions/ADR-0005-uptg-addon-layout.md)
- [ADR-0006: UPTG protection against expensive configurations](decisions/ADR-0006-uptg-cost-protection.md)
- [ADR-0007: UPTG noise sampling offsets derived from the seed](decisions/ADR-0007-uptg-seed-derived-noise-offsets.md)
- [ADR-0008: UPTG cost estimate calibration from measurements](decisions/ADR-0008-uptg-cost-calibration.md)
- [ADR-0009: UPTG is a private tool, only its baked output goes into a game](decisions/ADR-0009-uptg-tool-only-baked-output.md)

**English** | [Italiano](README.it.md)

# Architecture overview

Shared architecture rules that apply to every module in Universal Game Tools.

## Module anatomy

Each tool lives in `<CODE>/<FullName>/` and should ideally contain:

- **Core implementation**: runtime code under `addons/<code>/runtime/`
- **Configuration resources**: custom `Resource` scripts under `addons/<code>/resources/`, presets as `.tres`
- **Optional editor integration**: kept separate from runtime code
- **Demo scene**: standalone, runnable without other modules
- **Documentation**: architecture, usage, testing
- **Test procedures**: `documentation/TESTING.md`
- **Version information**: module `CHANGELOG.md` with semantic versions

## Rules

- Modules are game-agnostic: no gameplay, vehicle, quest or game-specific logic in the core.
- A module must be transferable to an independent Godot project with documented steps.
- Core systems and optional extensions are clearly separated.
- Dependencies between modules are one-directional and documented (e.g. UPRG may depend on UPTG output, never the reverse).
- Generation is deterministic from a seed where randomness is involved.

## Modules

| Module | Architecture doc |
|---|---|
| UPTG | [UPTG_ARCHITECTURE.md](../../UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md) |
| UPRG | Not written yet |
| UPWG | Not written yet |

## Decisions

Significant architectural decisions are recorded as ADRs in [`decisions/`](decisions/), using the [template](decisions/ADR-0000-template.md).

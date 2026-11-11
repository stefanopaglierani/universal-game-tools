# ADR-0005: UPTG addon layout (R12)

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

UPTG must be copied into other Godot projects with everything it needs. The repository's general docs describe `addons/<code>/runtime/` + `resources/` and a module-level `presets/` folder.

## Options considered

1. Follow the general docs: consistent with existing text / default preset outside the addon, less portable.
2. R12: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` inside `addons/uptg/`: self-contained addon / general docs temporarily out of date.

## Decision

Option 2. Each module is its own Godot project; `addons/uptg/` is the only folder copied into games and references only `res://addons/uptg/...` paths. No `plugin.cfg` in v0.1. The general repository docs are not changed now; for UPTG the architecture document prevails. Decided by Stefano, 2026-11-06.

## Consequences

The structure was created in Milestone 0. Aligning the general docs and deciding the future of the module-level `presets/` folder are deferred to a separate, approved documentation update.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`

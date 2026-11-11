# ADR-0015: UPWG keeps synchronized copies of the generators

**Status:** Accepted
**Date:** 2026-11-11
**Module:** UPWG

## Context

The editor must run UPTG and UPRG inside one standalone program, also on Linux and macOS. Godot projects cannot share an addon stored outside them (see ADR-0010), and an exported program cannot call other Godot projects.

## Options considered

1. Run the other projects as separate processes: no copies / impossible in an exported program.
2. Symbolic links to the source addons: no copies / need special rights on Windows and break in archives.
3. Copies under `addons/`, made by a script and checked by a test: works everywhere / the copies must be refreshed after changes.

## Decision

Option 3: `tools/sync_vendor.gd` copies the UPTG and UPRG addons, the UPTG baker and UWR into UPWG, and `tests/test_vendor.gd` fails while any copy differs from its source. The generators are edited only in their own modules.

## Consequences

UPWG builds as one program on every platform. Every change to a generator needs a sync before UPWG is tested or released.

Source: `UPWG/UniversalProceduralWorldGenerator/documentation/UPWG_ARCHITECTURE_0.1.md`

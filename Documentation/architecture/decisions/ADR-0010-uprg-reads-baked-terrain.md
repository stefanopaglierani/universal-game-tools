**English** | [Italiano](ADR-0010-uprg-reads-baked-terrain.it.md)

# ADR-0010: UPRG works on the baked terrain file

**Status:** Accepted
**Date:** 2026-11-08
**Module:** UPRG

## Context

Roads must flatten the terrain, but `UPTGTerrainData` is read-only in UPTG v0.1, and dependencies between modules go one way. Godot projects cannot share an addon stored outside them without copying it.

## Options considered

1. Put roads inside UPTG: one project / mixes two tools and changes the contract.
2. Copy the UPTG addon into UPRG: direct access to the generator / a copy that goes stale.
3. Read the file baked by UPTG and write a new one: no shared code, UPTG unchanged / UPRG depends on the file format.

## Decision

Option 3. The file format (`format_version` 1) is the contract between the two tools. Stefano asked to proceed with the road generator on 2026-11-08; this choice was made in that work and is open to his review.

## Consequences

Each tool can be developed alone, and later sub-programs can chain the same way. Changing the terrain edit means baking again from the UPTG file. A format change needs a new `format_version`.

Source: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.1.md`

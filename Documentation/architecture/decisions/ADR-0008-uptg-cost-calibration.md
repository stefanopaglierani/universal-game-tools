# ADR-0008: UPTG cost estimate calibration from measurements

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

ADR-0006 introduced the pre-generation cost estimate and left its memory coefficients as estimates, to be calibrated with measurements in Milestone D, with approval.

## Options considered

1. Keep the initial coefficients: no change / the trimesh cost was underestimated by more than 4 times.
2. Replace the coefficients with measured values and keep the thresholds: the estimate matches reality and the protection levels stay as approved / the values depend on Godot 4.7.2 internals.

## Decision

Option 2 (architecture 0.2-r5, section 5.4). `estimated_bytes` is `vertices * 112 + cells * 48`, plus `cells * 320` with `TRIMESH`. The per-cell coefficient goes from 24 to 48 because indices are held on both CPU and GPU, and the trimesh coefficient from 72 to 320 as measured for `ConcavePolygonShape3D`. The thresholds are unchanged. Approved by Stefano by merging Milestone D (pull request #5), 2026-11-06. This ADR was written afterwards, on 2026-11-08, to close the follow-up left open by ADR-0006.

## Consequences

512 × 512 cells in `HEIGHTMAP` are estimated at about 40 MB (`OK`), and the largest accepted case, 1024 × 1024 cells in `TRIMESH`, at about 480 MB. No threshold in seconds was added. The measurements are in `documentation/TESTING.md`.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`

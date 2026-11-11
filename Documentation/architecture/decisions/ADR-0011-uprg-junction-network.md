**English** | [Italiano](ADR-0011-uprg-junction-network.it.md)

# ADR-0011: UPRG builds junctions as one network after planning every road

**Status:** Accepted
**Date:** 2026-11-09
**Module:** UPRG

## Context

Separate roads that cross must meet at one height, on one clean surface, and keep their grade limits. Stefano asked for junctions and village streets on 2026-11-09.

## Options considered

1. Each road edits the terrain in turn, later roads on top: simple / steps and overlapping surfaces where roads cross.
2. Plan every road first, then solve the meeting points together: one height per junction and one surface / a solver that can refuse impossible layouts.

## Decision

Option 2. The road listed first keeps its height and the others adapt; junction heights move only as far as the grades need. Each junction replaces the road samples around it with its own surface. Taken while building the feature Stefano asked for, and open to his review.

## Consequences

Road order now means priority. Layouts with very sharp meetings or junctions too close together are refused with a message instead of producing broken surfaces. Bridges would need a new kind of junction.

Source: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.2.md`

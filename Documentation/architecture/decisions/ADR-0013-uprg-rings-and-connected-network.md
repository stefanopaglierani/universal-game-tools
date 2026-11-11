# ADR-0013: Rings start away from junctions, and a world can require one connected network

**Status:** Accepted
**Date:** 2026-11-11
**Module:** UPRG

## Context

Circuits are closed roads. Stefano also set a rule for his worlds: every circuit and road must be part of one drivable network, and a detached circuit must not exist.

## Options considered

1. Handle junctions across the closing point of a ring: general / every junction calculation must wrap around.
2. Start each ring at its point farthest from other roads and places, so that no junction sits on the closing point: simple, all junction code unchanged / a ring touched everywhere by other roads cannot be placed well.

For the rule: a check in the bake, switched on per world (`connected_roads`), rather than always on, because single roads remain useful on their own.

## Decision

Option 2, and the `connected_roads` check, which names the roads that are not joined. Stefano gave the rule on 2026-11-11.

## Consequences

Rings, junctions and streets work together. Worlds that use the check cannot contain detached roads by mistake.

Source: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.2.md`

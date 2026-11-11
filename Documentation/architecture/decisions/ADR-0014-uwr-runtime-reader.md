# ADR-0014: A small runtime reader is the one part of the tools that ships in games

**Status:** Accepted
**Date:** 2026-11-11
**Module:** UWR

## Context

ADR-0009 keeps the tools out of games: only their output ships. Tiled worlds, though, need code in the game to stream tiles and paint the ground, and that code was first written inside Nitro Underground. Every new game would have to write it again. Stefano asked to return to independent tools on 2026-11-11 and approved the plan whose stage 1 is this reader.

## Options considered

1. Each game writes its own loader: no exception to ADR-0009 / repeated work, and worlds are harder to use.
2. A small runtime addon with no generator code, depending only on the file format: one loader for every game / it ships inside games, so it must stay small and stable.

## Decision

Option 2: UWR, in its own module. It reads files; it never imports UPTG, UPRG or UPWG scripts.

## Consequences

A new game opens a world with one node. The file format becomes a public contract of the tools: changes to it need a new format version and an update to UWR.

Source: `UWR/UniversalWorldReader/documentation/UWR_ARCHITECTURE_0.1.md`

# ADR-0009: UPTG is a private tool, only its baked output goes into a game

**Status:** Accepted
**Date:** 2026-11-08
**Module:** repository-wide

## Context

Version 0.1.0 generates terrain at runtime, and its guide describes copying the addon into a game. UPTG is private and not for sale, while Nitro Underground is a product for sale. The two programs must stay separate.

## Options considered

1. Ship the addon inside the game and generate at runtime: no export step / the tool becomes part of the product, generation runs on the player's phone.
2. Generate in the UPTG project and give the game ordinary Godot files: the game contains no UPTG code and loads a finished world / the world must be baked again to change it.

## Decision

Option 2. UPTG and all its sub-programs are development tools that create worlds and 3D objects for other software. A bake tool outside the addon writes a self-contained `.scn` file with no scripts and no reference to UPTG (architecture 0.2-r6, section 12.5). Licenses stay as they are. Decided by Stefano, 2026-11-08.

## Consequences

The generator, seed, mesh and collision code are unchanged. Future sub-programs (roads, terrain modification, places and villages, skins and textures) follow the same rule. The baked file depends on the Godot version that wrote it.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`

# UWR — Architecture 0.1

**Status:** first version (2026-11-11), stage 1 of the plan to return to the tools
**Target engine:** Godot 4.7.2

## 1. Role

The tools (UPTG, UPRG, UPWG) never ship inside a game (ADR-0009). UWR is the exception (ADR-0014): a small runtime addon, with no generator code, that opens what the tools write. It depends only on the file format, never on the tools' scripts.

## 2. Input

- **Single-file world:** a `.scn` with the `terrain_data` metadata, a `Mesh` and `Body/Shape` (UPTG or UPRG output).
- **Tiled world:** `world.scn` with `terrain_data.tiles` (`size`, `origin`, `list`) and one `tile_<x>_<z>.scn` per tile, each with `Near`, `Far` and `Body/Shape` (UPRG `uprg_tiles.gd`). With `--road-colors` the red vertex color tells how close the ground is to a road.

## 3. Streaming

`UWRWorld` keeps the tiles within `rings` (computer) or `mobile_rings` (phone) of the tile under the follow node. `load_world()` reads the tiles around the start before returning, so the ground is there at once. During play, missing tiles are read with `ResourceLoader.load_threaded_request`, at most `max_loading` at a time, and one finished tile per frame enters the scene. Tiles more than one ring beyond the limit are freed.

## 4. Ground and sea

The built-in ground shader mixes grass, sand below `beach_height` above the sea, rock on slopes and gravel where the red vertex color is high. Plain colors by default; four textures can replace them. A game can set its own `ground_material`. The sea is one large quad with small moving waves, added when `sea_size` is above 0.

## 5. Data for the game

`data` holds the world's `terrain_data`. `roads()`, `junctions()`, `places()` and `sea_level()` read it; `nearest_road_point()` finds the closest road sample.

## 6. Known limits

- Tiled worlds drop the full height array, so the ground height between road samples is read through physics (collision).
- Single-file worlds keep the terrain colors written by UPTG unless the game gives a material.
- Only the reader is tested here; worlds are produced and tested by UPTG and UPRG.

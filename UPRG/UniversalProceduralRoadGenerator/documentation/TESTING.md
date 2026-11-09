**English** | [Italiano](TESTING.it.md)

# UPRG Testing

From the module folder:

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

`tests/test_roads.gd` and `tests/test_world.gd` build a synthetic baked terrain, so they need no UPTG code. `test_world.gd` checks terrain edits, places, building faces, skins and refused inputs. It checks path spacing, `max_grade`, the terrain under and far from the road, mesh and collision against the edited heights, road winding, a self-contained result, and refused inputs. The exit code is `0` when every check passes.

`tests/test_dressing.gd` builds its own small model library and checks how models are chosen and placed, the credits file, and that a missing library is refused.

To look at a result: `godot --path . res://demo/uprg_viewer.tscn -- --file=<world.scn>`.

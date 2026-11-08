**English** | [Italiano](TESTING.it.md)

# UPRG Testing

From the module folder:

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

`tests/test_roads.gd` builds a synthetic baked terrain, so it needs no UPTG code. It checks path spacing, `max_grade`, the terrain under and far from the road, mesh and collision against the edited heights, road winding, a self-contained result, and refused inputs. The exit code is `0` when every check passes.

To look at a result: `godot --path . res://demo/uprg_viewer.tscn -- --file=<world.scn>`.

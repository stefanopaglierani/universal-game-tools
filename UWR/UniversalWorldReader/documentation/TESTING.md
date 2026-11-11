# UWR Testing

From the module folder:

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

`tests/test_reader.gd` opens the two sample worlds in `tests/data/`, made by UPRG: a 512 m terrain with a closed road, one tiled 2 x 2 and one in a single file. It checks that:

- tiles appear at once around the start, with the ground material and their collision;
- tiles leave when the follow node is far, and come back in the background;
- roads and the nearest road point can be read;
- a game material replaces the ground of a single-file world;
- the sea is added on request;
- a file that is not a world is refused.

The exit code is `0` when every check passes.

To see a world: `godot --path . res://demo/uwr_demo.tscn -- --world=<world.scn>`. `--tour --shot=<file.png>` flies along the first road and saves a picture after 8 seconds.

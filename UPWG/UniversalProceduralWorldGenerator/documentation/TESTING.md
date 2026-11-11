# UPWG Testing

From the module folder:

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

| Suite | Checks |
|---|---|
| `test_vendor.gd` | The copies of UPTG, UPRG and UWR match their sources |
| `test_project.gd` | Every template is valid; the same template and seed give the same world; coast mountains stay on land; big worlds get bigger cells; moving the mountains can be undone; projects save and open |
| `test_export.gd` | A world exports to every format; the RAW, EXR and glTF files read back with the right size; `world.json` lists seed and files; formats can be left out; an impossible world is refused |
| `test_editor.gd` | The window opens; every template builds its preview; sliders change the world and the preview follows; an island never grows past the edge; mountains can be added; the editor saves and opens projects |

The exit code is `0` when every check passes.

Measured on the development PC (2026-11-11): a 2 km world with 4 m cells (512 x 512) exports in 4.7 s, a 4 km world (1024 x 1024) in 21.8 s. The exported tiles open in the UWR demo at 60 FPS. A 30 720 m world with 4 m cells (7680 x 7680, the largest) exports in 10.4 min with a 1.8 GB memory peak: 4192 tile files (447 MB), heightmaps 178 MB, glTF at 16 m cells 313 MB. In the editor, one brush touch on that world takes about 60 ms.

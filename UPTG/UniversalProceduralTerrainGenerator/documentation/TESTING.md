**English** | [Italiano](TESTING.it.md)

# UPTG Testing

UPTG tests are plain GDScript files run headless by Godot 4.7.2. No test framework or plugin is needed.

## Running the tests

From the module folder (`UPTG/UniversalProceduralTerrainGenerator/`):

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

- The first command imports the project and registers the `class_name` scripts. It is only needed after adding or renaming scripts, or on a fresh clone (the `.godot/` cache is not in Git).
- `godot` is the Godot 4.7.2 executable. On Windows, use the `_console.exe` build so that the output and the exit code reach the terminal.
- The exit code is `0` when every check passes and `1` when at least one check fails or a script does not compile.

## Output

Each check prints one line:

- `PASS <name> | <detail>`: the check passed.
- `FAIL <name> | <detail>`: the check failed; the detail shows the value that was found.
- `INFO <name> | <detail>`: a measurement, not a check (for example timings).

The last line is `SUMMARY checks=<n> failures=<n>`.

Some tests feed invalid configurations on purpose. The generator reports them with `push_error`, so a run that passes still prints two `ERROR: UPTG: ...` lines (an invalid `cell_size` and a large configuration without `allow_large_terrain`). They are expected.

## Test suites

| File | What it checks | Criteria |
|---|---|---|
| `tests/test_seed.gd` | `UPTGSeed.derive()` reference values, range, distinct sub-seeds | A7 |
| `tests/test_validation.gd` | `UPTGConfig.validate()` rejects each kind of invalid value; cost levels OK / LARGE / REJECTED and refusal without generating | A5, A5b |
| `tests/test_determinism.gd` | Same seed gives the same heights and checksums; border at the sea floor; height queries on the verified diagonal; resolution independence; `.tres` preset round trip; timings | A7, A11, A12 |

## Adding a suite

1. Create `tests/test_<topic>.gd` extending `RefCounted` with a `func run(t: Object) -> void`.
2. Inside `run`, call `t.check(name, condition, detail)` for each check and `t.info(name, detail)` for measurements.
3. Add the path to `SUITES` in `tests/run_tests.gd`.
4. Commit the script together with its `.gd.uid` file, which Godot creates on import.

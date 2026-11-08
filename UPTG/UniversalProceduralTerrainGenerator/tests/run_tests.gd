## UPTG automated test runner.
## Run from the module folder: godot --headless --path . -s res://tests/run_tests.gd
## Exit code: 0 when every check passes, 1 otherwise.
extends SceneTree

const SUITES: Array[String] = [
	"res://tests/test_seed.gd",
	"res://tests/test_validation.gd",
	"res://tests/test_determinism.gd",
	"res://tests/test_mesh.gd",
	"res://tests/test_terrain_node.gd",
	"res://tests/test_bake.gd",
]

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("UPTG tests - Godot %s" % Engine.get_version_info().string)
	for path in SUITES:
		print("\n== %s" % path)
		var suite: Object = load(path).new()
		suite.call("run", self)
	print("\nSUMMARY checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


## Records one check.
func check(test_name: String, ok: bool, detail: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failures += 1
	var suffix: String = "" if str(detail) == "" else " | " + str(detail)
	print("%s %s%s" % ["PASS" if ok else "FAIL", test_name, suffix])


## Prints an informational line (not a check).
func info(test_name: String, detail: Variant) -> void:
	print("INFO %s | %s" % [test_name, str(detail)])

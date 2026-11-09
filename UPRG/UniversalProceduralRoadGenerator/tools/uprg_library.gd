extends SceneTree
## Builds the model library used for dressing worlds. From the module folder:
## godot --headless --path . -s res://tools/uprg_library.gd -- --models=<Ambientazione folder>
## Optional: --catalog=<catalog.json> --out=<library folder>
## Exit code: 0 when the library is written, 1 otherwise.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var models := ""
	var catalog := "res://presets/ambientazione_catalog.json"
	var out := "res://library"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--models="):
			models = a.substr(9)
		elif a.begins_with("--catalog="):
			catalog = a.substr(10)
		elif a.begins_with("--out="):
			out = a.substr(6)
	if models.is_empty():
		printerr("Needed: --models=<folder>")
		quit(1)
		return
	var result := UPRGLibraryBuilder.build(models, catalog, out, root)
	print("LIBRARY ", result)
	quit(0 if result.ok else 1)

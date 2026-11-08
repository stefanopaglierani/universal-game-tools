extends SceneTree
## Bakes a terrain to a .scn file that a game can open without UPTG. From the module folder:
## godot --headless --path . -s res://tools/uptg_bake.gd -- --out=<file.scn> [--preset=<res path>] [--seed=<n>] [--allow-large]
## Exit code: 0 when the file is written, 1 otherwise.

const DEFAULT_PRESET := "res://addons/uptg/presets/uptg_island_default.tres"


func _initialize() -> void:
	var out_path := ""
	var preset_path := DEFAULT_PRESET
	var seed_value := -1
	var allow_large := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--preset="):
			preset_path = a.substr(9)
		elif a.begins_with("--seed="):
			seed_value = int(a.substr(7))
		elif a == "--allow-large":
			allow_large = true
	if out_path.is_empty():
		printerr("Missing --out=<file.scn>")
		quit(1)
		return
	var preset := load(preset_path) as UPTGConfig
	if preset == null:
		printerr("Cannot load the preset: ", preset_path)
		quit(1)
		return
	var config := preset.duplicate(true) as UPTGConfig
	if seed_value >= 0:
		config.generation_seed = seed_value
	var result := UPTGBaker.bake(config, out_path, allow_large)
	print("BAKE ", result)
	quit(0 if result.ok else 1)

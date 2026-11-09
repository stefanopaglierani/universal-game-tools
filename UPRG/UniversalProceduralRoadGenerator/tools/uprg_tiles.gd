extends SceneTree
## Cuts a world baked by uprg_bake.gd into tiles. From the module folder:
## godot --headless --path . -s res://tools/uprg_tiles.gd -- --in=<world.scn> --out=<folder> [--cells=64]
## Exit code: 0 when the tiles are written, 1 otherwise.


func _initialize() -> void:
	var in_path := ""
	var out_dir := ""
	var cells := 64
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--in="):
			in_path = a.substr(5)
		elif a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--cells="):
			cells = int(a.substr(8))
	if in_path.is_empty() or out_dir.is_empty():
		printerr("Needed: --in=<world.scn> --out=<folder>")
		quit(1)
		return
	var result := UPRGTileBuilder.split(in_path, out_dir, cells)
	print("TILES ", result)
	quit(0 if result.ok else 1)

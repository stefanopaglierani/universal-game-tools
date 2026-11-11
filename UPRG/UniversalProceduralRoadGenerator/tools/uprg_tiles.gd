extends SceneTree
## Cuts a world baked by uprg_bake.gd into tiles. From the module folder:
## godot --headless --path . -s res://tools/uprg_tiles.gd -- --in=<world.scn> --out=<folder> [--cells=64] [--road-colors]
## --road-colors: the red vertex color marks the ground next to the roads instead of holding the terrain colors.
## Exit code: 0 when the tiles are written, 1 otherwise.


func _initialize() -> void:
	var in_path := ""
	var out_dir := ""
	var cells := 64
	var road_colors := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--in="):
			in_path = a.substr(5)
		elif a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--cells="):
			cells = int(a.substr(8))
		elif a == "--road-colors":
			road_colors = true
	if in_path.is_empty() or out_dir.is_empty():
		printerr("Needed: --in=<world.scn> --out=<folder>")
		quit(1)
		return
	var result := UPRGTileBuilder.split(in_path, out_dir, cells, road_colors)
	print("TILES ", result)
	quit(0 if result.ok else 1)

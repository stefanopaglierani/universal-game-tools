extends SceneTree
## Adds a world description or roads to a terrain baked by UPTG. From the module folder:
## godot --headless --path . -s res://tools/uprg_bake.gd -- --in=<terrain.scn> --world=<world.tres> --out=<result.scn>
## godot --headless --path . -s res://tools/uprg_bake.gd -- --in=<terrain.scn> --road=<road.tres> [--road=<road2.tres>] --out=<result.scn>
## Exit code: 0 when the file is written, 1 otherwise.


func _initialize() -> void:
	var in_path := ""
	var out_path := ""
	var roads: Array[UPRGRoadConfig] = []
	var world: UPRGWorldConfig
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--in="):
			in_path = a.substr(5)
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--road="):
			var road := load(a.substr(7)) as UPRGRoadConfig
			if road == null:
				printerr("Cannot load the road: ", a.substr(7))
				quit(1)
				return
			roads.append(road)
		elif a.begins_with("--world="):
			world = load(a.substr(8)) as UPRGWorldConfig
			if world == null:
				printerr("Cannot load the world description: ", a.substr(8))
				quit(1)
				return
	if in_path.is_empty() or out_path.is_empty():
		printerr("Needed: --in=<terrain.scn> --world=<world.tres> (or --road=<road.tres>) --out=<result.scn>")
		quit(1)
		return
	var result := UPRGBaker.bake_world(in_path, world, out_path) if world != null else UPRGBaker.bake(in_path, roads, out_path)
	print("BAKE ", result)
	quit(0 if result.ok else 1)

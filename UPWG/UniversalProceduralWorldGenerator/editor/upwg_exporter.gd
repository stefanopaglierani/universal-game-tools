class_name UPWGExporter
extends RefCounted
## Builds a UPWG world at full detail and writes it in the formats chosen in the project:
##   godot/world.scn          one file for Godot (open it as a scene, or with UWR)
##   godot/tiles/              the same world in tiles, for big worlds and UWR streaming
##   heightmap/height.r16      16-bit raw heights (Unity, Unreal and most terrain tools)
##   heightmap/height.exr      32-bit float heights (Blender, Houdini)
##   heightmap/height.json     what the numbers mean: size, cell, lowest and highest point
##   gltf/terrain.glb          the terrain as a mesh, for any 3D program or engine
##   world.json                summary of the world and of the files written


## Returns {ok, files: Array[String], seconds} or {ok: false, error}.
static func export_world(project: UPWGProject, folder: String) -> Dictionary:
	var started := Time.get_ticks_msec()
	var errors := project.validate()
	if not errors.is_empty():
		return _fail("; ".join(errors))
	if DirAccess.make_dir_recursive_absolute(folder.path_join("godot")) != OK:
		return _fail("cannot create the folder %s" % folder)
	var files: Array[String] = []
	var single := folder.path_join("godot/world.scn")
	var baked := UPTGBaker.bake(project.terrain, single, true)
	if not baked.ok:
		return _fail("terrain: %s" % baked.get("error", "unknown error"))
	if _has_world_content(project.world):
		var terrain_only := folder.path_join("godot/terrain.scn")
		DirAccess.rename_absolute(single, terrain_only)
		var world := UPRGBaker.bake_world(terrain_only, project.world, single)
		DirAccess.remove_absolute(terrain_only)
		if not world.ok:
			return _fail("roads, places and water: %s" % world.get("error", "unknown error"))
	files.append(single)

	var root := (ResourceLoader.load(single, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D
	var meta: Dictionary = root.get_meta("terrain_data")
	if project.export_heightmap:
		files.append_array(_write_heightmap(meta, folder.path_join("heightmap")))
	if project.export_gltf:
		var glb := _write_gltf(root, folder.path_join("gltf/terrain.glb"))
		if glb.is_empty():
			root.free()
			return _fail("could not write the glTF file")
		files.append(glb)
	root.free()

	if project.export_godot_tiles:
		var cells := tile_cells(project.terrain.grid_cells_x, project.terrain.grid_cells_z)
		if cells > 0:
			var tiles := UPRGTileBuilder.split(single, folder.path_join("godot/tiles"), cells, true)
			if not tiles.ok:
				return _fail("tiles: %s" % tiles.error)
			files.append(folder.path_join("godot/tiles"))
	if not project.export_godot_single:
		DirAccess.remove_absolute(single)
		files.erase(single)

	var summary := {
		"name": project.world_name,
		"template": project.template,
		"seed": project.terrain.generation_seed,
		"size_m": [project.terrain.get_size().x, project.terrain.get_size().y],
		"cell_m": project.terrain.cell_size,
		"sea_level": meta.get("sea_level", 0.0),
		"files": files.map(func(f: String) -> String: return f.trim_prefix(folder).trim_prefix("/")),
		"made_with": "UPWG %s" % ProjectSettings.get_setting("application/config/version", "0.1.0"),
	}
	var info := FileAccess.open(folder.path_join("world.json"), FileAccess.WRITE)
	if info == null:
		return _fail("cannot write world.json")
	info.store_string(JSON.stringify(summary, "\t"))
	info.close()
	files.append(folder.path_join("world.json"))
	return {"ok": true, "files": files, "seconds": (Time.get_ticks_msec() - started) / 1000.0}


## The largest tile, up to 64 cells, that divides the grid and the light mesh step.
static func tile_cells(cells_x: int, cells_z: int) -> int:
	for cells in [64, 32, 16, 8]:
		if cells_x % cells == 0 and cells_z % cells == 0:
			return cells
	return 0


static func _has_world_content(world: UPRGWorldConfig) -> bool:
	return world != null and not (world.roads.is_empty() and world.places.is_empty() and world.terrain_edits.is_empty() and world.water.is_empty())


static func _write_heightmap(meta: Dictionary, folder: String) -> Array[String]:
	DirAccess.make_dir_recursive_absolute(folder)
	var heights: PackedFloat32Array = meta.heights
	var vx: int = meta.grid_cells_x + 1
	var vz: int = meta.grid_cells_z + 1
	var low := INF
	var high := -INF
	for h in heights:
		low = minf(low, h)
		high = maxf(high, h)
	var span := maxf(high - low, 0.001)
	var raw := PackedByteArray()
	raw.resize(heights.size() * 2)
	for i in heights.size():
		raw.encode_u16(i * 2, int(round((heights[i] - low) / span * 65535.0)))
	var r16 := FileAccess.open(folder.path_join("height.r16"), FileAccess.WRITE)
	r16.store_buffer(raw)
	r16.close()
	var image := Image.create_empty(vx, vz, false, Image.FORMAT_RF)
	for z in vz:
		for x in vx:
			image.set_pixel(x, z, Color(heights[z * vx + x], 0, 0))
	image.save_exr(folder.path_join("height.exr"), true)
	var info := {
		"width_px": vx, "height_px": vz, "cell_m": meta.cell_size,
		"size_m": [meta.grid_cells_x * meta.cell_size, meta.grid_cells_z * meta.cell_size],
		"lowest_m": low, "highest_m": high, "sea_level_m": meta.sea_level,
		"r16": "unsigned 16-bit little endian, row by row from -Z to +Z; 0 = lowest_m, 65535 = highest_m",
		"exr": "32-bit float, one channel (R), heights in meters",
	}
	var json := FileAccess.open(folder.path_join("height.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify(info, "\t"))
	json.close()
	return [folder.path_join("height.r16"), folder.path_join("height.exr"), folder.path_join("height.json")]


static func _write_gltf(root: Node3D, path: String) -> String:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var scene := Node3D.new()
	scene.name = "Terrain"
	var source := root.get_node_or_null("Mesh") as MeshInstance3D
	if source == null:
		scene.free()
		return ""
	var mesh := MeshInstance3D.new()
	mesh.name = "Ground"
	mesh.mesh = source.mesh
	scene.add_child(mesh)
	mesh.owner = scene
	var roads := root.get_node_or_null("Roads")
	if roads != null:
		for road in roads.get_children():
			if road is MeshInstance3D:
				var copy := MeshInstance3D.new()
				copy.name = road.name
				copy.mesh = (road as MeshInstance3D).mesh
				scene.add_child(copy)
				copy.owner = scene
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_scene(scene, state)
	if error == OK:
		error = document.write_to_filesystem(state, path)
	scene.free()
	return path if error == OK else ""


static func _fail(message: String) -> Dictionary:
	push_error("UPWG export: " + message)
	return {"ok": false, "error": message}

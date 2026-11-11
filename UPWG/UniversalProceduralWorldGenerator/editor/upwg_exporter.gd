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
## A world with more than 2048 cells per side (UPWGProject.is_large) is too big for one scene: its
## heights are generated alone and written straight as tiles, and the glTF mesh has the detail of
## the preview terrain (ADR-0017).


## Returns {ok, files: Array[String], seconds} or {ok: false, error}.
static func export_world(project: UPWGProject, folder: String) -> Dictionary:
	var started := Time.get_ticks_msec()
	var errors := project.validate()
	if not errors.is_empty():
		return _fail("; ".join(errors))
	if DirAccess.make_dir_recursive_absolute(folder.path_join("godot")) != OK:
		return _fail("cannot create the folder %s" % folder)
	var files: Array[String] = []
	var notes: Array[String] = []
	if project.is_large():
		var large := _export_large(project, folder, files, notes)
		if not large.ok:
			return large
		return _finish(project, folder, files, notes, large.sea_level, started)
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
	return _finish(project, folder, files, notes, meta.get("sea_level", 0.0), started)


static func _finish(project: UPWGProject, folder: String, files: Array[String], notes: Array[String], sea_level: float, started: int) -> Dictionary:
	var summary := {
		"name": project.world_name,
		"template": project.template,
		"seed": project.terrain.generation_seed,
		"size_m": [project.terrain.get_size().x, project.terrain.get_size().y],
		"cell_m": project.export_cell(),
		"sea_level": sea_level,
		"notes": notes,
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


## A world too big for one scene: heights alone at the export detail, then brush strokes and
## water, then tiles, heightmap and a glTF at the detail of the terrain configuration.
static func _export_large(project: UPWGProject, folder: String, files: Array[String], notes: Array[String]) -> Dictionary:
	var config := project.terrain
	var data := UPTGHeightfieldGenerator.generate_heights(config, project.export_cell())
	if data == null:
		return _fail("terrain: the heights could not be generated")
	var grid := UPRGTerrainGrid.new()
	grid.cells_x = data.grid_cells_x
	grid.cells_z = data.grid_cells_z
	grid.cell_size = data.cell_size
	grid.sea_level = data.sea_level
	grid.heights = data.heights
	var meta := {
		"format_version": UPRGTerrainGrid.SUPPORTED_FORMAT,
		"algorithm_version": UPTGTerrainData.ALGORITHM_VERSION,
		"generation_seed": data.generation_seed,
		"config_checksum": data.config_checksum,
		"grid_cells_x": data.grid_cells_x,
		"grid_cells_z": data.grid_cells_z,
		"cell_size": data.cell_size,
		"sea_level": data.sea_level,
		"sea_floor_depth": data.sea_floor_depth,
	}
	data = null
	var world := project.world
	if world != null:
		if not (world.roads.is_empty() and world.places.is_empty()):
			notes.append("roads and places are not exported yet for worlds over 2048 cells per side")
		for edit in world.terrain_edits:
			edit.apply(grid)
	var root := Node3D.new()
	root.name = "World"
	var water_meta: Array[Dictionary] = []
	if world != null and not world.water.is_empty():
		var water_group := Node3D.new()
		water_group.name = "Water"
		root.add_child(water_group)
		water_group.owner = root
		for i in world.water.size():
			var plan := UPRGWaterBuilder.dig(world.water[i], grid)
			if not plan.ok:
				root.free()
				return _fail("water: %s" % plan.error)
			var surface := UPRGWaterBuilder.build_mesh(plan, grid)
			if surface != null:
				var node := MeshInstance3D.new()
				node.name = "%s%d" % ["Lake" if plan.kind == "lake" else "River", i]
				node.mesh = surface
				node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				water_group.add_child(node)
				node.owner = root
			if plan.kind == "lake":
				water_meta.append({"kind": "lake", "center": plan.center, "radius": plan.radius, "level": plan.level})
			else:
				water_meta.append({"kind": "river", "path": plan.path, "levels": plan.levels, "width": plan.width})
	meta.water = water_meta
	meta.heights = grid.heights
	if project.export_heightmap:
		files.append_array(_write_heightmap(meta, folder.path_join("heightmap")))
	if project.export_gltf:
		var glb := _write_gltf_coarse(grid, config, root, folder.path_join("gltf/terrain.glb"))
		if glb.is_empty():
			root.free()
			return _fail("could not write the glTF file")
		files.append(glb)
		notes.append("gltf/terrain.glb has %.1f m cells; the tiles and the heightmap have the full detail" % config.cell_size)
	if project.export_godot_single or project.export_godot_tiles:
		if project.export_godot_single:
			notes.append("godot/world.scn is not written: the world is too big for one scene, use godot/tiles")
		var cells := tile_cells(grid.cells_x, grid.cells_z)
		var tiles := UPRGTileBuilder.split_grid(grid, root, meta, folder.path_join("godot/tiles"), cells, config.uv_tile_size)
		if not tiles.ok:
			root.free()
			return _fail("tiles: %s" % tiles.error)
		files.append(folder.path_join("godot/tiles"))
	root.free()
	return {"ok": true, "sea_level": grid.sea_level}


## The terrain mesh at the detail of [param config] (one vertex out of every few of the grid), with
## the water, as a glTF file.
static func _write_gltf_coarse(grid: UPRGTerrainGrid, config: UPTGConfig, water_root: Node3D, path: String) -> String:
	var step := grid.cells_x / config.grid_cells_x
	var data := UPTGTerrainData.new()
	data.grid_cells_x = config.grid_cells_x
	data.grid_cells_z = config.grid_cells_z
	data.vertex_count_x = config.grid_cells_x + 1
	data.vertex_count_z = config.grid_cells_z + 1
	data.cell_size = config.cell_size
	data.size = config.get_size()
	data.sea_level = grid.sea_level
	var heights := PackedFloat32Array()
	heights.resize(data.vertex_count_x * data.vertex_count_z)
	for iz in data.vertex_count_z:
		for ix in data.vertex_count_x:
			heights[iz * data.vertex_count_x + ix] = grid.heights[grid.index(ix * step, iz * step)]
	data.heights = heights
	var root := Node3D.new()
	var ground := MeshInstance3D.new()
	ground.name = "Mesh"
	ground.mesh = UPTGMeshBuilder.build(data, config)
	root.add_child(ground)
	var water := water_root.get_node_or_null("Water")
	if water != null:
		for lake in water.get_children():
			var copy := MeshInstance3D.new()
			copy.name = lake.name
			copy.mesh = (lake as MeshInstance3D).mesh
			root.add_child(copy)
	var written := _write_gltf(root, path)
	root.free()
	return written


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
	var extras: Array[Node] = []
	var roads := root.get_node_or_null("Roads")
	if roads != null:
		extras.append_array(roads.get_children())
	var water := root.get_node_or_null("Water")
	if water != null:
		extras.append_array(water.get_children())
	for child in root.get_children():
		if child is MeshInstance3D and child.name != "Mesh":
			extras.append(child)
	for item in extras:
		if item is MeshInstance3D:
			var copy := MeshInstance3D.new()
			copy.name = item.name
			copy.mesh = (item as MeshInstance3D).mesh
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

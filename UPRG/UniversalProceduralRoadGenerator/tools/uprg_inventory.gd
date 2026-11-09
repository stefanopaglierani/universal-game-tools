extends SceneTree
## Lists every .glb and .gltf model under a folder, with the size and cost of each piece.
## godot --headless --path . -s res://tools/uprg_inventory.gd -- --dir=<folder> --out=<report.json>
## Exit code: 0 when the report is written, 1 otherwise.


func _initialize() -> void:
	var dir_path := ""
	var out_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir_path = a.substr(6)
		elif a.begins_with("--out="):
			out_path = a.substr(6)
	if dir_path.is_empty() or out_path.is_empty():
		printerr("Needed: --dir=<folder> --out=<report.json>")
		quit(1)
		return
	var files := PackedStringArray()
	_collect(dir_path, files)
	files.sort()
	var report: Array[Dictionary] = []
	for path in files:
		var entry := _inspect(path)
		report.append(entry)
		print("%s pieces=%d tris=%d error=%s" % [path.get_file(), entry.pieces.size(), entry.triangles, entry.error])
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write: ", out_path)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("INVENTORY models=%d" % report.size())
	quit(0)


func _collect(folder: String, into: PackedStringArray) -> void:
	for sub in DirAccess.get_directories_at(folder):
		_collect(folder.path_join(sub), into)
	for f in DirAccess.get_files_at(folder):
		if f.get_extension().to_lower() in ["glb", "gltf"]:
			into.append(folder.path_join(f))


func _inspect(path: String) -> Dictionary:
	var entry := {"path": path, "pieces": [], "triangles": 0, "error": ""}
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var err := document.append_from_file(path, state)
	if err != OK:
		entry.error = "load error %d" % err
		return entry
	var scene := document.generate_scene(state)
	if scene == null:
		entry.error = "no scene"
		return entry
	root.add_child(scene)
	var total := 0
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var tris := 0
		var biggest_texture := 0
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			tris += (indices.size() if not indices.is_empty() else vertices.size()) / 3
			var material := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				biggest_texture = maxi(biggest_texture, material.albedo_texture.get_width())
		total += tris
		var box := mi.global_transform * mi.get_aabb()
		entry.pieces.append({
			"name": str(mi.name),
			"triangles": tris,
			"surfaces": mi.mesh.get_surface_count(),
			"size": [snappedf(box.size.x, 0.01), snappedf(box.size.y, 0.01), snappedf(box.size.z, 0.01)],
			"position": [snappedf(box.get_center().x, 0.01), snappedf(box.get_center().y, 0.01), snappedf(box.get_center().z, 0.01)],
			"texture": biggest_texture,
		})
	entry.triangles = total
	root.remove_child(scene)
	scene.free()
	return entry

class_name UPRGLibraryBuilder
extends RefCounted
## Turns chosen .glb/.gltf models into a light library: one mesh file per object, standing on
## the ground, at real size, with small textures. The worlds are then baked from this library.


## Reads the catalog and writes the library to [param out_dir]. Returns a Dictionary:
## [code]ok[/code], and [code]error[/code] on failure, or [code]items[/code] and [code]skipped[/code].
const LOD_NORMAL_MERGE := 25.0
const LOD_NORMAL_SPLIT := 60.0


static func build(models_dir: String, catalog_path: String, out_dir: String, parent: Node) -> Dictionary:
	var text := FileAccess.get_file_as_string(catalog_path)
	var catalog: Variant = JSON.parse_string(text)
	if not catalog is Dictionary:
		return {"ok": false, "error": "cannot read the catalog: %s" % catalog_path}
	var credits := find_credits(models_dir)
	if credits.is_empty():
		return {"ok": false, "error": "no credits table (a .md file with one row per model) in %s" % models_dir}
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	if error != OK:
		return {"ok": false, "error": "cannot create %s" % out_dir}
	var models := {}
	_index_models(models_dir, models)
	var max_triangles: int = catalog.get("max_triangles", 26000)
	var max_texture: int = catalog.get("max_texture", 512)
	var index: Array[Dictionary] = []
	var skipped: Array[String] = []
	for entry: Dictionary in catalog.entries:
		var n := int(entry.n)
		if not models.has(n) or not credits.has(n):
			skipped.append("%d: not found" % n)
			continue
		var made := _build_entry(models[n], entry, max_triangles, max_texture, out_dir, parent, credits[n], skipped)
		index.append_array(made)
	var file := FileAccess.open(out_dir.path_join("index.json"), FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "cannot write the library index"}
	file.store_string(JSON.stringify(index, "\t"))
	file.close()
	return {"ok": true, "items": index.size(), "skipped": skipped}


## The first Markdown file in [param models_dir] that holds a credits table, read with
## [method parse_credits]. Empty when there is none.
static func find_credits(models_dir: String) -> Dictionary:
	for file_name in DirAccess.get_files_at(models_dir):
		if file_name.get_extension().to_lower() == "md":
			var credits := parse_credits(models_dir.path_join(file_name))
			if not credits.is_empty():
				return credits
	return {}


## Reads a credits table: number -> {model, author, source, license, link}. Rows look like
## | n | folder | file | model | author | source | license | triangles | link |
static func parse_credits(path: String) -> Dictionary:
	var credits := {}
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if not line.begins_with("| ") or line.begins_with("| N "):
			continue
		var cells: PackedStringArray = line.trim_prefix("|").trim_suffix("|").split(" | ")
		if cells.size() < 9 or not cells[0].strip_edges().is_valid_int():
			continue
		credits[cells[0].strip_edges().to_int()] = {
			"model": cells[3].strip_edges(), "author": cells[4].strip_edges(), "source": cells[5].strip_edges(),
			"license": cells[6].strip_edges(), "link": cells[8].strip_edges(),
		}
	return credits


static func _index_models(folder: String, models: Dictionary) -> void:
	for sub in DirAccess.get_directories_at(folder):
		_index_models(folder.path_join(sub), models)
	for f in DirAccess.get_files_at(folder):
		if not f.get_extension().to_lower() in ["glb", "gltf"]:
			continue
		var own := f if f.get_extension().to_lower() == "glb" else folder.get_file()
		var number := own.get_slice("_", 0)
		if number.is_valid_int():
			models[number.to_int()] = folder.path_join(f)


static func _build_entry(path: String, entry: Dictionary, max_triangles: int, max_texture: int, out_dir: String,
		parent: Node, credit: Dictionary, skipped: Array[String]) -> Array[Dictionary]:
	var made: Array[Dictionary] = []
	var n := int(entry.n)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path, state) != OK:
		skipped.append("%d: cannot load" % n)
		return made
	var scene := document.generate_scene(state)
	if scene == null:
		skipped.append("%d: no scene" % n)
		return made
	parent.add_child(scene)
	var instances: Array[MeshInstance3D] = []
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).mesh != null:
			instances.append(node)
	var groups: Array = []
	var only: Array = entry.get("only", [])
	if entry.get("pieces", false):
		for mi in instances:
			groups.append([mi])
	else:
		groups.append(instances)
	var textures := {}
	for g in groups.size():
		if not only.is_empty() and not float(g) in only:
			continue
		var item_id := "%03d_%02d" % [n, g] if groups.size() > 1 else "%03d" % n
		var result := _merge(groups[g], entry, max_triangles, max_texture, textures)
		if result.is_empty():
			skipped.append("%s: too heavy or empty" % item_id)
			continue
		var mesh_path := out_dir.path_join(item_id + ".res")
		if ResourceSaver.save(result.mesh, mesh_path, ResourceSaver.FLAG_COMPRESS) != OK:
			skipped.append("%s: cannot save" % item_id)
			continue
		made.append({"id": item_id, "n": n, "kind": entry.kind, "path": mesh_path, "size": result.size, "triangles": result.triangles,
			"model": credit.model, "author": credit.author, "license": credit.license, "source": credit.source, "link": credit.link})
	parent.remove_child(scene)
	scene.free()
	return made


static func _merge(instances: Array, entry: Dictionary, max_triangles: int, max_texture: int, textures: Dictionary) -> Dictionary:
	var buckets := {}
	var total_triangles := 0
	var fix := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(float(entry.get("rotate_x", 0.0)))), Vector3.ZERO)
	var low := Vector3.INF
	var high := -Vector3.INF
	for mi: MeshInstance3D in instances:
		var world := fix * mi.global_transform
		for s in mi.mesh.get_surface_count():
			# Some model files also hold lines or points: they would break the merged triangles.
			if mi.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arrays := mi.mesh.surface_get_arrays(s)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				indices.resize(vertices.size())
				for i in vertices.size():
					indices[i] = i
			total_triangles += indices.size() / 3
			if total_triangles > max_triangles:
				return {}
			var material := mi.mesh.surface_get_material(s)
			var key := material.get_instance_id() if material != null else 0
			if not buckets.has(key):
				buckets[key] = {"material": material, "v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "i": PackedInt32Array()}
			var bucket: Dictionary = buckets[key]
			var offset: int = bucket.v.size()
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var uvs: Variant = arrays[Mesh.ARRAY_TEX_UV]
			var normal_basis := world.basis.inverse().transposed()
			for i in vertices.size():
				var p := world * vertices[i]
				low = low.min(p)
				high = high.max(p)
				bucket.v.append(p)
				bucket.n.append((normal_basis * normals[i]).normalized() if i < normals.size() else Vector3.UP)
				bucket.uv.append(uvs[i] if uvs != null and i < (uvs as PackedVector2Array).size() else Vector2.ZERO)
			for i in indices:
				bucket.i.append(offset + i)
	if buckets.is_empty():
		return {}
	var natural_size := high - low
	var scale_factor := 1.0
	if not entry.get("natural", false):
		if natural_size.y <= 0.0001:
			return {}
		scale_factor = float(entry.height) / natural_size.y
	elif natural_size.length() < 0.05 or maxf(natural_size.x, maxf(natural_size.y, natural_size.z)) > 60.0:
		return {}
	var base := Vector3((low.x + high.x) * 0.5, low.y, (low.z + high.z) * 0.5)
	# Built through ImporterMesh to add lighter versions (levels of detail) inside the mesh:
	# the renderer switches to them by itself as the object gets small on the screen.
	var importer := ImporterMesh.new()
	for key: int in buckets:
		var bucket: Dictionary = buckets[key]
		var vertices: PackedVector3Array = bucket.v
		for i in vertices.size():
			vertices[i] = (vertices[i] - base) * scale_factor
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = bucket.n
		arrays[Mesh.ARRAY_TEX_UV] = bucket.uv
		arrays[Mesh.ARRAY_INDEX] = bucket.i
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, _light_material(bucket.material, max_texture, textures))
	importer.generate_lods(LOD_NORMAL_MERGE, LOD_NORMAL_SPLIT, [])
	var mesh := importer.get_mesh()
	var size := natural_size * scale_factor
	return {"mesh": mesh, "triangles": total_triangles, "size": [snappedf(size.x, 0.01), snappedf(size.y, 0.01), snappedf(size.z, 0.01)]}


## Keeps color, small albedo texture and transparency: normal and detail maps cost too much on a phone.
static func _light_material(source: Material, max_texture: int, textures: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	var base := source as BaseMaterial3D
	if base == null:
		return material
	material.albedo_color = base.albedo_color
	material.cull_mode = base.cull_mode
	material.transparency = base.transparency
	if base.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
		# Blended leaves are slow and sort badly; cut-out looks the same at a distance.
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.5
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	elif base.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		material.alpha_scissor_threshold = base.alpha_scissor_threshold
	var texture := base.albedo_texture
	if texture != null:
		var key := texture.get_rid().get_id()
		if not textures.has(key):
			var image := texture.get_image()
			if image.is_compressed():
				image.decompress()
			var longest := maxi(image.get_width(), image.get_height())
			if longest > max_texture:
				var ratio := float(max_texture) / longest
				image.resize(maxi(int(image.get_width() * ratio), 1), maxi(int(image.get_height() * ratio), 1), Image.INTERPOLATE_LANCZOS)
			image.generate_mipmaps()
			textures[key] = ImageTexture.create_from_image(image)
		material.albedo_texture = textures[key]
	return material

## Tests for the bake tool: the output must work without any UPTG code.
extends RefCounted

const OUT_PATH := "user://uptg_bake_test/terrain.scn"


func _small() -> UPTGConfig:
	var c := UPTGConfig.new()
	c.grid_cells_x = 64
	c.grid_cells_z = 48
	c.cell_size = 8.0
	return c


func _has_script(node: Node) -> bool:
	if node.get_script() != null:
		return true
	for child in node.get_children():
		if _has_script(child):
			return true
	return false


func run(t: Object) -> void:
	var config := _small()
	var result: Dictionary = UPTGBaker.bake(config, OUT_PATH)
	t.check("bake writes the file", result.ok and FileAccess.file_exists(OUT_PATH), str(result))
	if not result.ok:
		return
	t.check("the baked file depends on no other file", ResourceLoader.get_dependencies(OUT_PATH).is_empty(),
		str(ResourceLoader.get_dependencies(OUT_PATH)))

	var scene := ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	t.check("the baked file loads as a scene", scene != null)
	if scene == null:
		return
	var root := scene.instantiate() as Node3D
	t.check("no node of the baked scene has a script", not _has_script(root))

	var expected := UPTGHeightfieldGenerator.generate(config)
	var mesh_node := root.get_node_or_null("Mesh") as MeshInstance3D
	t.check("the mesh has the expected vertices",
		mesh_node != null and mesh_node.mesh.surface_get_array_len(0) == expected.vertex_count_x * expected.vertex_count_z)
	var material := mesh_node.mesh.surface_get_material(0) as StandardMaterial3D
	t.check("the material is inside the file and uses vertex colors",
		material != null and material.vertex_color_use_as_albedo and material.resource_path.get_extension() != "tres")
	var shape_node := root.get_node_or_null("Body/Shape") as CollisionShape3D
	t.check("the collision shape is a height map with the expected scale", shape_node != null
		and shape_node.shape is HeightMapShape3D
		and shape_node.scale.is_equal_approx(UPTGCollisionBuilder.get_shape_scale(expected, config.collision_mode)))

	var meta: Dictionary = root.get_meta(UPTGBaker.META_KEY, {})
	t.check("the metadata keeps the seed, the checksum and the format", meta.get("generation_seed") == expected.generation_seed
		and meta.get("heights_checksum") == expected.heights_checksum and meta.get("format_version") == UPTGBaker.FORMAT_VERSION)
	t.check("the metadata keeps the same heights as the generator", meta.get("heights") == expected.heights)
	root.free()

	var again: Dictionary = UPTGBaker.bake(config, OUT_PATH)
	t.check("baking again gives the same heights checksum", again.ok and again.heights_checksum == result.heights_checksum)

	t.check("a wrong file extension is refused", not UPTGBaker.bake(config, "user://uptg_bake_test/terrain.tscn").ok)
	var invalid := _small()
	invalid.cell_size = -1.0
	t.check("an invalid configuration is refused", not UPTGBaker.bake(invalid, OUT_PATH.replace("terrain", "invalid")).ok)
	t.check("a refused bake writes no file", not FileAccess.file_exists(OUT_PATH.replace("terrain", "invalid")))
	t.info("baked file size", "%d bytes for %d vertices" % [result.bytes, result.vertices])

	DirAccess.remove_absolute(OUT_PATH)
	DirAccess.remove_absolute(OUT_PATH.get_base_dir())

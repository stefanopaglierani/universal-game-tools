## Tests for UPTGMeshBuilder (criterion A6).
extends RefCounted


func _small() -> UPTGConfig:
	var c := UPTGConfig.new()
	c.grid_cells_x = 96
	c.grid_cells_z = 64
	c.cell_size = 8.0
	return c


func run(t: Object) -> void:
	var config := _small()
	var data := UPTGHeightfieldGenerator.generate(config)
	var mesh := UPTGMeshBuilder.build(data, config)
	t.check("A6 build() returns a mesh with one surface", mesh != null and mesh.get_surface_count() == 1)
	if mesh == null:
		return
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var vcount: int = data.vertex_count_x * data.vertex_count_z

	t.check("A6 one vertex per grid point", vertices.size() == vcount and normals.size() == vcount and uvs.size() == vcount and colors.size() == vcount, vertices.size())
	t.check("A6 expected triangle count (2 per cell)", indices.size() == data.grid_cells_x * data.grid_cells_z * 6, "%d triangles" % (indices.size() / 3))
	var min_i: int = vcount
	var max_i: int = -1
	for i in indices:
		min_i = mini(min_i, i)
		max_i = maxi(max_i, i)
	t.check("A6 indices within bounds", min_i == 0 and max_i == vcount - 1, "%d .. %d" % [min_i, max_i])

	var finite := true
	var unit := true
	var match_data := true
	var uv_ok := true
	for i in vcount:
		var v: Vector3 = vertices[i]
		var n: Vector3 = normals[i]
		if not (v.is_finite() and n.is_finite()):
			finite = false
		if absf(n.length() - 1.0) > 1e-4 or n.y <= 0.0:
			unit = false
		var ix: int = i % data.vertex_count_x
		var iz: int = i / data.vertex_count_x
		if not v.is_equal_approx(data.get_vertex_position(ix, iz)):
			match_data = false
		if not uvs[i].is_equal_approx(Vector2(v.x, v.z) / config.uv_tile_size):
			uv_ok = false
	t.check("A6 no NaN or infinite values", finite)
	t.check("A6 normals are unit length and point up", unit)
	t.check("A6 vertices match the terrain data", match_data)
	t.check("A6 UVs are the planar projection in meters / uv_tile_size", uv_ok)

	# Winding: front faces are clockwise seen from above (verified in M0),
	# so (c - a) x (b - a) points up for every triangle (a, b, c).
	var winding_ok := true
	var diagonal_ok := true
	for k in range(0, indices.size(), 3):
		var a: Vector3 = vertices[indices[k]]
		var b: Vector3 = vertices[indices[k + 1]]
		var c: Vector3 = vertices[indices[k + 2]]
		if (c - a).cross(b - a).y <= 0.0:
			winding_ok = false
	for k in range(0, indices.size(), 6):
		# Both triangles of a cell share the (ix + 1, iz)-(ix, iz + 1) diagonal.
		var i10: int = indices[k + 1]
		var i01: int = indices[k + 2]
		if i01 - i10 != data.vertex_count_x - 1 or indices[k + 3] != i10 or indices[k + 5] != i01:
			diagonal_ok = false
	t.check("A6 all triangles are clockwise seen from +Y", winding_ok)
	t.check("A6 all cells split on the (ix + 1, iz)-(ix, iz + 1) diagonal", diagonal_ok)

	var aabb: AABB = mesh.get_aabb()
	t.check("A6 mesh bounds match the terrain size and heights",
		is_equal_approx(aabb.size.x, data.size.x) and is_equal_approx(aabb.size.z, data.size.y)
		and is_equal_approx(aabb.position.y, data.min_height) and is_equal_approx(aabb.end.y, data.max_height), aabb)

	# Vertex colors
	t.check("vertex color: sand at the beach", UPTGMeshBuilder.vertex_color(0.5, Vector3.UP, config).is_equal_approx(config.sand_color))
	t.check("vertex color: grass inland on flat ground", UPTGMeshBuilder.vertex_color(10.0, Vector3.UP, config).is_equal_approx(config.grass_color))
	t.check("vertex color: rock above rock_height", UPTGMeshBuilder.vertex_color(config.rock_height + 2.0, Vector3.UP, config).is_equal_approx(config.rock_color))
	t.check("vertex color: rock on steep slopes", UPTGMeshBuilder.vertex_color(10.0, Vector3(1.0, 1.0, 0.0).normalized(), config).is_equal_approx(config.rock_color))
	# Mesh vertex colors are stored with 8 bits per channel: compare within 1/255.
	var c0: Color = colors[0]
	var sand: Color = config.sand_color
	var close: bool = absf(c0.r - sand.r) <= 1.0 / 255.0 and absf(c0.g - sand.g) <= 1.0 / 255.0 and absf(c0.b - sand.b) <= 1.0 / 255.0
	t.check("border vertex (sea floor) is sand in the mesh", close, "%s vs %s" % [c0, sand])

	var t0: int = Time.get_ticks_usec()
	var big := UPTGConfig.new()
	var big_data := UPTGHeightfieldGenerator.generate(big)
	var t1: int = Time.get_ticks_usec()
	UPTGMeshBuilder.build(big_data, big)
	var t2: int = Time.get_ticks_usec()
	t.info("timing 256x256 (default config)", "height field %.1f ms, mesh %.1f ms" % [(t1 - t0) / 1000.0, (t2 - t1) / 1000.0])

class_name UPTGCollisionBuilder
extends RefCounted
## Builds the terrain collision shape from a [UPTGTerrainData] (architecture 0.2, section 11).
##
## Static functions only; no nodes are created here. [code]HEIGHTMAP[/code] returns a
## [HeightMapShape3D] whose heights are divided by [member UPTGTerrainData.cell_size]: the
## [CollisionShape3D] holding it must use the uniform scale returned by [method get_shape_scale].
## [code]TRIMESH[/code] returns a [ConcavePolygonShape3D] with the same triangles as the mesh.
## [code]NONE[/code] returns [code]null[/code].


## Returns the shape for [param mode], or [code]null[/code] for [code]NONE[/code] and on error
## (reported with [method @GlobalScope.push_error]).
static func build(data: UPTGTerrainData, mode: UPTGConfig.CollisionMode) -> Shape3D:
	if mode == UPTGConfig.CollisionMode.NONE:
		return null
	if data == null or data.vertex_count_x < 2 or data.vertex_count_z < 2 \
			or data.heights.size() != data.vertex_count_x * data.vertex_count_z:
		push_error("UPTG: UPTGCollisionBuilder.build() needs consistent terrain data")
		return null
	match mode:
		UPTGConfig.CollisionMode.HEIGHTMAP:
			return _build_heightmap(data)
		UPTGConfig.CollisionMode.TRIMESH:
			return _build_trimesh(data)
	push_error("UPTG: unknown collision mode %d" % mode)
	return null


## Scale for the [CollisionShape3D] that holds the shape built for [param mode]:
## uniform [code]cell_size[/code] for [code]HEIGHTMAP[/code], one otherwise.
static func get_shape_scale(data: UPTGTerrainData, mode: UPTGConfig.CollisionMode) -> Vector3:
	if mode == UPTGConfig.CollisionMode.HEIGHTMAP and data != null:
		return Vector3.ONE * data.cell_size
	return Vector3.ONE


static func _build_heightmap(data: UPTGTerrainData) -> HeightMapShape3D:
	# The shape spaces samples 1 unit apart and is centered on its origin; map_data
	# follows iz * width + ix (all verified in Milestone 0).
	var map := PackedFloat32Array()
	map.resize(data.heights.size())
	var inv_cell: float = 1.0 / data.cell_size
	for i in data.heights.size():
		map[i] = data.heights[i] * inv_cell
	var shape := HeightMapShape3D.new()
	shape.map_width = data.vertex_count_x
	shape.map_depth = data.vertex_count_z
	shape.map_data = map
	return shape


static func _build_trimesh(data: UPTGTerrainData) -> ConcavePolygonShape3D:
	# Same triangles and winding as UPTGMeshBuilder: (00, 10, 01) and (10, 11, 01),
	# clockwise seen from +Y, so backface_collision can stay off.
	var vx: int = data.vertex_count_x
	var faces := PackedVector3Array()
	faces.resize(data.grid_cells_x * data.grid_cells_z * 6)
	var row0 := PackedVector3Array()
	row0.resize(vx)
	var row1 := PackedVector3Array()
	row1.resize(vx)
	for ix in vx:
		row1[ix] = data.get_vertex_position(ix, 0)
	var k: int = 0
	for iz in data.grid_cells_z:
		var swap := row0
		row0 = row1
		row1 = swap
		for ix in vx:
			row1[ix] = data.get_vertex_position(ix, iz + 1)
		for ix in data.grid_cells_x:
			faces[k] = row0[ix]
			faces[k + 1] = row0[ix + 1]
			faces[k + 2] = row1[ix]
			faces[k + 3] = row0[ix + 1]
			faces[k + 4] = row1[ix + 1]
			faces[k + 5] = row1[ix]
			k += 6
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	return shape

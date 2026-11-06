class_name UPTGMeshBuilder
extends RefCounted
## Builds the terrain [ArrayMesh] from a [UPTGTerrainData] (architecture 0.2, section 10).
##
## Static functions only. One indexed surface, one vertex per grid point.
## Normals come from the height field, UVs are a planar projection in meters,
## vertex colors blend sand, grass and rock by height and slope.

## Height range, in meters, over which sand and grass, and grass and rock by height, blend.
const COLOR_BLEND_HEIGHT: float = 1.0
## Slope range, in degrees, over which grass and rock blend.
const COLOR_BLEND_SLOPE: float = 5.0


## Returns the mesh, or [code]null[/code] (with [method @GlobalScope.push_error]) when
## [param data] or [param config] is missing or [param data] is inconsistent.
static func build(data: UPTGTerrainData, config: UPTGConfig) -> ArrayMesh:
	if data == null or config == null:
		push_error("UPTG: UPTGMeshBuilder.build() needs terrain data and a configuration")
		return null
	var vx: int = data.vertex_count_x
	var vz: int = data.vertex_count_z
	var count: int = vx * vz
	if vx < 2 or vz < 2 or data.heights.size() != count:
		push_error("UPTG: terrain data is inconsistent (%d x %d vertices, %d heights)" % [vx, vz, data.heights.size()])
		return null

	var vertices := PackedVector3Array()
	vertices.resize(count)
	var normals := PackedVector3Array()
	normals.resize(count)
	var uvs := PackedVector2Array()
	uvs.resize(count)
	var colors := PackedColorArray()
	colors.resize(count)

	var inv_tile: float = 1.0 / config.uv_tile_size
	for iz in vz:
		for ix in vx:
			var i: int = iz * vx + ix
			var p: Vector3 = data.get_vertex_position(ix, iz)
			var n: Vector3 = data.get_vertex_normal(ix, iz)
			vertices[i] = p
			normals[i] = n
			uvs[i] = Vector2(p.x, p.z) * inv_tile
			colors[i] = vertex_color(p.y - data.sea_level, n, config)

	# Two triangles per cell, clockwise seen from +Y, split on the (ix + 1, iz)-(ix, iz + 1)
	# diagonal used by HeightMapShape3D (verified in Milestone 0).
	var indices := PackedInt32Array()
	indices.resize(data.grid_cells_x * data.grid_cells_z * 6)
	var k: int = 0
	for iz in data.grid_cells_z:
		for ix in data.grid_cells_x:
			var i00: int = iz * vx + ix
			var i10: int = i00 + 1
			var i01: int = i00 + vx
			var i11: int = i01 + 1
			indices[k] = i00
			indices[k + 1] = i10
			indices[k + 2] = i01
			indices[k + 3] = i10
			indices[k + 4] = i11
			indices[k + 5] = i01
			k += 6

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Vertex color for a point [param height_above_sea] meters above sea level with unit normal [param normal].
## Sand up to [member UPTGConfig.beach_height] (including the sea floor, whatever the slope),
## otherwise rock above [member UPTGConfig.rock_height] or on slopes steeper than
## [member UPTGConfig.rock_slope_degrees], grass elsewhere.
static func vertex_color(height_above_sea: float, normal: Vector3, config: UPTGConfig) -> Color:
	var slope: float = rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
	var sand: float = 1.0 - smoothstep(config.beach_height, config.beach_height + COLOR_BLEND_HEIGHT, height_above_sea)
	var rock: float = maxf(
		smoothstep(config.rock_slope_degrees - COLOR_BLEND_SLOPE, config.rock_slope_degrees, slope),
		smoothstep(config.rock_height, config.rock_height + COLOR_BLEND_HEIGHT, height_above_sea))
	return config.grass_color.lerp(config.rock_color, rock).lerp(config.sand_color, sand)

class_name UPRGRoadBuilder
extends RefCounted
## Builds the visible road and its collision. Each cross-section has 4 points:
## outer shoulder, pavement edge, pavement edge, outer shoulder.


## Returns the road surface. Triangles are clockwise seen from above, as in Godot's front faces.
static func build_mesh(road: UPRGRoadConfig, shape: UPRGRoadShape) -> ArrayMesh:
	var count := shape.path.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	vertices.resize(count * 4)
	normals.resize(count * 4)
	uvs.resize(count * 4)
	var half := road.width * 0.5
	var offsets: Array[float] = [-half - road.shoulder, -half, half, half + road.shoulder]
	var drops: Array[float] = [road.sink, 0.0, 0.0, road.sink]
	var across: Array[float] = [0.0, 0.1, 0.9, 1.0]
	for i in count:
		var p := shape.path[i]
		var tangent := (shape.path[mini(i + 1, count - 1)] - shape.path[maxi(i - 1, 0)]).normalized()
		var side := Vector2(tangent.y, -tangent.x)
		for j in 4:
			var at := p + side * offsets[j]
			vertices[i * 4 + j] = Vector3(at.x, shape.heights[i] - drops[j], at.y)
			normals[i * 4 + j] = Vector3.UP
			uvs[i * 4 + j] = Vector2(across[j], i * road.sample_spacing / road.uv_length)
	var indices := PackedInt32Array()
	for i in count - 1:
		for j in 3:
			var a := i * 4 + j
			var b := a + 1
			var c := a + 4
			var d := c + 1
			indices.append_array([a, b, d, a, d, c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = road.road_color
	material.roughness = 0.95
	mesh.surface_set_material(0, material)
	return mesh


## Collision made of the same triangles as [param mesh].
static func build_collision(mesh: ArrayMesh) -> ConcavePolygonShape3D:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var faces := PackedVector3Array()
	faces.resize(indices.size())
	for i in indices.size():
		faces[i] = vertices[indices[i]]
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	return shape

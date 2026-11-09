class_name UPRGRoadBuilder
extends RefCounted
## Builds the visible road and its collision. Each cross-section has 4 points:
## outer shoulder, pavement edge, pavement edge, outer shoulder.


## Returns the road surface. Triangles are clockwise seen from above, as in Godot's front faces.
## The samples inside [param gaps] are left out: junction surfaces replace them.
static func build_mesh(road: UPRGRoadConfig, shape: UPRGRoadShape, skin: UPRGSkin = null, errors: PackedStringArray = PackedStringArray(),
		gaps: Array[Vector2i] = []) -> ArrayMesh:
	var count := shape.path.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	vertices.resize(count * 4)
	normals.resize(count * 4)
	uvs.resize(count * 4)
	var across: Array[float] = [0.0, 0.1, 0.9, 1.0]
	for i in count:
		var points := section(road, shape, i)
		for j in 4:
			vertices[i * 4 + j] = points[j]
			normals[i * 4 + j] = Vector3.UP
			uvs[i * 4 + j] = Vector2(across[j], i * road.sample_spacing / road.uv_length)
	var indices := PackedInt32Array()
	for i in count - 1:
		if gaps.any(func(gap: Vector2i) -> bool: return i >= gap.x and i < gap.y):
			continue
		for j in 3:
			var a := i * 4 + j
			var b := a + 1
			var c := a + 4
			var d := c + 1
			indices.append_array([a, b, d, a, d, c])
	return _mesh_from(vertices, normals, uvs, indices, _material(road, skin, errors))


## The 4 points of cross-section [param i]: outer shoulder, pavement edge, pavement edge, outer shoulder.
static func section(road: UPRGRoadConfig, shape: UPRGRoadShape, i: int) -> Array[Vector3]:
	var count := shape.path.size()
	var p := shape.path[i]
	var tangent := (shape.path[mini(i + 1, count - 1)] - shape.path[maxi(i - 1, 0)]).normalized()
	var side := Vector2(tangent.y, -tangent.x)
	var half := road.width * 0.5
	var offsets: Array[float] = [-half - road.shoulder, -half, half, half + road.shoulder]
	# The outer points stay just above the leveled terrain.
	var outer := road.sink * 0.5
	var drops: Array[float] = [outer, 0.0, 0.0, outer]
	var points: Array[Vector3] = []
	for j in 4:
		var at := p + side * offsets[j]
		points.append(Vector3(at.x, shape.heights[i] - drops[j], at.y))
	return points


## The surface shared by the roads of a junction: it starts exactly where each arm ends,
## with rounded corners between the arms. Same winding as [method build_mesh].
static func build_junction_mesh(junction: Dictionary, roads: Array[UPRGRoadConfig], plans: Array[UPRGRoadShape], skin: UPRGSkin = null,
		errors: PackedStringArray = PackedStringArray()) -> ArrayMesh:
	const CORNER_STEPS := 6
	var center: Vector2 = junction.center
	var arms: Array = junction.arms
	var ring := PackedVector3Array()
	for a in arms.size():
		var points := _arm_points(arms[a], roads, plans, center)
		ring.append_array(PackedVector3Array(points))
		var next: Dictionary = arms[(a + 1) % arms.size()]
		var from: Vector3 = points[3]
		var to: Vector3 = _arm_points(next, roads, plans, center)[0]
		var control := _corner_control(from, _arm_direction(arms[a], plans), to, _arm_direction(next, plans))
		var start := Vector2(from.x, from.z)
		var finish := Vector2(to.x, to.z)
		for s in range(1, CORNER_STEPS):
			var t := float(s) / CORNER_STEPS
			var flat := start.lerp(control, t).lerp(control.lerp(finish, t), t)
			ring.append(Vector3(flat.x, junction.height, flat.y))
	var road: UPRGRoadConfig = roads[junction.roads.keys().min()]
	var vertices := PackedVector3Array([Vector3(center.x, junction.height, center.y)])
	vertices.append_array(ring)
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for v in vertices:
		normals.append(Vector3.UP)
		uvs.append(Vector2(v.x / road.width, v.z / road.uv_length))
	var indices := PackedInt32Array()
	for i in ring.size():
		indices.append_array([0, i + 1, (i + 1) % ring.size() + 1])
	return _mesh_from(vertices, normals, uvs, indices, _material(road, skin, errors))


## The cross-section at the end of an arm, in clockwise order around the junction seen from above.
static func _arm_points(arm: Dictionary, roads: Array[UPRGRoadConfig], plans: Array[UPRGRoadShape], center: Vector2) -> Array[Vector3]:
	var points := section(roads[arm.road], plans[arm.road], arm.end)
	var path := plans[arm.road].path
	var outward: Vector2 = path[arm.end] - center
	var clockwise := Vector2(-outward.y, outward.x)
	if Vector2(points[0].x, points[0].z).dot(clockwise) > Vector2(points[3].x, points[3].z).dot(clockwise):
		points.reverse()
	return points


static func _arm_direction(arm: Dictionary, plans: Array[UPRGRoadShape]) -> Vector2:
	var path := plans[arm.road].path
	return ((path[clampi(arm.end + 1, 0, path.size() - 1)] - path[clampi(arm.end - 1, 0, path.size() - 1)]) * float(arm.dir)).normalized()


## Point the rounded corner bends toward: where the two road edges would meet.
static func _corner_control(from: Vector3, from_direction: Vector2, to: Vector3, to_direction: Vector2) -> Vector2:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var hit: Variant = Geometry2D.line_intersects_line(a, from_direction, b, to_direction)
	if hit == null or ((hit as Vector2) - a).dot(from_direction) > 0.0 or ((hit as Vector2) - b).dot(to_direction) > 0.0:
		return (a + b) * 0.5
	return hit


static func _material(road: UPRGRoadConfig, skin: UPRGSkin, errors: PackedStringArray) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = road.road_color * (skin.road_tint if skin != null else Color.WHITE)
	material.roughness = 0.95
	if skin != null:
		material.albedo_texture = UPRGSkin.load_texture(skin.road_texture_path, errors)
	return material


static func _mesh_from(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array,
		material: StandardMaterial3D) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
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

class_name UPRGPlaceBuilder
extends RefCounted
## Levels the ground of a place and builds its houses as one mesh with one collision.

## Levels the ground around the place to its average height. Returns the level used.
static func level_ground(place: UPRGPlace, grid: UPRGTerrainGrid) -> float:
	var total := 0.0
	var count := 0
	for iz in grid.cells_z + 1:
		for ix in grid.cells_x + 1:
			if Vector2(grid.vertex_x(ix), grid.vertex_z(iz)).distance_to(place.center) <= place.radius:
				total += grid.heights[grid.index(ix, iz)]
				count += 1
	var level := grid.height_at(place.center) if count == 0 else total / count
	level = maxf(level, grid.sea_level + 1.5)
	var edit := UPRGTerrainEdit.new()
	edit.kind = UPRGTerrainEdit.Kind.LEVEL
	edit.center = place.center
	edit.radius = place.radius
	edit.blend = place.blend
	edit.height = level - grid.sea_level
	edit.apply(grid)
	return level


## Chooses building footprints on a grid of plots, away from the roads. Each is
## {center: Vector2, size: Vector2, wall: float, wall_color: Color, roof_color: Color}.
static func plan_buildings(place: UPRGPlace, road_paths: Array[PackedVector2Array], road_clearances: PackedFloat32Array) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = place.seed_value
	var plot := place.building_size.y + place.spacing
	var cells := int(ceil(place.radius / plot))
	var plots: Array[Vector2] = []
	for iz in range(-cells, cells + 1):
		for ix in range(-cells, cells + 1):
			var at := place.center + Vector2(ix, iz) * plot
			if at.distance_to(place.center) + place.building_size.y * 0.71 > place.radius:
				continue
			if _clear_of_roads(at, place.building_size.y * 0.71, road_paths, road_clearances):
				plots.append(at)
	# Fisher-Yates with the local generator, so that the same seed gives the same village.
	for i in range(plots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := plots[i]
		plots[i] = plots[j]
		plots[j] = swap
	var buildings: Array[Dictionary] = []
	for i in mini(place.building_count, plots.size()):
		buildings.append({
			"center": plots[i],
			"size": Vector2(rng.randf_range(place.building_size.x, place.building_size.y), rng.randf_range(place.building_size.x, place.building_size.y)),
			"wall": rng.randf_range(place.wall_height.x, place.wall_height.y),
			"wall_color": place.wall_colors[rng.randi_range(0, place.wall_colors.size() - 1)],
			"roof_color": place.roof_colors[rng.randi_range(0, place.roof_colors.size() - 1)],
		})
	return buildings


static func _clear_of_roads(at: Vector2, half_size: float, road_paths: Array[PackedVector2Array], clearances: PackedFloat32Array) -> bool:
	for r in road_paths.size():
		for p in road_paths[r]:
			if p.distance_to(at) < clearances[r] + half_size:
				return false
	return true


## Returns one mesh with every building, or null when there are none. Triangles are clockwise from outside.
static func build_mesh(buildings: Array[Dictionary], grid: UPRGTerrainGrid, uv_size: float) -> ArrayMesh:
	if buildings.is_empty():
		return null
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	for b: Dictionary in buildings:
		var ground := grid.height_at(b.center)
		var half: Vector2 = b.size * 0.5
		var x0: float = b.center.x - half.x
		var x1: float = b.center.x + half.x
		var z0: float = b.center.y - half.y
		var z1: float = b.center.y + half.y
		# Walls start below the ground, so no gap shows on uneven terrain.
		var y0: float = ground - 1.0
		var y1: float = ground + b.wall
		var ridge: float = y1 + minf(half.x, half.y) * 0.7
		var wall: Color = b.wall_color
		var roof: Color = b.roof_color
		var p00 := Vector3(x0, y1, z0)
		var p10 := Vector3(x1, y1, z0)
		var p01 := Vector3(x0, y1, z1)
		var p11 := Vector3(x1, y1, z1)
		_quad(v, n, c, uv, Vector3(x0, y0, z1), p01, p11, Vector3(x1, y0, z1), wall, uv_size)
		_quad(v, n, c, uv, Vector3(x1, y0, z0), p10, p00, Vector3(x0, y0, z0), wall, uv_size)
		_quad(v, n, c, uv, Vector3(x1, y0, z1), p11, p10, Vector3(x1, y0, z0), wall, uv_size)
		_quad(v, n, c, uv, Vector3(x0, y0, z0), p00, p01, Vector3(x0, y0, z1), wall, uv_size)
		var r0 := Vector3((x0 + x1) * 0.5, ridge, z0)
		var r1 := Vector3((x0 + x1) * 0.5, ridge, z1)
		_quad(v, n, c, uv, p00, r0, r1, p01, roof, uv_size)
		_quad(v, n, c, uv, p11, r1, r0, p10, roof, uv_size)
		_triangle(v, n, c, uv, p10, r0, p00, wall, uv_size)
		_triangle(v, n, c, uv, p01, r1, p11, wall, uv_size)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _quad(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, uv: PackedVector2Array,
		a: Vector3, b: Vector3, d: Vector3, e: Vector3, color: Color, uv_size: float) -> void:
	_triangle(v, n, c, uv, a, b, d, color, uv_size)
	_triangle(v, n, c, uv, a, d, e, color, uv_size)


static func _triangle(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, uv: PackedVector2Array,
		a: Vector3, b: Vector3, d: Vector3, color: Color, uv_size: float) -> void:
	var normal := (d - a).cross(b - a).normalized()
	var u_axis := Vector3.UP.cross(normal).normalized() if absf(normal.y) < 0.99 else Vector3.RIGHT
	for p: Vector3 in [a, b, d]:
		v.append(p)
		n.append(normal)
		c.append(color)
		uv.append(Vector2(p.dot(u_axis), -p.y) / uv_size)

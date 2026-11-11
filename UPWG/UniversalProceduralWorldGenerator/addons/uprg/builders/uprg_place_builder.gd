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
	if place.streets:
		return _plan_along_streets(place, road_paths, road_clearances)
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
	_shuffle(plots, rng)
	var buildings: Array[Dictionary] = []
	for i in mini(place.building_count, plots.size()):
		buildings.append(_building(place, plots[i], rng))
	return buildings


## Room of one building plot, as used for buildings made from models too.
static func plot_room(place: UPRGPlace) -> float:
	return place.building_size.y + place.spacing * 0.6


## Plots on both sides of every road and street inside the place, each turned toward its street.
static func _plan_along_streets(place: UPRGPlace, road_paths: Array[PackedVector2Array], road_clearances: PackedFloat32Array) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = place.seed_value
	var room := plot_room(place)
	var free := PackedFloat32Array()
	for clearance in road_clearances:
		free.append(clearance - 0.5)
	var plots: Array[Dictionary] = []
	for r in road_paths.size():
		var path := road_paths[r]
		var walked := 0.0
		for i in path.size() - 1:
			walked += path[i].distance_to(path[i + 1])
			if walked < room + 1.0:
				continue
			walked = 0.0
			var along := (path[i + 1] - path[i]).normalized()
			var across := Vector2(-along.y, along.x)
			# +Z of a building is its front: it looks at the street on both sides.
			var yaw := atan2(-along.y, along.x)
			for side: float in [-1.0, 1.0]:
				var at := path[i] + across * side * (road_clearances[r] + room * 0.5)
				if at.distance_to(place.center) + room * 0.5 <= place.radius and _clear_of_roads(at, room * 0.5, road_paths, free):
					plots.append({"at": at, "yaw": yaw + (PI if side > 0.0 else 0.0)})
	_shuffle(plots, rng)
	var buildings: Array[Dictionary] = []
	for plot in plots:
		if buildings.size() >= place.building_count:
			break
		if buildings.all(func(b: Dictionary) -> bool: return (b.center as Vector2).distance_to(plot.at) >= room * 1.15):
			var building := _building(place, plot.at, rng)
			building.yaw = plot.yaw
			buildings.append(building)
	return buildings


## Fisher-Yates with the local generator, so that the same seed gives the same village.
static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap


static func _building(place: UPRGPlace, at: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"center": at,
		"size": Vector2(rng.randf_range(place.building_size.x, place.building_size.y), rng.randf_range(place.building_size.x, place.building_size.y)),
		"wall": rng.randf_range(place.wall_height.x, place.wall_height.y),
		"wall_color": place.wall_colors[rng.randi_range(0, place.wall_colors.size() - 1)],
		"roof_color": place.roof_colors[rng.randi_range(0, place.roof_colors.size() - 1)],
	}


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
		var first_vertex := v.size()
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
		_turn(v, n, first_vertex, b)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Turns the vertices of a building around its center, when it follows a street.
static func _turn(v: PackedVector3Array, n: PackedVector3Array, first_vertex: int, building: Dictionary) -> void:
	if not building.has("yaw"):
		return
	var turn := Basis(Vector3.UP, building.yaw)
	var pivot := Vector3(building.center.x, 0.0, building.center.y)
	for i in range(first_vertex, v.size()):
		v[i] = pivot + turn * (v[i] - pivot)
		n[i] = turn * n[i]


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

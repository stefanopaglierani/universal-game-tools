class_name UPRGWaterBuilder
extends RefCounted
## Digs lakes and rivers into the terrain and builds their water surfaces.
##
## A lake takes the lowest height around its basin as its level, digs the basin below it and
## fills it: the water can never spill, whatever the height of the ground (a lake on a mountain
## top works). A river follows its points; its water level never rises from the source to the
## mouth, and the bed is dug under it.

const SHORE_MARGIN := 0.4


## Digs [param water] into [param grid] and returns its plan: {kind, level (lakes), path and
## levels (rivers), ok, error}.
static func dig(water: UPRGWater, grid: UPRGTerrainGrid) -> Dictionary:
	var errors := water.validate()
	if not errors.is_empty():
		return {"ok": false, "error": "; ".join(errors)}
	if water.kind == UPRGWater.Kind.LAKE:
		return _dig_lake(water, grid)
	return _dig_river(water, grid)


static func _dig_lake(water: UPRGWater, grid: UPRGTerrainGrid) -> Dictionary:
	var center := water.points[0]
	if not grid.is_inside(center, water.size + water.shore + grid.cell_size):
		return {"ok": false, "error": "a lake is too close to the edge of the terrain"}
	# The level is just under the lowest ground on the rim, so the basin holds the water.
	var rim := INF
	for k in 48:
		var a := TAU * k / 48.0
		rim = minf(rim, grid.height_at(center + Vector2(cos(a), sin(a)) * (water.size + water.shore)))
	var level := rim - SHORE_MARGIN
	var bottom := level - water.depth
	var reach := water.size + water.shore
	for iz in grid.cells_z + 1:
		var z := grid.vertex_z(iz)
		if absf(z - center.y) > reach:
			continue
		for ix in grid.cells_x + 1:
			var p := Vector2(grid.vertex_x(ix), z)
			var d := p.distance_to(center)
			if d >= reach:
				continue
			var i := grid.index(ix, iz)
			# A bowl: deepest in the middle, rising to the level at the radius, then to the ground.
			var bowl := bottom + (level - bottom) * pow(d / water.size, 2.0) if d < water.size else lerpf(level - 0.3, grid.heights[i], smoothstep(0.0, 1.0, (d - water.size) / water.shore))
			grid.heights[i] = minf(grid.heights[i], bowl)
	return {"ok": true, "kind": "lake", "center": center, "radius": water.size, "level": level}


static func _dig_river(water: UPRGWater, grid: UPRGTerrainGrid) -> Dictionary:
	var spacing := maxf(grid.cell_size * 0.5, 1.0)
	var path := UPRGRoadShape.smooth_path(water.points, spacing)
	var half := water.size * 0.5
	for p in path:
		if not grid.is_inside(p, half + water.shore + grid.cell_size):
			return {"ok": false, "error": "a river leaves the terrain or comes too close to its edge"}
	var levels := PackedFloat32Array()
	levels.resize(path.size())
	var current := INF
	for i in path.size():
		# Lowest ground across the river here, so the water sits in the bed and never climbs.
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var across := Vector2(-tangent.y, tangent.x)
		var ground := minf(grid.height_at(path[i]), minf(grid.height_at(path[i] + across * half), grid.height_at(path[i] - across * half)))
		current = minf(current, ground - SHORE_MARGIN)
		levels[i] = current
	# On a coarse grid the bed is at least 1.5 cells wide on each side, so the ground between the
	# vertices cannot rise above the water.
	var bed_half := maxf(half, grid.cell_size * 1.5)
	var reach := bed_half + water.shore
	var best := {}
	for s in path.size() - 1:
		var a := path[s]
		var b := path[s + 1]
		var ix0 := clampi(floori((minf(a.x, b.x) - reach) / grid.cell_size + grid.cells_x / 2.0), 0, grid.cells_x)
		var ix1 := clampi(ceili((maxf(a.x, b.x) + reach) / grid.cell_size + grid.cells_x / 2.0), 0, grid.cells_x)
		var iz0 := clampi(floori((minf(a.y, b.y) - reach) / grid.cell_size + grid.cells_z / 2.0), 0, grid.cells_z)
		var iz1 := clampi(ceili((maxf(a.y, b.y) + reach) / grid.cell_size + grid.cells_z / 2.0), 0, grid.cells_z)
		var segment := b - a
		var length_sq := maxf(segment.length_squared(), 0.0001)
		for iz in range(iz0, iz1 + 1):
			for ix in range(ix0, ix1 + 1):
				var v := Vector2(grid.vertex_x(ix), grid.vertex_z(iz))
				var u := clampf((v - a).dot(segment) / length_sq, 0.0, 1.0)
				var d := v.distance_to(a + segment * u)
				if d >= reach:
					continue
				var key := grid.index(ix, iz)
				if not best.has(key) or d < best[key].x:
					best[key] = Vector2(d, lerpf(levels[s], levels[s + 1], u))
	for key: int in best:
		var hit: Vector2 = best[key]
		var bed := hit.y - water.depth * (1.0 - pow(minf(hit.x / bed_half, 1.0), 2.0)) - 0.3 if hit.x < bed_half else lerpf(hit.y - 0.3, grid.heights[key], smoothstep(0.0, 1.0, (hit.x - bed_half) / water.shore))
		grid.heights[key] = minf(grid.heights[key], bed)
	return {"ok": true, "kind": "river", "path": path, "levels": levels, "width": water.size}


## The water surface of a dug lake or river, as one mesh (clockwise from above).
static func build_mesh(plan: Dictionary, grid: UPRGTerrainGrid) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	if plan.kind == "lake":
		# The cells of the basin that are under the level, plus one ring of cells around them.
		var level: float = plan.level
		var center: Vector2 = plan.center
		var reach: float = plan.radius + grid.cell_size * 2.0
		for iz in grid.cells_z:
			for ix in grid.cells_x:
				var mid := Vector2(grid.vertex_x(ix) + grid.cell_size * 0.5, grid.vertex_z(iz) + grid.cell_size * 0.5)
				if mid.distance_to(center) > reach:
					continue
				var lowest := minf(minf(grid.heights[grid.index(ix, iz)], grid.heights[grid.index(ix + 1, iz)]),
					minf(grid.heights[grid.index(ix, iz + 1)], grid.heights[grid.index(ix + 1, iz + 1)]))
				if lowest >= level:
					continue
				var base := vertices.size()
				var x0 := grid.vertex_x(ix)
				var z0 := grid.vertex_z(iz)
				vertices.append_array([Vector3(x0, level, z0), Vector3(x0 + grid.cell_size, level, z0),
					Vector3(x0, level, z0 + grid.cell_size), Vector3(x0 + grid.cell_size, level, z0 + grid.cell_size)])
				indices.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2])
	else:
		var path: PackedVector2Array = plan.path
		var levels: PackedFloat32Array = plan.levels
		var half: float = plan.width * 0.5 + 0.5
		for i in path.size():
			var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
			var side := Vector2(tangent.y, -tangent.x)
			var l := path[i] - side * half
			var r := path[i] + side * half
			vertices.append(Vector3(l.x, levels[i], l.y))
			vertices.append(Vector3(r.x, levels[i], r.y))
		for i in path.size() - 1:
			var a := i * 2
			indices.append_array([a, a + 1, a + 3, a, a + 3, a + 2])
	if indices.is_empty():
		return null
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, water_material())
	return mesh


static func water_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.38, 0.52, 0.82)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	material.metallic_specular = 0.7
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

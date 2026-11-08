class_name UPRGRoadShape
extends RefCounted
## Plans a road on a terrain: smooth path, height profile, and the terrain edit under it.

## Centerline positions, evenly spaced.
var path: PackedVector2Array
## Road height at each centerline position.
var heights: PackedFloat32Array


## Builds the plan for [param road] on [param grid]. Returns null when the road leaves the terrain.
static func plan(road: UPRGRoadConfig, grid: UPRGTerrainGrid) -> UPRGRoadShape:
	var margin := road.width * 0.5 + road.shoulder + road.blend + grid.cell_size
	var shape := UPRGRoadShape.new()
	shape.path = _smooth_path(road.points, road.sample_spacing)
	for p in shape.path:
		if not grid.is_inside(p, margin):
			return null
	shape.heights = _profile(shape.path, road, grid)
	return shape


## Catmull-Rom curve through the points, resampled at equal distances.
static func _smooth_path(points: PackedVector2Array, spacing: float) -> PackedVector2Array:
	const STEPS := 24
	var dense := PackedVector2Array()
	var count := points.size()
	for i in count - 1:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, count - 1)]
		for s in STEPS:
			var t := float(s) / STEPS
			dense.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	dense.append(points[count - 1])

	var result := PackedVector2Array([dense[0]])
	var carried := 0.0
	for i in range(1, dense.size()):
		var a := dense[i - 1]
		var b := dense[i]
		var length := a.distance_to(b)
		var along := spacing - carried
		while along <= length and length > 0.0:
			result.append(a.lerp(b, along / length))
			along += spacing
		carried = fposmod(carried + length, spacing)
	if result[result.size() - 1].distance_to(dense[dense.size() - 1]) > spacing * 0.25:
		result.append(dense[dense.size() - 1])
	return result


static func _profile(path_points: PackedVector2Array, road: UPRGRoadConfig, grid: UPRGTerrainGrid) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(path_points.size())
	for i in path_points.size():
		h[i] = grid.height_at(path_points[i])
	var window := int(road.smoothing / road.sample_spacing / 2.0)
	h = _average(_average(h, window), window)
	var lowest := grid.sea_level + road.sea_clearance
	for i in h.size():
		h[i] = maxf(h[i], lowest)
	_limit_grade(h, road.max_grade * road.sample_spacing)
	h = _average(h, mini(window, 2))
	_limit_grade(h, road.max_grade * road.sample_spacing)
	return h


static func _average(values: PackedFloat32Array, window: int) -> PackedFloat32Array:
	if window <= 0:
		return values
	var out := PackedFloat32Array()
	out.resize(values.size())
	for i in values.size():
		var total := 0.0
		var count := 0
		for j in range(maxi(i - window, 0), mini(i + window, values.size() - 1) + 1):
			total += values[j]
			count += 1
		out[i] = total / count
	return out


static func _limit_grade(h: PackedFloat32Array, max_step: float) -> void:
	for i in range(1, h.size()):
		h[i] = clampf(h[i], h[i - 1] - max_step, h[i - 1] + max_step)
	for i in range(h.size() - 2, -1, -1):
		h[i] = clampf(h[i], h[i + 1] - max_step, h[i + 1] + max_step)


## Flattens the terrain under the road and blends it back to its own shape at the sides.
## Returns the number of vertices changed.
func apply_to_terrain(road: UPRGRoadConfig, grid: UPRGTerrainGrid) -> int:
	var flat := road.width * 0.5 + road.shoulder
	var reach := flat + road.blend
	var best := {}
	for s in path.size() - 1:
		var a := path[s]
		var b := path[s + 1]
		var ix0 := clampi(int(floor((minf(a.x, b.x) - reach) / grid.cell_size + grid.cells_x / 2.0)), 0, grid.cells_x)
		var ix1 := clampi(int(ceil((maxf(a.x, b.x) + reach) / grid.cell_size + grid.cells_x / 2.0)), 0, grid.cells_x)
		var iz0 := clampi(int(floor((minf(a.y, b.y) - reach) / grid.cell_size + grid.cells_z / 2.0)), 0, grid.cells_z)
		var iz1 := clampi(int(ceil((maxf(a.y, b.y) + reach) / grid.cell_size + grid.cells_z / 2.0)), 0, grid.cells_z)
		var segment := b - a
		var length_sq := segment.length_squared()
		for iz in range(iz0, iz1 + 1):
			for ix in range(ix0, ix1 + 1):
				var v := Vector2(grid.vertex_x(ix), grid.vertex_z(iz))
				var u := clampf((v - a).dot(segment) / length_sq, 0.0, 1.0)
				var distance := v.distance_to(a + segment * u)
				if distance >= reach:
					continue
				var key := grid.index(ix, iz)
				if not best.has(key) or distance < best[key].x:
					best[key] = Vector2(distance, lerpf(heights[s], heights[s + 1], u))
	for key: int in best:
		var hit: Vector2 = best[key]
		var k := smoothstep(0.0, 1.0, (hit.x - flat) / road.blend) if hit.x > flat else 0.0
		grid.heights[key] = lerpf(hit.y - road.sink, grid.heights[key], k)
	return best.size()

class_name UPRGRoadShape
extends RefCounted
## Plans a road on a terrain: smooth path, height profile, and the terrain edit under it.

## Centerline positions, evenly spaced.
var path: PackedVector2Array
## Road height at each centerline position.
var heights: PackedFloat32Array
## True when the road meets another one: its height changes abruptly next to the junctions.
var joined: bool = false
## A ring: the last position repeats the first one.
var closed: bool = false


## Builds the plan for [param road] on [param grid]. Returns null when the road leaves the terrain.
static func plan(road: UPRGRoadConfig, grid: UPRGTerrainGrid) -> UPRGRoadShape:
	var margin := road.width * 0.5 + road.shoulder + road.blend + grid.cell_size * 2.5
	var shape := UPRGRoadShape.new()
	shape.closed = road.closed
	shape.path = smooth_path(road.points, road.sample_spacing, road.closed)
	for p in shape.path:
		if not grid.is_inside(p, margin):
			return null
	shape.heights = _profile(shape.path, road, grid, road.closed)
	return shape


## Makes a ring start at position [param start], keeping the last position equal to the first.
func rotate_start(start: int) -> void:
	if not closed or start <= 0:
		return
	var n := path.size() - 1
	var new_path := PackedVector2Array()
	var new_heights := PackedFloat32Array()
	for k in n:
		new_path.append(path[(start + k) % n])
		new_heights.append(heights[(start + k) % n])
	new_path.append(new_path[0])
	new_heights.append(new_heights[0])
	path = new_path
	heights = new_heights


## Catmull-Rom curve through the points, resampled at equal distances. On a ring the curve
## goes on from the last point back to the first, and the last position repeats the first.
static func smooth_path(points: PackedVector2Array, spacing: float, closed: bool = false) -> PackedVector2Array:
	const STEPS := 24
	var dense := PackedVector2Array()
	var count := points.size()
	for i in (count if closed else count - 1):
		var p0 := points[posmod(i - 1, count)] if closed else points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[(i + 1) % count]
		var p3 := points[(i + 2) % count] if closed else points[mini(i + 2, count - 1)]
		for s in STEPS:
			var t := float(s) / STEPS
			dense.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	dense.append(points[0] if closed else points[count - 1])

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
	if closed:
		if result[result.size() - 1].distance_to(result[0]) < spacing * 0.5:
			result.remove_at(result.size() - 1)
		result.append(result[0])
	elif result[result.size() - 1].distance_to(dense[dense.size() - 1]) > spacing * 0.25:
		result.append(dense[dense.size() - 1])
	return result


static func _profile(path_points: PackedVector2Array, road: UPRGRoadConfig, grid: UPRGTerrainGrid, closed: bool = false) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(path_points.size())
	for i in path_points.size():
		h[i] = grid.height_at(path_points[i])
	var window := int(road.smoothing / road.sample_spacing / 2.0)
	h = _average(_average(h, window, closed), window, closed)
	var lowest := grid.sea_level + road.sea_clearance
	for i in h.size():
		h[i] = maxf(h[i], lowest)
	_limit_grade(h, road.max_grade * road.sample_spacing, closed)
	h = _average(h, mini(window, 2), closed)
	_limit_grade(h, road.max_grade * road.sample_spacing, closed)
	return h


static func _average(values: PackedFloat32Array, window: int, closed: bool = false) -> PackedFloat32Array:
	if window <= 0:
		return values
	var out := PackedFloat32Array()
	out.resize(values.size())
	# On a ring the last value repeats the first and the window wraps around.
	var ring := values.size() - 1
	for i in values.size():
		var total := 0.0
		var count := 0
		if closed:
			for j in range(i - window, i + window + 1):
				total += values[posmod(j, ring)]
				count += 1
		else:
			for j in range(maxi(i - window, 0), mini(i + window, values.size() - 1) + 1):
				total += values[j]
				count += 1
		out[i] = total / count
	if closed:
		out[ring] = out[0]
	return out


static func _limit_grade(h: PackedFloat32Array, max_step: float, closed: bool = false) -> void:
	if not closed:
		for i in range(1, h.size()):
			h[i] = clampf(h[i], h[i - 1] - max_step, h[i - 1] + max_step)
		for i in range(h.size() - 2, -1, -1):
			h[i] = clampf(h[i], h[i + 1] - max_step, h[i + 1] + max_step)
		return
	var ring := h.size() - 1
	for pass_number in 3:
		for k in range(1, ring * 2 + 1):
			h[k % ring] = clampf(h[k % ring], h[(k - 1) % ring] - max_step, h[(k - 1) % ring] + max_step)
		for k in range(ring * 2, 0, -1):
			h[(k - 1) % ring] = clampf(h[(k - 1) % ring], h[k % ring] - max_step, h[k % ring] + max_step)
	h[ring] = h[0]


## Records how this road flattens the terrain and blends it back to its own shape at the sides.
## [param targets] maps a vertex to Vector3(blend, height, distance): the road that leaves the
## vertex least of its own shape wins, so that one road's slope never covers another road.
func collect_terrain(road: UPRGRoadConfig, grid: UPRGTerrainGrid, targets: Dictionary) -> void:
	# The leveled strip extends past the road by more than one cell diagonal, so that no terrain
	# triangle crosses the road edge and the edge stays clean on a coarse grid.
	var flat := road.width * 0.5 + road.shoulder + grid.cell_size * 1.5
	var reach := flat + road.blend
	var best := {}
	var sag := _sag(road, grid)
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
					best[key] = Vector2(distance, lerpf(heights[s] - sag[s], heights[s + 1] - sag[s + 1], u))
	for key: int in best:
		var hit: Vector2 = best[key]
		var k := smoothstep(0.0, 1.0, (hit.x - flat) / road.blend) if hit.x > flat else 0.0
		var old: Variant = targets.get(key)
		if old == null or k < old.x or (is_equal_approx(k, old.x) and hit.x < old.z):
			targets[key] = Vector3(k, hit.y - road.sink, hit.x)


## How far the terrain must go lower where the road bends upward: a straight terrain triangle
## spanning the bend would otherwise rise through the pavement.
func _sag(road: UPRGRoadConfig, grid: UPRGTerrainGrid) -> PackedFloat32Array:
	var reach := int(ceil(grid.cell_size * 1.5 / road.sample_spacing))
	var last := path.size() - 1
	var sag := PackedFloat32Array()
	sag.resize(path.size())
	if not joined:
		return sag
	for i in path.size():
		sag[i] = maxf(0.0, (heights[maxi(i - reach, 0)] + heights[mini(i + reach, last)]) * 0.5 - heights[i])
	return sag


## Changes the terrain as recorded by [method collect_terrain]. Returns the number of vertices changed.
static func apply_targets(grid: UPRGTerrainGrid, targets: Dictionary) -> int:
	for key: int in targets:
		var target: Vector3 = targets[key]
		grid.heights[key] = lerpf(target.y, grid.heights[key], target.x)
	return targets.size()

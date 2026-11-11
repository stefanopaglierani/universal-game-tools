class_name UPRGRoadNetwork
extends RefCounted
## Finds where roads meet and makes them meet at one height. Each junction is a Dictionary:
## center (Vector2), height (float), trim (meters of road replaced by the junction surface),
## roads (road index -> sample index), arms (Array of {road, dir, end}, clockwise from above),
## spans (road index -> Vector2i of the samples the junction replaces).

## Hits closer than this belong to the same junction.
const MERGE_DISTANCE := 4.0
## Arms shorter than this are ignored: a road that overshoots another a little makes a T.
const MIN_ARM := 8.0
## Sharper meetings would need a very long junction surface.
const MIN_ANGLE_DEGREES := 25.0
## Length of the rounded corner between two arms.
const CORNER := 3.0
## Shortest distance over which a road rises or falls to a junction.
const MIN_REACH := 30.0
## Rounding of the slope next to a junction: meters on each side, and how many times.
const EASE_LENGTH := 6.0
const EASE_PASSES := 3
## Over this distance from a junction, the slope grows from RAMP_START of max_grade to all of it.
const RAMP_LENGTH := 16.0
const RAMP_START := 0.3


## Returns {ok: true, junctions: Array[Dictionary]} or {ok: false, error: String}.
## Changes the heights of [param plans] so that roads agree at every junction.
static func solve(roads: Array[UPRGRoadConfig], plans: Array[UPRGRoadShape]) -> Dictionary:
	var junctions: Array[Dictionary] = []
	for hit in _find_hits(roads, plans):
		_add_hit(junctions, hit)
	var kept: Array[Dictionary] = []
	for junction in junctions:
		var error := _build_arms(junction, roads, plans)
		if not error.is_empty():
			return {"ok": false, "error": error}
		if junction.arms.size() >= 2:
			kept.append(junction)
	var error := _fit_heights(kept, roads, plans)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "junctions": kept}


## Spans of samples of road [param road_index] that the junctions replace.
static func spans_of(road_index: int, junctions: Array[Dictionary]) -> Array[Vector2i]:
	var spans: Array[Vector2i] = []
	for junction in junctions:
		if junction.spans.has(road_index):
			spans.append(junction.spans[road_index])
	return spans


static func _find_hits(roads: Array[UPRGRoadConfig], plans: Array[UPRGRoadShape]) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	var boxes: Array[Rect2] = []
	for plan in plans:
		var box := Rect2(plan.path[0], Vector2.ZERO)
		for p in plan.path:
			box = box.expand(p)
		boxes.append(box)
	for a in roads.size():
		for b in range(a + 1, roads.size()):
			var reach := maxf(roads[a].width, roads[b].width)
			if not boxes[a].grow(reach).intersects(boxes[b].grow(reach)):
				continue
			_add_crossings(hits, a, b, plans[a].path, plans[b].path)
			# A ring has no ends: its first and last positions are the same point.
			if not roads[a].closed:
				_add_road_end(hits, a, b, plans[a].path, plans[b].path, roads[b].width * 0.5)
			if not roads[b].closed:
				_add_road_end(hits, b, a, plans[b].path, plans[a].path, roads[a].width * 0.5)
	return hits


static func _add_crossings(hits: Array[Dictionary], a: int, b: int, path_a: PackedVector2Array, path_b: PackedVector2Array) -> void:
	for i in path_a.size() - 1:
		var low := Vector2(minf(path_a[i].x, path_a[i + 1].x), minf(path_a[i].y, path_a[i + 1].y))
		var high := Vector2(maxf(path_a[i].x, path_a[i + 1].x), maxf(path_a[i].y, path_a[i + 1].y))
		for j in path_b.size() - 1:
			var p := path_b[j]
			var q := path_b[j + 1]
			if maxf(p.x, q.x) < low.x or minf(p.x, q.x) > high.x or maxf(p.y, q.y) < low.y or minf(p.y, q.y) > high.y:
				continue
			var at: Variant = Geometry2D.segment_intersects_segment(path_a[i], path_a[i + 1], p, q)
			if at != null:
				hits.append({"center": at, "samples": {a: _nearest_sample(path_a, at), b: _nearest_sample(path_b, at)}})


## A road that ends on another road.
static func _add_road_end(hits: Array[Dictionary], road: int, other: int, path: PackedVector2Array, other_path: PackedVector2Array, snap: float) -> void:
	for sample: int in [0, path.size() - 1]:
		var on_other := _closest_on_path(other_path, path[sample])
		if on_other.distance_to(path[sample]) <= snap:
			hits.append({"center": on_other, "samples": {road: sample, other: _nearest_sample(other_path, on_other)}})


static func _closest_on_path(path: PackedVector2Array, p: Vector2) -> Vector2:
	var best := path[0]
	for i in path.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1])
		if q.distance_squared_to(p) < best.distance_squared_to(p):
			best = q
	return best


static func _nearest_sample(path: PackedVector2Array, p: Vector2) -> int:
	var best := 0
	for i in path.size():
		if path[i].distance_squared_to(p) < path[best].distance_squared_to(p):
			best = i
	return best


static func _add_hit(junctions: Array[Dictionary], hit: Dictionary) -> void:
	for junction in junctions:
		if (junction.center as Vector2).distance_to(hit.center) < MERGE_DISTANCE:
			for road: int in hit.samples:
				if not junction.roads.has(road):
					junction.roads[road] = hit.samples[road]
			return
	junctions.append({"center": hit.center, "roads": hit.samples.duplicate(), "height": 0.0, "trim": 0.0, "arms": [], "spans": {}})


## Works out the arms, sorted clockwise from above, and how much of each road the junction replaces.
static func _build_arms(junction: Dictionary, roads: Array[UPRGRoadConfig], plans: Array[UPRGRoadShape]) -> String:
	var center: Vector2 = junction.center
	var arms: Array[Dictionary] = []
	for road: int in junction.roads:
		var sample: int = junction.roads[road]
		var path := plans[road].path
		var look := int(ceil(MIN_ARM / roads[road].sample_spacing))
		for dir: int in [-1, 1]:
			var ahead := sample + dir * look
			if ahead >= 0 and ahead < path.size():
				arms.append({"road": road, "dir": dir, "angle": (path[ahead] - center).angle()})
	while true:
		if arms.size() < 2:
			junction.arms = arms
			return ""
		arms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.angle < b.angle)
		var gap := TAU
		for i in arms.size():
			gap = minf(gap, fposmod(arms[(i + 1) % arms.size()].angle - arms[i].angle, TAU))
		if gap < deg_to_rad(MIN_ANGLE_DEGREES):
			return "two roads meet at less than %d degrees near (%.0f, %.0f)" % [MIN_ANGLE_DEGREES, center.x, center.y]
		var clearance := 0.0
		for arm in arms:
			clearance = maxf(clearance, roads[arm.road].width * 0.5 + roads[arm.road].shoulder)
		var trim := clearance / tan(gap * 0.5) + CORNER
		var whole: Array[Dictionary] = []
		for arm in arms:
			var end: int = junction.roads[arm.road] + arm.dir * int(ceil(trim / roads[arm.road].sample_spacing))
			if end >= 0 and end < plans[arm.road].path.size():
				arm.end = end
				whole.append(arm)
		if whole.size() == arms.size():
			junction.trim = trim
			break
		arms = whole
	junction.arms = arms
	var spans := {}
	for road: int in junction.roads:
		var sample: int = junction.roads[road]
		var low := sample
		var high := sample
		var has_low := false
		var has_high := false
		for arm in arms:
			if arm.road == road and arm.dir < 0:
				low = arm.end
				has_low = true
			elif arm.road == road:
				high = arm.end
				has_high = true
		if not has_low:
			low = 0
		if not has_high:
			high = plans[road].path.size() - 1
		spans[road] = Vector2i(low, high)
	junction.spans = spans
	return ""


## Roads listed first keep their height: the others come to them.
static func _fit_heights(junctions: Array[Dictionary], roads: Array[UPRGRoadConfig], plans: Array[UPRGRoadShape]) -> String:
	for junction in junctions:
		var first: int = junction.roads.keys().min()
		junction.height = plans[first].heights[junction.roads[first]]
	for r in roads.size():
		var ordered := _junctions_along(r, junctions)
		for m in range(1, ordered.size()):
			if ordered[m].spans[r].x <= ordered[m - 1].spans[r].y:
				var at := plans[r].path[ordered[m].roads[r]]
				return "two junctions are too close on one road near (%.0f, %.0f)" % [at.x, at.y]
	_settle_junctions(junctions, roads)
	for r in roads.size():
		var marks: Array[Dictionary] = []
		for junction in _junctions_along(r, junctions):
			marks.append({"span": junction.spans[r], "height": junction.height, "sample": junction.roads[r]})
		if marks.is_empty():
			continue
		if not _fit_road(roads[r], plans[r], marks):
			var at := plans[r].path[marks[0].sample]
			return "road %d cannot reach its junctions within max_grade near (%.0f, %.0f)" % [r, at.x, at.y]
	return ""


static func _junctions_along(road: int, junctions: Array[Dictionary]) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = junctions.filter(func(j: Dictionary) -> bool: return j.spans.has(road))
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.spans[road].x < b.spans[road].x)
	return ordered


## Moves junction heights until each road can climb from one junction to the next within its
## grade. The junction of the road listed last gives way.
static func _settle_junctions(junctions: Array[Dictionary], roads: Array[UPRGRoadConfig]) -> void:
	for pass_number in 32:
		var moved := false
		for r in roads.size():
			var ordered := _junctions_along(r, junctions)
			for m in range(1, ordered.size()):
				var a: Dictionary = ordered[m - 1]
				var b: Dictionary = ordered[m]
				var free: float = (b.spans[r].x - a.spans[r].y) * roads[r].sample_spacing
				var excess := absf(b.height - a.height) - roads[r].max_grade * maxf(free - RAMP_LENGTH, 0.0) * 0.9
				if excess <= 0.001:
					continue
				moved = true
				var direction := signf(b.height - a.height)
				var rank_a: int = a.roads.keys().min()
				var rank_b: int = b.roads.keys().min()
				var share_a := 0.5 if rank_a == rank_b else (0.0 if rank_a < rank_b else 1.0)
				a.height += direction * excess * share_a
				b.height -= direction * excess * (1.0 - share_a)
		if not moved:
			break


static func _fit_road(road: UPRGRoadConfig, plan: UPRGRoadShape, marks: Array[Dictionary]) -> bool:
	plan.joined = true
	var count := plan.heights.size()
	var original := plan.heights.duplicate()
	var pinned := PackedByteArray()
	pinned.resize(count)
	for i in count:
		var total := 0.0
		var weight := 0.0
		for m in marks:
			var span: Vector2i = m.span
			var delta: float = m.height - original[m.sample]
			var gap := maxi(maxi(span.x - i, i - span.y), 0) * road.sample_spacing
			var reach := maxf(MIN_REACH, absf(delta) / (road.max_grade * 0.5))
			var w := 1.0 - smoothstep(0.0, 1.0, gap / reach)
			total += delta * w
			weight += w
			if i >= span.x and i <= span.y:
				pinned[i] = 1
				plan.heights[i] = m.height
		if pinned[i] == 0 and weight > 0.0:
			plan.heights[i] = original[i] + total / maxf(weight, 1.0)
	var distance := _distance_to_pins(road, pinned)
	var steps := _allowed_steps(road, distance)
	_limit_grade(plan.heights, steps, pinned)
	# Only next to the junctions: the rest of the road keeps its own profile (and a ring stays
	# closed, since it starts far from any junction).
	var near := PackedByteArray()
	near.resize(count)
	for i in count:
		near[i] = 1 if pinned[i] == 0 and distance[i] <= RAMP_LENGTH + EASE_LENGTH * EASE_PASSES else 0
	for pass_number in EASE_PASSES:
		_ease(plan.heights, int(ceil(EASE_LENGTH / road.sample_spacing)), near)
	_limit_grade(plan.heights, steps, pinned)
	if plan.closed:
		plan.heights[count - 1] = plan.heights[0]
	for i in range(1, count):
		if absf(plan.heights[i] - plan.heights[i - 1]) > steps[i] + 0.001:
			return false
	return true


## Meters from each sample to the nearest sample a junction holds.
static func _distance_to_pins(road: UPRGRoadConfig, pinned: PackedByteArray) -> PackedFloat32Array:
	var count := pinned.size()
	var distance := PackedFloat32Array()
	distance.resize(count)
	var walked := INF
	for i in count:
		walked = 0.0 if pinned[i] == 1 else walked + road.sample_spacing
		distance[i] = walked
	walked = INF
	for i in range(count - 1, -1, -1):
		walked = 0.0 if pinned[i] == 1 else walked + road.sample_spacing
		distance[i] = minf(distance[i], walked)
	return distance


## Largest height change between sample i - 1 and i: small next to a junction, so that the road
## leaves its flat surface gradually.
static func _allowed_steps(road: UPRGRoadConfig, distance: PackedFloat32Array) -> PackedFloat32Array:
	var count := distance.size()
	var steps := PackedFloat32Array()
	steps.resize(count)
	for i in count:
		var nearest := minf(distance[i], distance[maxi(i - 1, 0)])
		steps[i] = road.max_grade * road.sample_spacing * lerpf(RAMP_START, 1.0, clampf(nearest / RAMP_LENGTH, 0.0, 1.0))
	return steps


static func _limit_grade(h: PackedFloat32Array, steps: PackedFloat32Array, pinned: PackedByteArray) -> void:
	for pass_number in 32:
		var moved := false
		for i in range(1, h.size()):
			moved = _pull(h, i, i - 1, steps[i], pinned) or moved
		for i in range(h.size() - 2, -1, -1):
			moved = _pull(h, i, i + 1, steps[i + 1], pinned) or moved
		if not moved:
			return


## Rounds the change of slope where a road enters a junction, so that a car stays on the ground.
## Only the samples marked in [param apply] change.
static func _ease(h: PackedFloat32Array, window: int, apply: PackedByteArray) -> void:
	var source := h.duplicate()
	for i in h.size():
		if apply[i] == 0:
			continue
		var total := 0.0
		var count := 0
		for j in range(maxi(i - window, 0), mini(i + window, h.size() - 1) + 1):
			total += source[j]
			count += 1
		h[i] = total / count


static func _pull(h: PackedFloat32Array, i: int, neighbor: int, step: float, pinned: PackedByteArray) -> bool:
	if pinned[i] == 1:
		return false
	var limited := clampf(h[i], h[neighbor] - step, h[neighbor] + step)
	if is_equal_approx(limited, h[i]):
		return false
	h[i] = limited
	return true

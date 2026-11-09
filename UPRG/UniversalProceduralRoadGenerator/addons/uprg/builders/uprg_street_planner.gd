class_name UPRGStreetPlanner
extends RefCounted
## Lays out the streets of a place: a main street joined to the nearest road, and side streets.

## Streets end this far inside the edge of the place, as a fraction of its radius.
const REACH := 0.85
## A road farther than this from the edge of the place is not joined to it.
const MAX_LINK := 150.0
## Below this distance from the center, the road counts as passing through the place.
const THROUGH := 12.0
const MIN_STREET := 18.0
## First side street, in meters from the start of the main street.
const FIRST_SIDE := 26.0
## Stretch of a new street that may stay close to the road it starts from.
const START_FREE := 14.0


## Returns the streets of [param place]. [param paths] and [param clearances] are the roads so far.
static func plan(place: UPRGPlace, paths: Array[PackedVector2Array], clearances: PackedFloat32Array) -> Array[UPRGRoadConfig]:
	var streets: Array[UPRGRoadConfig] = []
	var all_paths := paths.duplicate()
	var all_clearances := clearances.duplicate()
	var reach := place.radius * REACH
	for spine in _spines(place, paths, reach):
		var end := _clip(spine[0], spine[1], all_paths, all_clearances, place)
		var length: float = (spine[0] as Vector2).distance_to(end)
		if length < MIN_STREET:
			continue
		_add_street(streets, all_paths, all_clearances, place, spine[0], end)
		var along := ((end - spine[0]) as Vector2).normalized()
		var side := Vector2(-along.y, along.x)
		var distance := FIRST_SIDE
		while distance <= length - START_FREE:
			var from: Vector2 = spine[0] + along * distance
			for sign_value: float in [-1.0, 1.0]:
				var far := _circle_exit(from, side * sign_value, place.center, reach)
				if far == Vector2.INF:
					continue
				var branch_end := _clip(from, far, all_paths, all_clearances, place)
				if from.distance_to(branch_end) >= MIN_STREET:
					_add_street(streets, all_paths, all_clearances, place, from, branch_end)
			distance += place.street_spacing
	return streets


static func _spines(place: UPRGPlace, paths: Array[PackedVector2Array], reach: float) -> Array:
	var nearest := _nearest_on_roads(place.center, paths)
	if nearest.is_empty() or nearest.distance > place.radius + MAX_LINK:
		return [[place.center - Vector2.RIGHT * reach, place.center + Vector2.RIGHT * reach]]
	var start: Vector2 = nearest.point
	if nearest.distance < THROUGH:
		var tangent: Vector2 = nearest.tangent
		var across := Vector2(-tangent.y, tangent.x)
		return [[start, start + across * reach], [start, start - across * reach]]
	return [[start, place.center + (place.center - start).normalized() * reach]]


static func _nearest_on_roads(p: Vector2, paths: Array[PackedVector2Array]) -> Dictionary:
	var best := {}
	for path in paths:
		for i in path.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1])
			var distance := q.distance_to(p)
			if best.is_empty() or distance < best.distance:
				best = {"point": q, "distance": distance, "tangent": (path[i + 1] - path[i]).normalized()}
	return best


## Where a ray from [param from] leaves the circle, or Vector2.INF when it starts outside.
static func _circle_exit(from: Vector2, direction: Vector2, center: Vector2, radius: float) -> Vector2:
	var q := from - center
	var c := q.length_squared() - radius * radius
	if c >= 0.0:
		return Vector2.INF
	var b := q.dot(direction)
	return from + direction * (-b + sqrt(b * b - c))


## Shortens a street so that it stops before getting close to another road.
static func _clip(from: Vector2, to: Vector2, paths: Array[PackedVector2Array], clearances: PackedFloat32Array, place: UPRGPlace) -> Vector2:
	var length := from.distance_to(to)
	var along := (to - from) / length
	var half := place.street_width * 0.5 + 2.5
	var distance := START_FREE
	while distance <= length:
		var at := from + along * distance
		for r in paths.size():
			for p in paths[r]:
				if p.distance_to(at) < clearances[r] + half:
					return from + along * maxf(distance - 4.0, 0.0)
		distance += 2.0
	return to


static func _add_street(streets: Array[UPRGRoadConfig], paths: Array[PackedVector2Array], clearances: PackedFloat32Array,
		place: UPRGPlace, from: Vector2, to: Vector2) -> void:
	var street := UPRGRoadConfig.new()
	street.is_street = true
	street.points = PackedVector2Array([from, to])
	street.width = place.street_width
	street.shoulder = 0.5
	street.blend = 5.0
	street.smoothing = 8.0
	street.max_grade = 0.15
	street.road_color = place.street_color
	streets.append(street)
	paths.append(UPRGRoadShape.smooth_path(street.points, street.sample_spacing))
	clearances.append(street.width * 0.5 + street.shoulder + 2.0)

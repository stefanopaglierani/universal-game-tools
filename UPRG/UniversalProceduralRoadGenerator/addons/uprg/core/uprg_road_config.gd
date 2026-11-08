class_name UPRGRoadConfig
extends Resource
## One road, saved as a .tres preset. All distances are meters in the terrain's local space.

## Control points the road passes through, as (x, z). At least 2.
@export var points: PackedVector2Array = PackedVector2Array()
## Width of the paved surface.
@export_range(1.0, 60.0, 0.1) var width: float = 8.0
## Width of the sloped strip on each side of the pavement.
@export_range(0.1, 10.0, 0.1) var shoulder: float = 1.0
## Width of the strip where the terrain blends from the road back to its own shape.
@export_range(1.0, 100.0, 0.5) var blend: float = 12.0
## Distance between road cross-sections.
@export_range(0.5, 20.0, 0.1) var sample_spacing: float = 2.0
## Steepest allowed slope along the road (0.1 = 10%).
@export_range(0.01, 0.5, 0.01) var max_grade: float = 0.1
## Length over which road heights are averaged.
@export_range(0.0, 200.0, 1.0) var smoothing: float = 24.0
## Lowest road height above the sea.
@export_range(0.0, 50.0, 0.1) var sea_clearance: float = 1.5
## How far the terrain sits below the pavement, so it never pokes through.
@export_range(0.01, 2.0, 0.01) var sink: float = 0.1
## Road length covered by one repeat of the texture.
@export_range(0.5, 200.0, 0.5) var uv_length: float = 10.0
## Color of the pavement.
@export var road_color: Color = Color(0.22, 0.22, 0.24)


## Returns the list of errors, empty when the road is valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if points.size() < 2:
		errors.append("a road needs at least 2 points")
	for i in range(1, points.size()):
		if points[i].distance_to(points[i - 1]) < 0.01:
			errors.append("points %d and %d coincide" % [i - 1, i])
	if width <= 0.0 or shoulder <= 0.0 or blend <= 0.0 or sample_spacing <= 0.0 or max_grade <= 0.0 or uv_length <= 0.0:
		errors.append("width, shoulder, blend, sample_spacing, max_grade and uv_length must be positive")
	return errors

class_name UPRGWater
extends Resource
## A lake or a river, at any height: its own water surface, independent of the sea level.

enum Kind {
	LAKE, ## A basin dug around [member points][0] and filled up to a level that cannot spill.
	RIVER, ## A bed dug along [member points], with water that only flows downhill.
}

@export var kind: Kind = Kind.LAKE
## LAKE: the first point is the center. RIVER: the course, from the source to the mouth.
@export var points: PackedVector2Array = PackedVector2Array()
## LAKE: radius of the basin. RIVER: width of the water.
@export_range(1.0, 2000.0, 0.5) var size: float = 60.0
## Depth of the water at the center of the lake or of the river bed.
@export_range(0.2, 100.0, 0.1) var depth: float = 4.0
## Width of the shore that slopes from the water to the terrain.
@export_range(1.0, 300.0, 0.5) var shore: float = 20.0


## Returns the list of errors, empty when the water is valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if points.is_empty():
		errors.append("a lake or river needs at least one point")
	if kind == Kind.RIVER and points.size() < 2:
		errors.append("a river needs at least 2 points")
	return errors

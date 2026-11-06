class_name UPTGMountainRegion
extends Resource
## One configurable mountain region (architecture 0.2, section 5.2).
##
## Coordinates are normalized, so the mountain keeps its relative position when
## the grid size or [member UPTGConfig.cell_size] change.

## Normalized position on the terrain: (0, 0) is the -X/-Z corner, (1, 1) the +X/+Z corner.
@export var center: Vector2 = Vector2(0.5, 0.5)
## Radius, normalized to the shorter terrain side.
@export_range(0.01, 1.0, 0.001) var radius: float = 0.2
## Height added at the center, in meters.
@export_range(0.0, 2000.0, 0.1, "suffix:m") var peak_height: float = 40.0
## Falloff curve exponent: 1 is soft, higher values give a narrower peak.
@export_range(0.25, 8.0, 0.01) var falloff: float = 1.5


## Returns the list of validation errors (empty when valid). [param label] prefixes each message.
func validate(label: String = "mountain region") -> PackedStringArray:
	var errors := PackedStringArray()
	if not (is_finite(center.x) and is_finite(center.y)) or center.x < 0.0 or center.x > 1.0 or center.y < 0.0 or center.y > 1.0:
		errors.append("%s: center must be within 0..1 on both axes (got %s)" % [label, center])
	if not is_finite(radius) or radius < 0.01 or radius > 1.0:
		errors.append("%s: radius must be within 0.01..1.0 (got %s)" % [label, radius])
	if not is_finite(peak_height) or peak_height < 0.0 or peak_height > 2000.0:
		errors.append("%s: peak_height must be within 0..2000 m (got %s)" % [label, peak_height])
	if not is_finite(falloff) or falloff < 0.25 or falloff > 8.0:
		errors.append("%s: falloff must be within 0.25..8.0 (got %s)" % [label, falloff])
	return errors

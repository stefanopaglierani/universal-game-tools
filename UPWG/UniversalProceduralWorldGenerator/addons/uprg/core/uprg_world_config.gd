class_name UPRGWorldConfig
extends Resource
## Everything to add to a baked terrain, in one .tres file.
## Applied in this order: terrain edits, ground of the places, roads and streets, buildings.

@export var terrain_edits: Array[UPRGTerrainEdit] = []
@export var places: Array[UPRGPlace] = []
@export var roads: Array[UPRGRoadConfig] = []
## Optional appearance.
@export var skin: UPRGSkin
## Optional 3D models: buildings, trees, rocks, roadside objects.
@export var dressing: UPRGDressing
## Every road, ring and street must be joined to the others: a road on its own makes the bake fail.
@export var connected_roads: bool = false


## Returns the list of errors, empty when the world description is valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if terrain_edits.is_empty() and places.is_empty() and roads.is_empty():
		errors.append("nothing to add: no terrain edit, place or road")
	for item in terrain_edits + places + roads:
		if item == null:
			errors.append("the world description has an empty entry")
	if not errors.is_empty():
		return errors
	for place in places:
		errors.append_array(place.validate())
	for road in roads:
		errors.append_array(road.validate())
	return errors

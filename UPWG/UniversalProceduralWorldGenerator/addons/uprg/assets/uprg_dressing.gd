class_name UPRGDressing
extends Resource
## How many 3D models to put in a world and how far they stay visible.

## Folder written by tools/uprg_library.gd.
@export var library_path: String = "res://library"
## Same seed, same world.
@export var seed_value: int = 1
## Objects per hectare (100 x 100 m) of suitable land.
@export_range(0.0, 200.0, 0.1) var tree_density: float = 5.0
@export_range(0.0, 200.0, 0.1) var plant_density: float = 3.0
@export_range(0.0, 200.0, 0.1) var bush_density: float = 12.0
@export_range(0.0, 200.0, 0.1) var rock_density: float = 0.7
## Meters between lamps along a road. 0 for none.
@export_range(0.0, 1000.0, 1.0) var lamp_spacing: float = 80.0
## Meters between barriers and small objects along a road. 0 for none.
@export_range(0.0, 1000.0, 1.0) var roadside_spacing: float = 45.0
## Containers, barrels and small objects around each place.
@export_range(0, 100, 1) var place_props: int = 8
## Distance at which trees, rocks and buildings disappear.
@export_range(50.0, 3000.0, 10.0) var view_distance: float = 500.0
## Side of the squares in which repeated objects are grouped: bigger means fewer draw calls.
@export_range(40.0, 1000.0, 10.0) var chunk_size: float = 160.0
## Distance at which bushes and small objects disappear.
@export_range(20.0, 1000.0, 10.0) var small_view_distance: float = 160.0

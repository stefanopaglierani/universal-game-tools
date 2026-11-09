class_name UPRGPlace
extends Resource
## A place on the map: leveled ground and a group of simple buildings (a village, a hamlet, a stop).

## Name stored in the world data, for the game to find the place.
@export var place_name: String = "Village"
## Center, in meters from the terrain center, as (x, z).
@export var center: Vector2 = Vector2.ZERO
## Radius of the leveled ground and of the building area.
@export_range(5.0, 500.0, 0.5) var radius: float = 50.0
## Width of the soft edge of the leveled ground.
@export_range(1.0, 200.0, 0.5) var blend: float = 20.0
## Buildings to place. Fewer are built when the area has no more room.
@export_range(0, 200, 1) var building_count: int = 10
## Same seed, same village.
@export var seed_value: int = 1
## Smallest and largest side of a building.
@export var building_size: Vector2 = Vector2(6.0, 11.0)
## Lowest and highest wall.
@export var wall_height: Vector2 = Vector2(3.0, 6.0)
## Free space between buildings.
@export_range(0.5, 40.0, 0.5) var spacing: float = 5.0
## Wall colors, chosen per building.
@export var wall_colors: PackedColorArray = PackedColorArray([Color(0.85, 0.8, 0.7), Color(0.76, 0.66, 0.54), Color(0.9, 0.88, 0.84)])
## Roof colors, chosen per building.
@export var roof_colors: PackedColorArray = PackedColorArray([Color(0.55, 0.25, 0.18), Color(0.38, 0.3, 0.28)])
## Builds streets inside the place, joined to the nearest road, with the buildings along them.
@export var streets: bool = false
## Width of the pavement of the streets.
@export_range(3.0, 20.0, 0.5) var street_width: float = 5.0
## Distance between side streets.
@export_range(20.0, 200.0, 1.0) var street_spacing: float = 30.0
## Color of the streets.
@export var street_color: Color = Color(0.27, 0.27, 0.29)


## Returns the list of errors, empty when the place is valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if radius <= 0.0 or blend <= 0.0 or spacing <= 0.0:
		errors.append("place %s: radius, blend and spacing must be positive" % place_name)
	if building_size.x <= 0.0 or building_size.y < building_size.x or wall_height.x <= 0.0 or wall_height.y < wall_height.x:
		errors.append("place %s: building_size and wall_height need 0 < min <= max" % place_name)
	if wall_colors.is_empty() or roof_colors.is_empty():
		errors.append("place %s: wall_colors and roof_colors cannot be empty" % place_name)
	if streets and (street_width <= 0.0 or street_spacing < 20.0):
		errors.append("place %s: street_width must be positive and street_spacing at least 20" % place_name)
	return errors

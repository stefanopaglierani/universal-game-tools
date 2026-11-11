class_name UPRGSkin
extends Resource
## Appearance of a world. Images are read when baking and stored inside the world file.
## A path can be res://... or a full path such as C:/Textures/road.png. Empty keeps plain colors.

## Image repeated along the roads.
@export_global_file("*.png", "*.jpg", "*.webp") var road_texture_path: String = ""
## Image repeated over the terrain, tinted by its colors.
@export_global_file("*.png", "*.jpg", "*.webp") var terrain_texture_path: String = ""
## Image repeated on walls and roofs, tinted by their colors.
@export_global_file("*.png", "*.jpg", "*.webp") var building_texture_path: String = ""
## Multiplies the terrain colors.
@export var terrain_tint: Color = Color.WHITE
## Multiplies the road color.
@export var road_tint: Color = Color.WHITE
## Meters covered by one repeat of the building image.
@export_range(0.5, 50.0, 0.5) var building_uv_size: float = 4.0


## Loads the image at [param path] as a texture stored inside the world file.
## Returns null for an empty path. Sets [param errors] when the image cannot be read.
static func load_texture(path: String, errors: PackedStringArray) -> ImageTexture:
	if path.is_empty():
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		errors.append("cannot read the image: %s" % path)
		return null
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

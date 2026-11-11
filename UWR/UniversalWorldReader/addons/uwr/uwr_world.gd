@icon("res://addons/uwr/uwr_world.svg")
class_name UWRWorld
extends Node3D
## Opens a world made with the Universal Game Tools (UPTG, UPRG, UPWG) in any Godot game.
## A tiled world streams its ground in tiles around a node (by default the active camera);
## a single-file world is opened as it is. The ground gets a shader that paints grass, rock,
## sand and gravel, unless the game gives its own material.

signal tile_added(at: Vector2i)
signal tile_removed(at: Vector2i)

const META_KEY := "terrain_data"
const TILE_FORMAT := "tile_%d_%d.scn"

## The world file: `world.scn` of a tiled world, or a single baked world file.
@export_file("*.scn") var world_file: String = ""
## Tiles are loaded around this node. Empty: the active camera.
@export var follow: Node3D
## Tiles loaded on each side of the one under [member follow], on a computer and on a phone.
@export_range(1, 8) var rings: int = 3
@export_range(1, 8) var mobile_rings: int = 2
## Tiles read at the same time in the background.
@export_range(1, 8) var max_loading: int = 3
## The material of the ground. Empty: the built-in ground shader.
@export var ground_material: Material
## A flat sea at sea level, as wide as this (0 for none).
@export_range(0.0, 50000.0, 100.0) var sea_size: float = 0.0

## The data stored in the world: roads, junctions, places, tiles, sea level.
var data: Dictionary = {}
var _root: Node3D
var _tile_size := 0.0
var _tile_origin := Vector2.ZERO
var _available := {}
var _tiles := {}
var _loading := {}
var _folder := ""
var _material: Material
var _ring_count := 3


func _ready() -> void:
	if not world_file.is_empty() and _root == null:
		load_world(world_file)


## Opens [param path]. Returns false when the file is not a world. Tiles around [param around]
## (or around the follow node) are read before returning, so that the ground is there at once.
func load_world(path: String, around: Vector3 = Vector3.INF) -> bool:
	clear()
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("UWR: cannot open %s" % path)
		return false
	_root = packed.instantiate() as Node3D
	if _root == null or not _root.has_meta(META_KEY):
		push_error("UWR: %s is not a world made with the Universal Game Tools" % path)
		if _root != null:
			_root.free()
			_root = null
		return false
	world_file = path
	data = _root.get_meta(META_KEY)
	add_child(_root)
	_material = ground_material if ground_material != null else _default_ground()
	_ring_count = mobile_rings if OS.has_feature("mobile") else rings
	if is_tiled():
		var tiles: Dictionary = data.tiles
		_tile_size = tiles.size
		_tile_origin = tiles.origin
		_folder = path.get_base_dir()
		for at: Vector2i in tiles.list:
			_available[at] = true
		var center := around if around != Vector3.INF else _follow_position()
		for at in _wanted(_tile_at(center)):
			_place(at, load(_folder.path_join(TILE_FORMAT % [at.x, at.y])) as PackedScene)
	else:
		var ground := _root.get_node_or_null("Mesh") as MeshInstance3D
		if ground != null and ground_material != null:
			ground.material_override = ground_material
	if sea_size > 0.0:
		_add_sea()
	return true


## Removes the world from the scene.
func clear() -> void:
	for at: Vector2i in _tiles:
		(_tiles[at] as Node).queue_free()
	_tiles.clear()
	_loading.clear()
	_available.clear()
	if _root != null:
		_root.queue_free()
		_root = null
	for child in get_children():
		if child.name == "Sea":
			child.queue_free()
	data = {}


func is_tiled() -> bool:
	return data.has("tiles")


## Tiles in the scene now.
func loaded_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for at: Vector2i in _tiles:
		out.append(at)
	return out


func sea_level() -> float:
	return data.get("sea_level", 0.0)


## Roads: each has `path` (PackedVector2Array, x and z), `heights`, `width`, `sample_spacing`,
## `street` and `closed`.
func roads() -> Array:
	return data.get("roads", [])


func junctions() -> Array:
	return data.get("junctions", [])


func places() -> Array:
	return data.get("places", [])


## The point of a road nearest to [param pos], as {road, sample, position (Vector3), distance}.
## With [param road_index] at -1 every road is searched.
func nearest_road_point(pos: Vector3, road_index: int = -1) -> Dictionary:
	var best := {}
	var list := roads()
	for r in list.size():
		if road_index >= 0 and r != road_index:
			continue
		var road: Dictionary = list[r]
		var path: PackedVector2Array = road.path
		var heights: PackedFloat32Array = road.heights
		for i in path.size():
			var p := Vector3(path[i].x, heights[i], path[i].y)
			var d := Vector2(p.x - pos.x, p.z - pos.z).length()
			if best.is_empty() or d < best.distance:
				best = {"road": r, "sample": i, "position": to_global(p), "distance": d}
	return best


func _process(_delta: float) -> void:
	if not is_tiled():
		return
	_finish_one()
	var center := _tile_at(_follow_position())
	for at in _wanted(center):
		if _loading.size() >= max_loading:
			break
		if not _tiles.has(at) and not _loading.has(at):
			_loading[at] = true
			ResourceLoader.load_threaded_request(_folder.path_join(TILE_FORMAT % [at.x, at.y]), "PackedScene")
	for at: Vector2i in _tiles.keys():
		if maxi(absi(at.x - center.x), absi(at.y - center.y)) > _ring_count + 1:
			(_tiles[at] as Node).queue_free()
			_tiles.erase(at)
			tile_removed.emit(at)


func _follow_position() -> Vector3:
	if follow != null:
		return follow.global_position
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	return camera.global_position if camera != null else global_position


func _tile_at(pos: Vector3) -> Vector2i:
	var local := to_local(pos) if is_inside_tree() else pos
	return Vector2i(floori((local.x - _tile_origin.x) / _tile_size), floori((local.z - _tile_origin.y) / _tile_size))


## Existing tiles around [param center], the nearest first.
func _wanted(center: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for z in range(center.y - _ring_count, center.y + _ring_count + 1):
		for x in range(center.x - _ring_count, center.x + _ring_count + 1):
			var at := Vector2i(x, z)
			if _available.has(at):
				out.append(at)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - center).length_squared() < (b - center).length_squared())
	return out


## One finished tile per frame goes into the scene, to spread the cost.
func _finish_one() -> void:
	for at: Vector2i in _loading.keys():
		var path := _folder.path_join(TILE_FORMAT % [at.x, at.y])
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_loading.erase(at)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_place(at, ResourceLoader.load_threaded_get(path) as PackedScene)
		return


func _place(at: Vector2i, scene: PackedScene) -> void:
	if scene == null or _tiles.has(at):
		return
	var tile := scene.instantiate() as Node3D
	for mesh_name: String in ["Near", "Far"]:
		var mesh := tile.get_node_or_null(mesh_name) as MeshInstance3D
		if mesh != null:
			mesh.material_override = _material
	add_child(tile)
	_tiles[at] = tile
	tile_added.emit(at)


func _default_ground() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://addons/uwr/uwr_ground.gdshader")
	material.set_shader_parameter("sea_level", sea_level())
	return material


func _add_sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(sea_size, sea_size)
	var material := ShaderMaterial.new()
	material.shader = preload("res://addons/uwr/uwr_sea.gdshader")
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	sea.mesh = plane
	sea.material_override = material
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sea.position.y = sea_level()
	add_child(sea)

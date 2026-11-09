class_name UPRGDresser
extends RefCounted
## Puts library models in a world. Repeated objects are drawn in groups by area
## (MultiMesh), and they disappear beyond a distance, to keep the cost low on a phone.

const CHUNK_SIZE := 160.0
const TREE_KINDS: Array[String] = ["tree", "pine", "plant"]
const SOLID_KINDS: Array[String] = ["tree", "pine", "rock", "lamp", "landmark"]


## Scatters plants and rocks, and adds roadside objects. Returns counts for the report.
static func dress(root: Node3D, dressing: UPRGDressing, library: UPRGLibrary, grid: UPRGTerrainGrid,
		road_paths: Array[PackedVector2Array], road_clearances: PackedFloat32Array, roads: Array[UPRGRoadConfig],
		places: Array[UPRGPlace]) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = dressing.seed_value
	var near_road := _road_cells(road_paths, road_clearances)
	var placements := {}
	var solids: Array[Dictionary] = []
	var counts := {"scatter": 0, "roadside": 0}
	counts.scatter += _scatter("tree", dressing.tree_density, 3.0, 1000.0, 0.88, grid, near_road, places, library, rng, placements, solids)
	counts.scatter += _scatter("pine", dressing.tree_density * 0.6, 14.0, 1000.0, 0.8, grid, near_road, places, library, rng, placements, solids)
	counts.scatter += _scatter("plant", dressing.plant_density, 2.5, 1000.0, 0.85, grid, near_road, places, library, rng, placements, solids)
	counts.scatter += _scatter("bush", dressing.bush_density, 1.5, 1000.0, 0.75, grid, near_road, places, library, rng, placements, solids)
	counts.scatter += _scatter("rock", dressing.rock_density, 1.5, 1000.0, 0.5, grid, near_road, places, library, rng, placements, solids)
	for r in roads.size():
		counts.roadside += _roadside(road_paths[r], roads[r], dressing, grid, library, rng, placements, solids)

	var group := Node3D.new()
	group.name = "Dressing"
	root.add_child(group)
	group.owner = root
	var drawn := 0
	for key: String in placements:
		drawn += _add_multimesh(group, root, placements[key], dressing, library)
	_add_solids(group, root, solids)
	counts.instances = drawn
	counts.models = library.used_count()
	return counts


static func _road_cells(road_paths: Array[PackedVector2Array], road_clearances: PackedFloat32Array) -> Dictionary:
	var cells := {}
	for r in road_paths.size():
		var reach := int(ceil((road_clearances[r] + 3.0) / 8.0))
		for p in road_paths[r]:
			var c := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
			for z in range(-reach, reach + 1):
				for x in range(-reach, reach + 1):
					cells[c + Vector2i(x, z)] = true
	return cells


static func _scatter(kind: String, density: float, min_height: float, max_height: float, min_up: float, grid: UPRGTerrainGrid,
		near_road: Dictionary, places: Array[UPRGPlace], library: UPRGLibrary, rng: RandomNumberGenerator,
		placements: Dictionary, solids: Array[Dictionary]) -> int:
	if density <= 0.0 or not library.has_kind(kind):
		return 0
	var step := 100.0 / sqrt(density)
	var half_x := grid.cells_x * grid.cell_size * 0.5
	var half_z := grid.cells_z * grid.cell_size * 0.5
	var count := 0
	var z := -half_z + step * 0.5
	while z < half_z:
		var x := -half_x + step * 0.5
		while x < half_x:
			var p := Vector2(x + rng.randf_range(-0.45, 0.45) * step, z + rng.randf_range(-0.45, 0.45) * step)
			x += step
			if not grid.is_inside(p, grid.cell_size * 2.0) or near_road.has(Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))):
				continue
			var above := grid.height_at(p) - grid.sea_level
			if above < min_height or above > max_height or _up_at(grid, p) < min_up or _inside_place(p, places):
				continue
			var item := library.pick(kind, rng)
			var size := rng.randf_range(0.8, 1.25)
			_place(item, p, grid.height_at(p) - 0.05, rng.randf() * TAU, size, placements, solids)
			count += 1
		z += step
	return count


static func _up_at(grid: UPRGTerrainGrid, p: Vector2) -> float:
	var ix := clampi(roundi(p.x / grid.cell_size + grid.cells_x / 2.0), 0, grid.cells_x)
	var iz := clampi(roundi(p.y / grid.cell_size + grid.cells_z / 2.0), 0, grid.cells_z)
	return grid.normal_at_vertex(ix, iz).y


static func _inside_place(p: Vector2, places: Array[UPRGPlace]) -> bool:
	for place in places:
		if p.distance_to(place.center) < place.radius + 4.0:
			return true
	return false


static func _roadside(path: PackedVector2Array, road: UPRGRoadConfig, dressing: UPRGDressing, grid: UPRGTerrainGrid, library: UPRGLibrary,
		rng: RandomNumberGenerator, placements: Dictionary, solids: Array[Dictionary]) -> int:
	var count := 0
	var offset := road.width * 0.5 + road.shoulder + 1.2
	var lamp_every := int(dressing.lamp_spacing / road.sample_spacing)
	var prop_every := int(dressing.roadside_spacing / road.sample_spacing)
	var side := 1.0
	for i in range(1, path.size() - 1):
		var kind := ""
		if lamp_every > 0 and i % lamp_every == 0:
			kind = "lamp"
		elif prop_every > 0 and i % prop_every == 0:
			kind = "barrier" if rng.randf() < 0.6 else "prop"
		if kind.is_empty() or not library.has_kind(kind):
			continue
		var tangent := (path[i + 1] - path[i - 1]).normalized()
		var across := Vector2(tangent.y, -tangent.x)
		var p := path[i] + across * offset * side
		side = -side
		_place(library.pick(kind, rng), p, grid.height_at(p), atan2(tangent.x, tangent.y), 1.0, placements, solids)
		count += 1
	return count


static func _place(item: Dictionary, p: Vector2, y: float, yaw: float, size: float, placements: Dictionary, solids: Array[Dictionary]) -> void:
	var chunk := Vector2i(floori(p.x / CHUNK_SIZE), floori(p.y / CHUNK_SIZE))
	var key := "%s|%d|%d" % [item.id, chunk.x, chunk.y]
	if not placements.has(key):
		placements[key] = {"item": item, "transforms": []}
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size)
	placements[key].transforms.append(Transform3D(basis, Vector3(p.x, y, p.y)))
	if item.kind in SOLID_KINDS:
		solids.append({"position": Vector3(p.x, y, p.y), "size": size, "item": item})


static func _add_multimesh(group: Node3D, root: Node3D, entry: Dictionary, dressing: UPRGDressing, library: UPRGLibrary) -> int:
	var item: Dictionary = entry.item
	var mesh := library.mesh_of(item)
	if mesh == null:
		return 0
	var transforms: Array = entry.transforms
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	# The raw buffer is written directly: headless Godot ignores set_instance_transform(), and
	# worlds are baked headless.
	var buffer := PackedFloat32Array()
	buffer.resize(transforms.size() * 12)
	for i in transforms.size():
		var t: Transform3D = transforms[i]
		var f := i * 12
		buffer[f] = t.basis.x.x
		buffer[f + 1] = t.basis.y.x
		buffer[f + 2] = t.basis.z.x
		buffer[f + 3] = t.origin.x
		buffer[f + 4] = t.basis.x.y
		buffer[f + 5] = t.basis.y.y
		buffer[f + 6] = t.basis.z.y
		buffer[f + 7] = t.origin.y
		buffer[f + 8] = t.basis.x.z
		buffer[f + 9] = t.basis.y.z
		buffer[f + 10] = t.basis.z.z
		buffer[f + 11] = t.origin.z
	multimesh.buffer = buffer
	var node := MultiMeshInstance3D.new()
	node.name = "%s_%d" % [item.id, group.get_child_count()]
	node.multimesh = multimesh
	var small: bool = item.kind in ["bush", "prop", "barrier", "yard"]
	node.visibility_range_end = dressing.small_view_distance if small else dressing.view_distance
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if small else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	group.add_child(node)
	node.owner = root
	return transforms.size()


## Simple collision: a thin cylinder for trunks and lamps, a box for rocks and landmarks.
static func _add_solids(group: Node3D, root: Node3D, solids: Array[Dictionary]) -> void:
	if solids.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "Solids"
	group.add_child(body)
	body.owner = root
	for s in solids:
		var item: Dictionary = s.item
		var extent := Vector3(float(item.size[0]), float(item.size[1]), float(item.size[2])) * float(s.size)
		var shape_node := CollisionShape3D.new()
		if item.kind in TREE_KINDS or item.kind == "lamp":
			var cylinder := CylinderShape3D.new()
			cylinder.radius = 0.35
			cylinder.height = minf(extent.y, 6.0)
			shape_node.shape = cylinder
			shape_node.position = s.position + Vector3.UP * cylinder.height * 0.5
		else:
			var box := BoxShape3D.new()
			box.size = extent * 0.8
			shape_node.shape = box
			shape_node.position = s.position + Vector3.UP * extent.y * 0.4
		body.add_child(shape_node)
		shape_node.owner = root


## Builds a place from library models instead of plain boxes.
static func add_place(group: Node3D, root: Node3D, place_name: String, place: UPRGPlace, buildings: Array[Dictionary],
		grid: UPRGTerrainGrid, library: UPRGLibrary, dressing: UPRGDressing) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = place.seed_value
	var node := Node3D.new()
	node.name = place_name
	group.add_child(node)
	node.owner = root
	var body := StaticBody3D.new()
	body.name = "Body"
	node.add_child(body)
	body.owner = root
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		var kind := "shop" if library.has_kind("shop") and rng.randf() < 0.2 else "house"
		var item := library.pick(kind, rng)
		var mesh := library.mesh_of(item)
		if mesh == null:
			continue
		var extent := Vector3(float(item.size[0]), float(item.size[1]), float(item.size[2]))
		var room := place.building_size.y + place.spacing * 0.6
		var factor := minf(room / maxf(extent.x, extent.z), 1.0)
		var yaw := rng.randi_range(0, 3) * PI * 0.5
		var at := Vector3(b.center.x, grid.height_at(b.center) - 0.05, b.center.y)
		var instance := MeshInstance3D.new()
		instance.name = "Building%d" % i
		instance.mesh = mesh
		instance.transform = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * factor), at)
		instance.visibility_range_end = dressing.view_distance
		node.add_child(instance)
		instance.owner = root
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = extent * factor
		shape_node.shape = box
		shape_node.transform = Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * extent.y * factor * 0.5)
		body.add_child(shape_node)
		shape_node.owner = root
	for i in dressing.place_props:
		var kind := "yard" if rng.randf() < 0.5 else "prop"
		if not library.has_kind(kind):
			continue
		var item := library.pick(kind, rng)
		var mesh := library.mesh_of(item)
		if mesh == null:
			continue
		var angle := rng.randf() * TAU
		var p := place.center + Vector2(cos(angle), sin(angle)) * rng.randf_range(0.3, 0.95) * place.radius
		var instance := MeshInstance3D.new()
		instance.name = "Prop%d" % i
		instance.mesh = mesh
		instance.position = Vector3(p.x, grid.height_at(p), p.y)
		instance.rotation.y = rng.randf() * TAU
		instance.visibility_range_end = dressing.small_view_distance
		node.add_child(instance)
		instance.owner = root

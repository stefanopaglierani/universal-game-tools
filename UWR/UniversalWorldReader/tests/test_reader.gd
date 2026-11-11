## Tests for UWRWorld on two small worlds made by UPRG: one tiled (2 x 2 tiles of 256 m) and
## one in a single file. Both have a closed road around the center.
extends RefCounted

const TILED := "res://tests/data/tiled/world.scn"
const SINGLE := "res://tests/data/single.scn"


func _frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.process_frame


func run(t: SceneTree) -> void:
	var follow := Node3D.new()
	t.root.add_child(follow)
	var world := UWRWorld.new()
	world.follow = follow
	world.rings = 1
	t.root.add_child(world)

	t.check("a tiled world opens", world.load_world(TILED, Vector3.ZERO))
	t.check("it is recognized as tiled", world.is_tiled())
	t.check("the tiles around the start are there at once", world.loaded_tiles().size() == 4, "%d tiles" % world.loaded_tiles().size())
	var tile := world.get_child(world.get_child_count() - 1) as Node3D
	var near := tile.get_node("Near") as MeshInstance3D
	t.check("the ground gets the built-in material", near.material_override is ShaderMaterial)
	t.check("each tile has its collision", tile.get_node_or_null("Body/Shape") is CollisionShape3D)
	t.check("the roads are readable", world.roads().size() == 1 and world.roads()[0].closed)
	var hit := world.nearest_road_point(Vector3(140, 0, 0))
	t.check("the nearest road point is found", not hit.is_empty() and hit.distance < 15.0, str(hit.get("distance")))

	follow.position = Vector3(3000, 0, 3000)
	await _frames(t, 6)
	t.check("tiles far from the follow node are removed", world.loaded_tiles().is_empty(), "%d tiles" % world.loaded_tiles().size())
	follow.position = Vector3.ZERO
	for i in 120:
		await t.process_frame
		if world.loaded_tiles().size() == 4:
			break
	t.check("tiles come back in the background", world.loaded_tiles().size() == 4, "%d tiles" % world.loaded_tiles().size())

	var custom := StandardMaterial3D.new()
	world.ground_material = custom
	t.check("a single-file world opens", world.load_world(SINGLE))
	await _frames(t, 2)
	t.check("a single-file world is not tiled", not world.is_tiled() and world.loaded_tiles().is_empty())
	var ground := world.find_child("Mesh", true, false) as MeshInstance3D
	t.check("a game material replaces the ground", ground != null and ground.material_override == custom)

	world.sea_size = 1000.0
	world.load_world(SINGLE)
	await _frames(t, 2)
	t.check("the sea is added on request", world.find_child("Sea", false, false) != null)
	t.check("a file that is not a world is refused", not world.load_world("res://project.godot"))
	world.queue_free()
	follow.queue_free()

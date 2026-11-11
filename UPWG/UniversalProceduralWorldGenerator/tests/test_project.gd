## Templates, seeds, sizes and saving of UPWG projects.
extends RefCounted

const PATH := "user://upwg_test/project.upwg.tres"


func run(t: SceneTree) -> void:
	for id in UPWGProject.TEMPLATES:
		var project := UPWGProject.from_template(id, 7)
		var data := UPTGHeightfieldGenerator.generate(_small(project.terrain))
		t.check("template %s is valid and generates" % id, project.validate().is_empty() and data != null, str(project.validate()))

	var a := UPWGProject.from_template("coast", 42)
	var b := UPWGProject.from_template("coast", 42)
	var c := UPWGProject.from_template("coast", 43)
	var ha := UPTGHeightfieldGenerator.generate(_small(a.terrain)).heights_checksum
	t.check("the same template and seed give the same world", ha == UPTGHeightfieldGenerator.generate(_small(b.terrain)).heights_checksum)
	t.check("another seed gives another world", ha != UPTGHeightfieldGenerator.generate(_small(c.terrain)).heights_checksum)
	var coast_mountains := true
	for region in a.terrain.mountain_regions:
		coast_mountains = coast_mountains and region.center.y < a.terrain.coast_position
	t.check("on a coast the mountains stay on land", coast_mountains)

	var config := UPTGConfig.new()
	UPWGProject.set_size(config, 8192.0, 4.0)
	t.check("a world too big for its detail gets bigger cells", config.grid_cells_x <= UPTGConfig.MAX_CELLS_PER_AXIS and is_equal_approx(config.get_size().x, 8192.0),
		"%d cells of %.0f m" % [config.grid_cells_x, config.cell_size])
	UPWGProject.place_mountains(config, 3, 0, 100.0, 0.2)
	var first := config.mountain_regions[0].center
	UPWGProject.place_mountains(config, 3, 1, 100.0, 0.2)
	var moved := config.mountain_regions[0].center
	UPWGProject.place_mountains(config, 3, 0, 100.0, 0.2)
	t.check("moving the mountains can be undone with the same shuffle", first != moved and first == config.mountain_regions[0].center)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	a.world_name = "Test coast"
	var saved := ResourceSaver.save(a, PATH)
	var loaded := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as UPWGProject
	t.check("a project saves and opens again", saved == OK and loaded != null and loaded.world_name == "Test coast")
	t.check("the opened project builds the same world",
		loaded != null and UPTGHeightfieldGenerator.generate(_small(loaded.terrain)).heights_checksum == ha)
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(PATH.get_base_dir())


## A small copy, to keep the tests fast: same world, fewer cells.
static func _small(config: UPTGConfig) -> UPTGConfig:
	var copy := config.duplicate(true) as UPTGConfig
	UPWGProject.set_size(copy, copy.get_size().x, copy.get_size().x / 64.0)
	return copy

## Heights only, at another detail (ADR-0017): same heights where the grids meet, sizes checked.
extends RefCounted


func run(t: Object) -> void:
	var config := UPTGConfig.new()
	config.grid_cells_x = 64
	config.grid_cells_z = 64
	config.cell_size = 16.0
	config.generation_seed = 77
	var coarse := UPTGHeightfieldGenerator.generate(config)
	var fine := UPTGHeightfieldGenerator.generate_heights(config, 4.0)
	t.check("heights only at a finer detail", fine != null and fine.grid_cells_x == 256 and fine.size == coarse.size)
	var same := true
	for iz in range(0, 65, 8):
		for ix in range(0, 65, 8):
			same = same and is_equal_approx(coarse.get_vertex_height(ix, iz), fine.get_vertex_height(ix * 4, iz * 4))
	t.check("shared vertices get the same height at both details", same)
	t.check("a cell that does not divide the world is refused", UPTGHeightfieldGenerator.generate_heights(config, 5.0) == null)
	t.check("more than 8192 cells per side is refused", UPTGHeightfieldGenerator.generate_heights(config, 0.0625) == null)
	var started := Time.get_ticks_msec()
	var big := UPTGHeightfieldGenerator.generate_heights(config, 0.5)
	t.check("2048 x 2048 heights without a mesh", big != null and big.heights.size() == 2049 * 2049, "%d ms" % (Time.get_ticks_msec() - started))

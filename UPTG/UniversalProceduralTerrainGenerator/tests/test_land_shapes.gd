## Land shapes other than the island: continent and coast.
extends RefCounted


func _config(shape: UPTGConfig.LandShape) -> UPTGConfig:
	var config := UPTGConfig.new()
	config.grid_cells_x = 64
	config.grid_cells_z = 64
	config.cell_size = 8.0
	config.land_shape = shape
	return config


func _mask_at(data: UPTGTerrainData, ix: int, iz: int) -> float:
	return data.land_mask[iz * data.vertex_count_x + ix]


func run(t: Object) -> void:
	var island := UPTGHeightfieldGenerator.generate(_config(UPTGConfig.LandShape.ISLAND))
	var continent := UPTGHeightfieldGenerator.generate(_config(UPTGConfig.LandShape.CONTINENT))
	var coast := UPTGHeightfieldGenerator.generate(_config(UPTGConfig.LandShape.COAST))
	t.check("L1 the three land shapes generate", island != null and continent != null and coast != null)
	if continent == null or coast == null or island == null:
		return
	var all_land := true
	for m in continent.land_mask:
		all_land = all_land and is_equal_approx(m, 1.0)
	t.check("L2 a continent is land everywhere, edges included", all_land and continent.min_height >= continent.sea_level)
	t.check("L3 a coast has land on the -Z edge", _mask_at(coast, 32, 0) > 0.99, "%.2f" % _mask_at(coast, 32, 0))
	t.check("L4 a coast has sea on the +Z edge", _mask_at(coast, 32, 64) < 0.01, "%.2f" % _mask_at(coast, 32, 64))
	t.check("L5 an island still has sea on all edges", _mask_at(island, 0, 32) < 0.01 and _mask_at(island, 32, 0) < 0.01)
	var configs := [_config(UPTGConfig.LandShape.ISLAND), _config(UPTGConfig.LandShape.CONTINENT), _config(UPTGConfig.LandShape.COAST)]
	t.check("L6 the land shape changes the checksums", island.config_checksum != continent.config_checksum and continent.config_checksum != coast.config_checksum)
	var again := UPTGHeightfieldGenerator.generate(_config(UPTGConfig.LandShape.COAST))
	t.check("L7 the same coast comes back from the same seed", again.heights_checksum == coast.heights_checksum)
	var big := _config(UPTGConfig.LandShape.CONTINENT)
	big.island_radius = Vector2(0.8, 0.8)
	big.coastline_irregularity = 0.5
	t.check("L8 island limits do not apply to a continent", big.validate().is_empty(), str(big.validate()))
	var bad := _config(UPTGConfig.LandShape.COAST)
	bad.coast_position = 0.05
	t.check("L9 a coast line outside 0.2..0.9 is refused", not bad.validate().is_empty())
	t.check("L10 an island keeps its checksum from before land shapes",
		UPTGTerrainData.fnv1a32(var_to_bytes(configs[0].get_height_parameters())) == island.config_checksum and configs[0].get_height_parameters().size() == 18)

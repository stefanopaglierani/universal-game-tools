## Tests for UPTGSeed (criterion A7, seed part).
extends RefCounted


func run(t: Object) -> void:
	# Expected values computed independently (Python reference implementation).
	var vectors: Array = [
		[0, 1, 33350994],
		[12345, 1, 1868776673],
		[12345, 2, 1162198605],
		[2147483647, 3, 2090469116],
	]
	for v in vectors:
		var got: int = UPTGSeed.derive(v[0], v[1])
		t.check("A7 derive(%d, %d) == %d" % [v[0], v[1], v[2]], got == v[2], got)

	var in_range := true
	var distinct := {}
	for s in 200:
		for salt in [UPTGSeed.SALT_COASTLINE, UPTGSeed.SALT_TERRAIN, UPTGSeed.SALT_MOUNTAINS]:
			var d: int = UPTGSeed.derive(s * 7919, salt)
			if d < 0 or d > UPTGSeed.MAX_SEED:
				in_range = false
			distinct[d] = true
	t.check("A7 sub-seeds stay within 0..MAX_SEED", in_range)
	t.check("A7 sub-seeds are distinct for 600 (seed, salt) pairs", distinct.size() == 600, distinct.size())
	t.check("A7 salts give different sub-seeds for the same master seed",
		UPTGSeed.derive(12345, UPTGSeed.SALT_COASTLINE) != UPTGSeed.derive(12345, UPTGSeed.SALT_TERRAIN))

class_name UPRGLibrary
extends RefCounted
## The objects of a built library, and the record of the ones a world used.

var _items: Array = []
var _by_kind := {}
var _meshes := {}
var _used := {}


## Opens the library in [param folder]. Returns null when it has no index.
static func open(folder: String) -> UPRGLibrary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("index.json")))
	if not parsed is Array or (parsed as Array).is_empty():
		return null
	var library := UPRGLibrary.new()
	library._items = parsed
	for item: Dictionary in library._items:
		if not library._by_kind.has(item.kind):
			library._by_kind[item.kind] = []
		library._by_kind[item.kind].append(item)
	return library


func has_kind(kind: String) -> bool:
	return _by_kind.has(kind)


## Chooses an object of [param kind] with [param rng]. Returns an empty Dictionary when there is none.
func pick(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	if not _by_kind.has(kind):
		return {}
	var list: Array = _by_kind[kind]
	return list[rng.randi_range(0, list.size() - 1)]


## Returns the mesh of [param item], one copy per object so that the world file stays self-contained.
func mesh_of(item: Dictionary) -> ArrayMesh:
	if not _meshes.has(item.id):
		var loaded := load(item.path) as ArrayMesh
		if loaded == null:
			return null
		# duplicate() clears the file path, so the mesh is stored inside the world file.
		_meshes[item.id] = loaded.duplicate()
	_used[int(item.n)] = item
	return _meshes[item.id]


## Attribution text for the models the world actually uses.
func credits_text() -> String:
	var keys: Array = _used.keys()
	keys.sort()
	var lines := PackedStringArray(["# 3D models used in this world", "",
		"CC BY 4.0 models must be credited in the game. CC0 models need no credit.", "",
		"| Model | Author | Source | License | Link |", "|---|---|---|---|---|"])
	for n: int in keys:
		var item: Dictionary = _used[n]
		lines.append("| %s | %s | %s | %s | %s |" % [item.model, item.author, item.source, item.license, item.link])
	return "\n".join(lines) + "\n"


func used_count() -> int:
	return _used.size()

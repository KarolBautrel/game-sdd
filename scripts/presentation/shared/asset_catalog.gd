extends RefCounted
## Imported texture access shared by gameplay presentation and authoring UI.

const CATALOGUE_PATH := "res://resources/catalogues/textures.json"
static var _textures: Dictionary = {}
static var _entries: Array = []
static var _catalogue_loaded := false


static func texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _textures.has(path):
		return _textures[path]
	var result: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		result = ResourceLoader.load(path, "Texture2D") as Texture2D
	_textures[path] = result
	return result


static func image_copy(path: String) -> Image:
	var source := texture(path)
	if source == null:
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		return null
	image = image.duplicate() as Image
	if image.is_compressed() and image.decompress() != OK:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


static func entries() -> Array:
	if not _catalogue_loaded:
		_catalogue_loaded = true
		var file := FileAccess.open(CATALOGUE_PATH, FileAccess.READ)
		if file == null:
			push_error("Cannot open texture catalogue")
			return []
		var data: Variant = JSON.parse_string(file.get_as_text())
		if not data is Dictionary or data.get("schema", "") != "sdd.texture-catalogue-v1" or not data.get("textures") is Array:
			push_error("Invalid texture catalogue")
			return []
		_entries = data.textures
	return _entries.duplicate(true)


static func paths_under(prefix: String) -> Array[String]:
	var paths: Array[String] = []
	for entry: Dictionary in entries():
		var path := str(entry.get("path", ""))
		if path.begins_with(prefix.trim_suffix("/") + "/"):
			paths.append(path)
	return paths


static func clear_texture_cache() -> void:
	_textures.clear()

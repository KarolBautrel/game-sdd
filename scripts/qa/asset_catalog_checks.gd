extends RefCounted

const Catalog := preload("res://scripts/presentation/shared/asset_catalog.gd")
const UnitArt := preload("res://scripts/presentation/combat/combat_unit_art.gd")


static func validate() -> Array[String]:
	var failures: Array[String] = []
	var entries := Catalog.entries()
	if entries.is_empty():
		failures.append("Empty texture catalogue")
	var previous := ""
	for entry: Dictionary in entries:
		var path := str(entry.get("path", ""))
		if path <= previous or not ResourceLoader.exists(path, "Texture2D"):
			failures.append("Missing, duplicated or unordered texture: %s" % path)
		previous = path
	var representatives: Array[String] = []
	for prefix in ["res://assets/ui/dungeon", "res://assets/ui/combat", "res://assets/combat/terrain/processed", "res://assets/combat/characters/original"]:
		var paths := Catalog.paths_under(prefix)
		if paths.is_empty():
			failures.append("Empty shipped asset category: %s" % prefix)
		else:
			representatives.append(paths[0])
	var art := UnitArt.new()
	for action in ["pose:0", "walk:0", "walk:1", "combat:0", "hit:0", "death:0"]:
		representatives.append(art.processed_sheet_texture_path("warrior", "east", action))
	for path in representatives:
		var texture := Catalog.texture(path)
		var copy := Catalog.image_copy(path)
		if texture == null or copy == null:
			failures.append("Cannot decode representative texture: %s" % path)
			continue
		if Catalog.texture(path) != texture:
			failures.append("Texture cache miss: %s" % path)
		var original_size := texture.get_size()
		copy.resize(1, 1)
		var second := Catalog.image_copy(path)
		if texture.get_size() != original_size or second.get_size() != Vector2i(original_size):
			failures.append("Shared image was mutated: %s" % path)
	if Catalog.texture("res://assets/missing_optional.png") != null:
		failures.append("Missing optional texture did not return null")
	return failures

extends RefCounted
## Two-view authored additions. Raw legacy sheets remain independently available.
const PATH := "res://resources/data/presentation/tactical_roster.json"
const Drawn := preload("res://scripts/presentation/combat/drawn_animation_catalog.gd")
static var _loaded := false
static var _data: Dictionary = {}
static var _visuals: Dictionary = {}


static func visual_configs() -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			if parsed is Dictionary:
				_data = parsed
				_visuals = Drawn.visual_configs(PATH)
	return _visuals


static func resolve(unit: Dictionary, original: Dictionary) -> Dictionary:
	visual_configs()
	var character := str(original.get("character", ""))
	var replacement := str(_data.get("archetype_replacements", {}).get(str(unit.get("archetype_id", "")), _data.get("replacements", {}).get(character, character)))
	if replacement == character or not _visuals.has(replacement):
		return original
	var result := original.duplicate(true)
	result.character = replacement
	return result

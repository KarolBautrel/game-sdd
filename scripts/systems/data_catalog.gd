extends RefCounted
class_name DataCatalog

const WORLD_REGION_PATH := "res://resources/data/world_regions/region_001.json"
const TOWN_PATH := "res://resources/data/towns/town_ravenford.json"
const DUNGEON_PATH := "res://resources/data/dungeons/dungeon_old_mine.json"
const BASIC_ATTACK_PATH := "res://resources/data/combat_actions/basic_attack.json"


static func load_vertical_slice() -> Dictionary:
	return {
		"world_region": _load_json(WORLD_REGION_PATH),
		"town": _load_json(TOWN_PATH),
		"dungeon": _load_json(DUNGEON_PATH),
		"basic_attack": _load_json(BASIC_ATTACK_PATH),
	}


static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open data file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Data file is not a JSON object: %s" % path)
		return {}

	return parsed

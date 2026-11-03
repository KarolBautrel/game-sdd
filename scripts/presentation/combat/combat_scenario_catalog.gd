extends RefCounted
class_name CombatScenarioCatalog

const DEFAULT_ENCOUNTER_PATH := "res://resources/data/combat_encounters/debug_full_combat_showcase.json"
const CATALOGUE_PATH := "res://resources/data/combat_scenarios/catalogue.json"
static var _loaded := false
static var _options: Array[Dictionary] = []


static func options() -> Array[Dictionary]:
	if not _loaded:
		_loaded = true
		var file := FileAccess.open(CATALOGUE_PATH, FileAccess.READ)
		var data: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
		var failures := validation_errors(data)
		if not failures.is_empty():
			push_error("Invalid combat scenario catalogue: " + "; ".join(failures))
			return []
		for row: Dictionary in data.scenarios:
			_options.append(row.duplicate(true))
	return _options.duplicate(true)


static func validation_errors(data: Variant) -> Array[String]:
	var failures: Array[String] = []
	if not data is Dictionary or data.get("schema", "") != "sdd.combat-scenarios-v1" or not data.get("scenarios") is Array or data.scenarios.is_empty():
		return ["Invalid catalogue shape/schema"]
	var ids: Dictionary = {}
	for row in data.scenarios:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or not row.get("label") is String or row.label.strip_edges().is_empty() or not row.get("path") is String:
			failures.append("Invalid scenario entry")
			continue
		if ids.has(row.id):
			failures.append("Duplicate scenario id: " + row.id)
		ids[row.id] = true
		var path: String = row.path
		if path.get_base_dir() != "res://resources/data/combat_encounters" or not path.ends_with(".json") or not FileAccess.file_exists(path):
			failures.append("Invalid/missing encounter path: " + path)
	return failures


static func path_for_id(scenario_id: String) -> String:
	for option: Dictionary in options():
		if option["id"] == scenario_id:
			return option["path"]
	return ""

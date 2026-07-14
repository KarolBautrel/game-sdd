extends RefCounted
class_name CombatScenarioCatalog

const DEFAULT_ENCOUNTER_PATH := "res://resources/data/combat_encounters/debug_map_scale_showcase.json"
const FULL_COMBAT_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_full_combat_showcase.json"
const MAP_SCALE_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_map_scale_showcase.json"


static func options() -> Array[Dictionary]:
	return [
		{"id": "map_scale_showcase", "label": "Map scale showcase", "path": MAP_SCALE_SHOWCASE_PATH},
		{"id": "full_combat_showcase", "label": "Full combat showcase", "path": FULL_COMBAT_SHOWCASE_PATH},
	]


static func path_for_id(scenario_id: String) -> String:
	for option: Dictionary in options():
		if option["id"] == scenario_id:
			return option["path"]
	return ""

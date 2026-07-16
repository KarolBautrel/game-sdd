extends RefCounted
class_name CombatScenarioCatalog

const DEFAULT_ENCOUNTER_PATH := "res://resources/data/combat_encounters/debug_full_combat_showcase.json"
const FULL_COMBAT_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_full_combat_showcase.json"
const DUNGEON_COMBAT_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json"
const TERRAIN_GRASS_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_terrain_grass_showcase.json"
const TERRAIN_DUNGEON_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_terrain_dungeon_showcase.json"
const MAP_SCALE_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_map_scale_showcase.json"
const RAW_GOBLIN_SPIDER_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_raw_goblin_spider_showcase.json"
const RAW_BRUTE_OGRE_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_raw_brute_ogre_showcase.json"
const RAW_WOLF_SNAKE_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_raw_wolf_snake_showcase.json"
const RAW_UNDEAD_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_raw_undead_showcase.json"
const RAW_BEASTS_SHOWCASE_PATH := "res://resources/data/combat_encounters/debug_raw_beasts_showcase.json"


static func options() -> Array[Dictionary]:
	return [
		{"id": "full_combat_showcase", "label": "Old Mine skirmish", "path": FULL_COMBAT_SHOWCASE_PATH},
		{"id": "dungeon_combat_showcase", "label": "Old Mine dungeon", "path": DUNGEON_COMBAT_SHOWCASE_PATH},
		{"id": "terrain_grass_showcase", "label": "New terrain grass", "path": TERRAIN_GRASS_SHOWCASE_PATH},
		{"id": "terrain_dungeon_showcase", "label": "New terrain dungeon", "path": TERRAIN_DUNGEON_SHOWCASE_PATH},
		{"id": "map_scale_showcase", "label": "Map test arena", "path": MAP_SCALE_SHOWCASE_PATH},
		{"id": "raw_goblin_spider_showcase", "label": "Raw Goblin + Spider", "path": RAW_GOBLIN_SPIDER_SHOWCASE_PATH},
		{"id": "raw_brute_ogre_showcase", "label": "Raw Brute + Ogre", "path": RAW_BRUTE_OGRE_SHOWCASE_PATH},
		{"id": "raw_wolf_snake_showcase", "label": "Raw Wolf + Snake", "path": RAW_WOLF_SNAKE_SHOWCASE_PATH},
		{"id": "raw_undead_showcase", "label": "Raw Undead", "path": RAW_UNDEAD_SHOWCASE_PATH},
		{"id": "raw_beasts_showcase", "label": "Raw Beasts", "path": RAW_BEASTS_SHOWCASE_PATH},
	]


static func path_for_id(scenario_id: String) -> String:
	for option: Dictionary in options():
		if option["id"] == scenario_id:
			return option["path"]
	return ""

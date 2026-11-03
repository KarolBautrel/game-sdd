extends RefCounted
class_name CombatUnitArt

const AssetCatalog := preload("res://scripts/presentation/shared/asset_catalog.gd")

const PartyRoster := preload("res://scripts/domain/party_roster.gd")
const DrawnCatalog := preload("res://scripts/presentation/combat/drawn_animation_catalog.gd")

const UNIT_VISUALS := {
	"unit_player_001": {"faction": "heroes", "character": "warrior"},
	"unit_player_002": {"faction": "heroes", "character": "archer_1"},
	"unit_enemy_001": {"faction": "villains", "character": "axe_bandit"},
	"unit_enemy_002": {"faction": "villains", "character": "bandit_archer"},
}

const ARCHETYPE_VISUALS := {
	"raider_swordsman": {"faction": "villains", "character": "axe_bandit"},
	"raider_archer": {"faction": "villains", "character": "bandit_archer"},
	"raider_shieldman": {"faction": "villains", "character": "bandit_brute"},
}

# The canonical manifest owns every family and legacy alias. No mixed art fallback.
static var PROCESSED_SHEET_VISUALS: Dictionary = _original_visuals()


static func _original_visuals() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json"))
	var result: Dictionary = {}
	for profile: Dictionary in data.characters:
		var margin := Vector2i(128,64) if profile.weapon == "spear" else Vector2i.ZERO
		var size := Vector2i(data.camera.size[0],data.camera.size[1])+margin
		var pivot := Vector2i(data.camera.pivot[0],data.camera.pivot[1])+margin/2
		result[profile.id] = {"root": "res://assets/combat/characters/original/" + str(profile.id),
			"prefix": profile.id, "directions": true, "canvas_size": size, "pivot": pivot,
			"final_death_frame": true,
			"frame_seconds": data.frame_seconds,
			"frames": {"pose": 0, "combat_idle": 0, "walk": 0, "combat": 0, "hit": 0, "status_reaction": 0, "death": 0},
			"frame_counts": data.frame_counts}
	result.merge(DrawnCatalog.visual_configs(),true)
	for alias: String in data.aliases:
		result[alias] = result[data.aliases[alias]]
	return result


var texture_path_cache: Dictionary = {}
var idle_top_cache: Dictionary = {}


func idle_top(unit: Dictionary, legacy_size: Vector2i) -> float:
	var character:=str(unit_visual_config(unit).character)
	if not idle_top_cache.has(character):
		var top:=10000
		for direction in ["south","south_west","west","north_west","north","north_east","east","south_east"]:
			var image:=AssetCatalog.image_copy(processed_sheet_texture_path(character,direction,"pose:0"))
			if image!=null:top=mini(top,image.get_used_rect().position.y)
		idle_top_cache[character]=top if top<10000 else 0
	return sprite_offset(unit,legacy_size).y+float(idle_top_cache[character])


func icon(unit: Dictionary, state: Dictionary, facing: Dictionary, visual_actions: Dictionary, _icon_size: Vector2i) -> Texture2D:
	var direction := unit_direction(unit, state, facing)
	var action := str(visual_actions.get(unit["id"], default_visual_action(unit, state)))
	if is_drawn_unit(unit) and action.get_slice(":",0)=="walk" and default_visual_action(unit,state)=="combat_idle":
		action=action.replace("walk","combat_walk")
	# Imported textures are already at the native shared world scale. Reuse them.
	return AssetCatalog.texture(texture_path(unit, direction, action))


func unit_direction(unit: Dictionary, state: Dictionary, facing: Dictionary) -> String:
	if facing.has(unit["id"]):
		return facing[unit["id"]]
	var nearest := nearest_living_opponent(unit, state)
	if nearest.is_empty():
		return "south"
	return direction_between(unit["position"], nearest["position"])


func texture_path(unit: Dictionary, direction: String, visual_action: String) -> String:
	var visual := unit_visual_config(unit)
	var faction := str(visual["faction"])
	var character := str(visual["character"])
	var cache_key := "%s:%s:%s:%s" % [faction, character, direction, visual_action]
	if texture_path_cache.has(cache_key):
		return texture_path_cache[cache_key]
	var path := processed_sheet_texture_path(character, direction, visual_action)
	if path == "":
		path = processed_sheet_texture_path("bandit", direction, visual_action)
	texture_path_cache[cache_key] = path
	return path


func processed_sheet_texture_path(character: String, direction: String, visual_action: String) -> String:
	if not PROCESSED_SHEET_VISUALS.has(character):
		return ""
	var config: Dictionary = PROCESSED_SHEET_VISUALS[character]
	var action := processed_sheet_action(visual_action,character)
	var frames: Dictionary = config.get("frames", {})
	var frame_index := processed_sheet_frame_index(character, visual_action, int(frames.get(action, 0)))
	var side := direction
	var path := "%s/%s/%s_%s_%s_%03d.png" % [
		config["root"],
		action,
		config["prefix"],
		side,
		action,
		frame_index,
	]
	return path


func processed_sheet_frame_index(character: String, visual_action: String, fallback: int) -> int:
	if not visual_action.contains(":"):
		return fallback
	var frame_text := visual_action.get_slice(":", 1)
	if not frame_text.is_valid_int():
		return fallback
	var action := processed_sheet_action(visual_action,character)
	var count := processed_sheet_frame_count(character, action)
	if count <= 0:
		return fallback
	return int(frame_text) % count


func processed_sheet_frame_count(character: String, visual_action: String) -> int:
	if not PROCESSED_SHEET_VISUALS.has(character):
		return 1
	var action := processed_sheet_action(visual_action,character)
	var config: Dictionary = PROCESSED_SHEET_VISUALS[character]
	var counts: Dictionary = config.get("frame_counts", {})
	return maxi(1, int(counts.get(action, 1)))


func processed_sheet_corpse_visual_action(character: String) -> String:
	return "death:%s" % maxi(0, processed_sheet_frame_count(character, "death") - 1)


func processed_sheet_action(visual_action: String, character: String = "") -> String:
	var base_action := visual_action
	if visual_action.contains(":"):
		base_action = visual_action.get_slice(":", 0)
	if is_drawn_character(character):
		var aliases: Dictionary={"pose":"neutral_idle","walk":"neutral_walk","combat":"attack","status_reaction":"hit"}
		var resolved: String=aliases.get(base_action,base_action)
		return resolved if PROCESSED_SHEET_VISUALS[character].frame_counts.has(resolved) else "neutral_idle"
	if base_action=="combat_walk":return "walk"
	if base_action == "combat_idle":
		return "pose"
	if base_action == "status_reaction":
		return "hit"
	if base_action == "walk" or base_action == "combat" or base_action == "hit" or base_action == "death" or base_action == "pose":
		return base_action
	return "pose"


func visual_scale_for_character(_character: String) -> float:
	return 1.0


func processed_sheet_visual_scale(_character: String) -> float:
	# Geometry already shares100pixels/metre. Never normalize a goblin to an ogre.
	return 1.0


func sprite_size(unit: Dictionary, legacy_size: Vector2i) -> Vector2i:
	var character := str(unit_visual_config(unit).get("character", ""))
	return PROCESSED_SHEET_VISUALS.get(character, {}).get("canvas_size", legacy_size)


func sprite_offset(unit: Dictionary, legacy_size: Vector2i) -> Vector2:
	var character := str(unit_visual_config(unit).get("character", ""))
	var config: Dictionary = PROCESSED_SHEET_VISUALS.get(character, {})
	if not config.has("pivot"):
		return Vector2.ZERO
	var pivot: Vector2i = config.pivot
	return Vector2(float(legacy_size.x) / 2.0 - pivot.x, legacy_size.y - pivot.y)


func frame_seconds(unit: Dictionary, action: String, fallback: float, frame: int = 0) -> float:
	if unit.is_empty():
		return fallback
	var character := str(unit_visual_config(unit).get("character", ""))
	var config: Dictionary = PROCESSED_SHEET_VISUALS.get(character, {})
	if config.get("drawn",false):
		var durations: Array=config.durations_ms[processed_sheet_action(action,character)]
		return float(durations[posmod(frame,durations.size())])/1000.0
	return float(config.get("frame_seconds", {}).get(action, fallback))


func is_drawn_character(character: String) -> bool:
	return bool(PROCESSED_SHEET_VISUALS.get(character,{}).get("drawn",false))


func is_drawn_unit(unit: Dictionary) -> bool:
	return not unit.is_empty() and is_drawn_character(str(unit_visual_config(unit).get("character","")))


func clip_seconds(unit: Dictionary, action: String, fallback: float, hold_final: bool = true) -> float:
	if not is_drawn_unit(unit):return fallback
	var character: String=unit_visual_config(unit).character
	var durations: Array=PROCESSED_SHEET_VISUALS[character].durations_ms[processed_sheet_action(action,character)]
	var total:=0.0
	for i in range(durations.size() if hold_final else maxi(0,durations.size()-1)):total+=float(durations[i])/1000.0
	return total


func impact_seconds(unit: Dictionary, fallback: float) -> float:
	if not is_drawn_unit(unit):return fallback
	var character: String=unit_visual_config(unit).character
	var config: Dictionary=PROCESSED_SHEET_VISUALS[character]
	var total:=0.0
	for i in range(int(config.impact_frame)):total+=float(config.durations_ms.attack[i])/1000.0
	return total


func movement_seconds(unit: Dictionary, distance_pixels: float, fallback: float) -> float:
	if not is_drawn_unit(unit):return fallback
	var character: String=unit_visual_config(unit).character
	return clip_seconds(unit,"walk",fallback)*distance_pixels/float(PROCESSED_SHEET_VISUALS[character].walk_stride_pixels)


func default_visual_action(unit: Dictionary, state: Dictionary) -> String:
	var nearest := nearest_living_opponent(unit, state)
	if nearest.is_empty():
		return "pose"
	return "combat_idle" if tile_distance(unit["position"], nearest["position"]) <= 2 else "pose"


func unit_visual_config(unit: Dictionary) -> Dictionary:
	if unit.has("visual"):
		return unit["visual"]
	var hero := PartyRoster.hero_for_combat_unit(str(unit.get("id", "")))
	if not hero.is_empty():
		return hero.get("visual", {"faction": "heroes", "character": "warrior"})
	var archetype_id := str(unit.get("archetype_id", ""))
	if ARCHETYPE_VISUALS.has(archetype_id):
		return ARCHETYPE_VISUALS[archetype_id]
	if UNIT_VISUALS.has(unit["id"]):
		return UNIT_VISUALS[unit["id"]]
	if unit.get("team", "enemy") == "player":
		return {"faction": "heroes", "character": "warrior"}
	return {"faction": "villains", "character": "enemy_baddie"}


func legacy_character_prefix(character: String) -> String:
	return str(PROCESSED_SHEET_VISUALS.get(character,{}).get("prefix",character))


func nearest_living_opponent(unit: Dictionary, state: Dictionary) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance := 9999
	for other: Dictionary in state.get("units", []):
		if other["team"] == unit["team"] or other["resources"]["hp"] <= 0:
			continue
		var distance := tile_distance(unit["position"], other["position"])
		if distance < best_distance:
			best_distance = distance
			nearest = other
	return nearest


func tile_distance(from_position: Dictionary, to_position: Dictionary) -> int:
	return maxi(
		absi(int(from_position["x"]) - int(to_position["x"])),
		absi(int(from_position["y"]) - int(to_position["y"]))
	)


func direction_between(from_position: Dictionary, to_position: Dictionary) -> String:
	var dx := int(to_position["x"]) - int(from_position["x"])
	var dy := int(to_position["y"]) - int(from_position["y"])
	if dy < 0 and dx == 0:
		return "north"
	if dy > 0 and dx == 0:
		return "south"
	if dx < 0 and dy == 0:
		return "west"
	if dx > 0 and dy == 0:
		return "east"
	if dx < 0 and dy < 0:
		return "north_west"
	if dx > 0 and dy < 0:
		return "north_east"
	if dx < 0 and dy > 0:
		return "south_west"
	if dx > 0 and dy > 0:
		return "south_east"
	return "south"

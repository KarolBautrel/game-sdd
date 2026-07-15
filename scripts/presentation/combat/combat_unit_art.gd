extends RefCounted
class_name CombatUnitArt

const RAW_EXTRACTED_TILE_SIZE := 112
const RAW_EXTRACTED_MAX_SIZE := Vector2i(110, 106)

const UNIT_VISUALS := {
	"unit_player_001": {"faction": "heroes", "character": "warrior"},
	"unit_enemy_001": {"faction": "villains", "character": "goblin_atlas"},
	"unit_enemy_002": {"faction": "villains", "character": "spider_atlas"},
}

const RAW_EXTRACTED_VISUALS := {
	"armored_brute": {
		"scale": 1.35,
		"folder": "armored_brute",
		"prefix": "raw_armored_brute_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 3, "combat": 6, "hit": 8, "status_reaction": 8, "death": 9},
	},
	"bandit": {
		"scale": 1.35,
		"folder": "bandit",
		"prefix": "raw_bandit_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 3, "combat": 6, "hit": 8, "status_reaction": 8, "death": 9},
	},
	"bat": {
		"scale": 1.35,
		"folder": "bat",
		"prefix": "raw_bat_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 3, "combat": 4, "hit": 5, "status_reaction": 5, "death": 6},
	},
	"dire_boar": {
		"scale": 1.35,
		"folder": "dire_boar",
		"prefix": "raw_dire_boar_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 2, "combat": 4, "hit": 6, "status_reaction": 6, "death": 7},
	},
	"giant_snake": {
		"scale": 1.35,
		"folder": "giant_snake",
		"prefix": "raw_giant_snake_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 2, "combat": 4, "hit": 6, "status_reaction": 6, "death": 7},
	},
	"goblin_atlas": {
		"scale": 1.35,
		"folder": "goblin_atlas",
		"prefix": "raw_goblin_atlas_atlas_frame",
		"frames": {
			"pose": 0,
			"combat_idle": 0,
			"walk": 2,
			"combat": 6,
			"hit": 7,
			"status_reaction": 7,
			"death": 8,
		},
	},
	"hell_hound": {
		"scale": 1.35,
		"folder": "hell_hound",
		"prefix": "raw_hell_hound_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 2, "combat": 4, "hit": 6, "status_reaction": 6, "death": 7},
	},
	"lizardman": {
		"scale": 1.35,
		"folder": "lizardman",
		"prefix": "raw_lizardman_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 2, "combat": 5, "hit": 6, "status_reaction": 6, "death": 7},
	},
	"ogre": {
		"scale": 1.35,
		"folder": "ogre",
		"prefix": "raw_ogre_atlas_frame",
		"frames": {"pose": 2, "combat_idle": 2, "walk": 3, "combat": 5, "hit": 7, "status_reaction": 7, "death": 8},
	},
	"spider_atlas": {
		"scale": 1.35,
		"folder": "spider_atlas",
		"prefix": "raw_spider_atlas_atlas_frame",
		"frames": {
			"pose": 1,
			"combat_idle": 1,
			"walk": 1,
			"combat": 2,
			"hit": 3,
			"status_reaction": 3,
			"death": 4,
		},
	},
	"skeleton_archer": {
		"scale": 1.35,
		"folder": "skeleton_archer",
		"prefix": "raw_skeleton_archer_atlas_frame",
		"frames": {
			"pose": 0,
			"combat_idle": 0,
			"walk": 2,
			"combat": 6,
			"hit": 7,
			"status_reaction": 7,
			"death": 8,
		},
	},
	"skeleton_warrior": {
		"scale": 1.35,
		"folder": "skeleton_warrior",
		"prefix": "raw_skeleton_warrior_atlas_frame",
		"frames": {
			"pose": 0,
			"combat_idle": 0,
			"walk": 2,
			"combat": 6,
			"hit": 7,
			"status_reaction": 7,
			"death": 8,
		},
	},
	"wolf_atlas": {
		"scale": 1.35,
		"folder": "wolf",
		"right_folder": "pose_right",
		"left_folder": "pose_left",
		"prefix": "raw_wolf_pose_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 4, "combat": 1, "hit": 3, "status_reaction": 3, "death": 4},
	},
	"wraith": {
		"scale": 1.35,
		"folder": "wraith",
		"prefix": "raw_wraith_atlas_frame",
		"frames": {"pose": 0, "combat_idle": 0, "walk": 3, "combat": 5, "hit": 7, "status_reaction": 7, "death": 8},
	},
}

var texture_cache: Dictionary = {}
var texture_path_cache: Dictionary = {}


func icon(unit: Dictionary, state: Dictionary, facing: Dictionary, visual_actions: Dictionary, icon_size: Vector2i) -> Texture2D:
	var direction := unit_direction(unit, state, facing)
	var visual_action := str(visual_actions.get(unit["id"], default_visual_action(unit, state)))
	var texture_path := texture_path(unit, direction, visual_action)
	var visual := unit_visual_config(unit)
	var character := str(visual["character"])
	var visual_scale := visual_scale_for_character(character)
	var use_source_scale := RAW_EXTRACTED_VISUALS.has(character)
	var cache_key := "%s:%s:%s:%s:%s" % [texture_path, icon_size.x, icon_size.y, visual_scale, use_source_scale]
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]

	var image := Image.new()
	var error := image.load(texture_path)
	if error != OK:
		push_error("Cannot load unit texture: %s" % texture_path)
		return null
	var texture := ImageTexture.create_from_image(scaled_icon_image(image, icon_size, visual_scale, use_source_scale))
	texture_cache[cache_key] = texture
	return texture


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
	var base_path := "res://assets/combat/characters/%s/%s" % [faction, character]
	var legacy_character := legacy_character_prefix(character)
	var legacy_base_path := "res://assets/combat/characters/%s/%s" % [faction, legacy_character]
	var candidates: Array[String] = []
	var raw_path := raw_extracted_texture_path(character, direction, visual_action)
	if raw_path != "":
		candidates.append(raw_path)

	if visual_action == "walk":
		candidates.append("%s/walk/%s_%s_walk.png" % [base_path, character, direction])
		candidates.append("%s/walk/%s_walk.png" % [base_path, direction])
	elif visual_action == "combat":
		candidates.append("%s/combat/%s_%s_combat.png" % [base_path, character, direction])
		candidates.append("%s/combat/%s_combat.png" % [base_path, direction])
		candidates.append("%s/combat/%s_%s_attack.png" % [base_path, character, direction])
		candidates.append("%s/combat/%s_attack.png" % [base_path, direction])
		if legacy_character != character:
			candidates.append("%s/combat/%s_%s_combat.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/combat/%s_combat.png" % [legacy_base_path, direction])
	elif visual_action == "hit":
		candidates.append("%s/hit/%s_%s_hit.png" % [base_path, character, direction])
		candidates.append("%s/hit/%s_hit.png" % [base_path, direction])
		candidates.append("%s/damage/%s_%s_damage.png" % [base_path, character, direction])
		candidates.append("%s/damage/%s_damage.png" % [base_path, direction])
		candidates.append("%s/hurt/%s_%s_hurt.png" % [base_path, character, direction])
		candidates.append("%s/hurt/%s_hurt.png" % [base_path, direction])
		candidates.append("%s/combat/%s_%s_combat.png" % [base_path, character, direction])
		candidates.append("%s/combat/%s_combat.png" % [base_path, direction])
		if legacy_character != character:
			candidates.append("%s/hit/%s_%s_hit.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/damage/%s_%s_damage.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/hurt/%s_%s_hurt.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/combat/%s_%s_combat.png" % [legacy_base_path, legacy_character, direction])
	elif visual_action == "status_reaction":
		candidates.append("%s/status/%s_%s_status.png" % [base_path, character, direction])
		candidates.append("%s/status/%s_status.png" % [base_path, direction])
		candidates.append("%s/hit/%s_%s_hit.png" % [base_path, character, direction])
		candidates.append("%s/hit/%s_hit.png" % [base_path, direction])
		candidates.append("%s/combat/%s_%s_combat.png" % [base_path, character, direction])
		candidates.append("%s/combat/%s_combat.png" % [base_path, direction])
		if legacy_character != character:
			candidates.append("%s/status/%s_%s_status.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/hit/%s_%s_hit.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/combat/%s_%s_combat.png" % [legacy_base_path, legacy_character, direction])
	elif visual_action == "death":
		candidates.append("%s/falling-back-death/%s_%s_falling-back-death.png" % [base_path, character, direction])
		candidates.append("%s/falling-back-death/%s_falling-back-death.png" % [base_path, direction])
		candidates.append("%s/death/%s_%s_death.png" % [base_path, character, direction])
		candidates.append("%s/death/%s_death.png" % [base_path, direction])
		candidates.append("%s/combat/%s_%s_combat.png" % [base_path, character, direction])
		candidates.append("%s/combat/%s_combat.png" % [base_path, direction])
		if legacy_character != character:
			candidates.append("%s/falling-back-death/%s_%s_falling-back-death.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/falling-back-death/%s_falling-back-death.png" % [legacy_base_path, direction])
			candidates.append("%s/death/%s_%s_death.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/combat/%s_%s_combat.png" % [legacy_base_path, legacy_character, direction])
	elif visual_action == "combat_idle":
		candidates.append("%s/fight-stance-idle-8-frames/%s_%s_fight-stance-idle-8-frames.png" % [base_path, character, direction])
		candidates.append("%s/fight-stance-idle-8-frames/%s_fight-stance-idle-8-frames.png" % [base_path, direction])
		candidates.append("%s/combat_idle/%s_%s_combat_idle.png" % [base_path, character, direction])
		candidates.append("%s/combat_idle/%s_combat_idle.png" % [base_path, direction])
		if legacy_character != character:
			candidates.append("%s/fight-stance-idle-8-frames/%s_%s_fight-stance-idle-8-frames.png" % [legacy_base_path, legacy_character, direction])
			candidates.append("%s/fight-stance-idle-8-frames/%s_fight-stance-idle-8-frames.png" % [legacy_base_path, direction])
			candidates.append("%s/combat_idle/%s_%s_combat_idle.png" % [legacy_base_path, legacy_character, direction])

	candidates.append("%s/pose/%s_%s.png" % [base_path, character, direction])
	candidates.append("%s/pose/%s_south.png" % [base_path, character])
	if legacy_character != character:
		candidates.append("%s/pose/%s_%s.png" % [legacy_base_path, legacy_character, direction])
		candidates.append("%s/pose/%s_south.png" % [legacy_base_path, legacy_character])

	for candidate in candidates:
		if ResourceLoader.exists(candidate) or FileAccess.file_exists(candidate):
			texture_path_cache[cache_key] = candidate
			return candidate
	texture_path_cache[cache_key] = candidates[-1]
	return candidates[-1]


func raw_extracted_texture_path(character: String, direction: String, visual_action: String) -> String:
	if not RAW_EXTRACTED_VISUALS.has(character):
		return ""
	var config: Dictionary = RAW_EXTRACTED_VISUALS[character]
	var frames: Dictionary = config.get("frames", {})
	var frame_index := int(frames.get(visual_action, frames.get("pose", 0)))
	var facing_folder := str(config.get("left_folder", "atlas_frames_left")) if direction.contains("west") else str(config.get("right_folder", "atlas_frames_right"))
	return "res://assets/combat/characters/villains/raw_extracted/%s/%s/%s_%03d.png" % [
		config["folder"],
		facing_folder,
		config["prefix"],
		frame_index,
	]


func visual_scale_for_character(character: String) -> float:
	if RAW_EXTRACTED_VISUALS.has(character):
		return float(RAW_EXTRACTED_VISUALS[character].get("scale", 1.0))
	return 1.0


func scaled_icon_image(source: Image, icon_size: Vector2i, visual_scale: float, use_source_scale: bool) -> Image:
	var output := Image.create(icon_size.x, icon_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	var source_width := source.get_width()
	var source_height := source.get_height()
	if source_width <= 0 or source_height <= 0:
		return output
	var scale := visual_scale
	if not use_source_scale:
		scale = minf(float(icon_size.x) / float(source_width), float(icon_size.y) / float(source_height)) * visual_scale
	else:
		var max_width_scale := float(RAW_EXTRACTED_MAX_SIZE.x) / float(source_width)
		var max_height_scale := float(RAW_EXTRACTED_MAX_SIZE.y) / float(source_height)
		scale = minf(scale, minf(max_width_scale, max_height_scale))
	var target_width := clampi(int(round(float(source_width) * scale)), 1, icon_size.x)
	var target_height := clampi(int(round(float(source_height) * scale)), 1, icon_size.y)
	var scaled := source.duplicate()
	scaled.resize(target_width, target_height, Image.INTERPOLATE_NEAREST)
	var target_x := int((icon_size.x - target_width) / 2)
	var target_y := icon_size.y - target_height
	if use_source_scale:
		var tile_bottom_in_icon := int(round((float(icon_size.y) + float(RAW_EXTRACTED_TILE_SIZE)) / 2.0))
		target_y = clampi(tile_bottom_in_icon - target_height, 0, icon_size.y - target_height)
	output.blit_rect(scaled, Rect2i(Vector2i.ZERO, Vector2i(target_width, target_height)), Vector2i(target_x, target_y))
	return output


func default_visual_action(unit: Dictionary, state: Dictionary) -> String:
	var nearest := nearest_living_opponent(unit, state)
	if nearest.is_empty():
		return "pose"
	return "combat_idle" if tile_distance(unit["position"], nearest["position"]) <= 2 else "pose"


func unit_visual_config(unit: Dictionary) -> Dictionary:
	if unit.has("visual"):
		return unit["visual"]
	if UNIT_VISUALS.has(unit["id"]):
		return UNIT_VISUALS[unit["id"]]
	if unit.get("team", "enemy") == "player":
		return {"faction": "heroes", "character": "warrior"}
	return {"faction": "villains", "character": "enemy_baddie"}


func legacy_character_prefix(character: String) -> String:
	if character == "enemy_orc" or character == "enemy_skeleton":
		return "enemy_baddie"
	return character


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

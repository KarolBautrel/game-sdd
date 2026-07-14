extends RefCounted
class_name CombatUnitArt

const UNIT_VISUALS := {
	"unit_player_001": {"faction": "heroes", "character": "warrior"},
	"unit_enemy_001": {"faction": "villains", "character": "enemy_orc"},
	"unit_enemy_002": {"faction": "villains", "character": "enemy_skeleton"},
}

var texture_cache: Dictionary = {}


func icon(unit: Dictionary, state: Dictionary, facing: Dictionary, visual_actions: Dictionary, icon_size: Vector2i) -> Texture2D:
	var direction := unit_direction(unit, state, facing)
	var visual_action := str(visual_actions.get(unit["id"], default_visual_action(unit, state)))
	var texture_path := texture_path(unit, direction, visual_action)
	var cache_key := "%s:%s:%s" % [texture_path, icon_size.x, icon_size.y]
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]

	var image := Image.new()
	var error := image.load(texture_path)
	if error != OK:
		push_error("Cannot load unit texture: %s" % texture_path)
		return null
	image.resize(icon_size.x, icon_size.y, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
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
	var base_path := "res://assets/characters/%s/%s" % [faction, character]
	var legacy_character := legacy_character_prefix(character)
	var legacy_base_path := "res://assets/characters/%s/%s" % [faction, legacy_character]
	var candidates: Array[String] = []

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
			return candidate
	return candidates[-1]


func default_visual_action(unit: Dictionary, state: Dictionary) -> String:
	var nearest := nearest_living_opponent(unit, state)
	if nearest.is_empty():
		return "pose"
	return "combat_idle" if tile_distance(unit["position"], nearest["position"]) <= 2 else "pose"


func unit_visual_config(unit: Dictionary) -> Dictionary:
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

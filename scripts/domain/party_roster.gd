extends RefCounted
class_name PartyRoster

const DEFAULT_PARTY_IDS := ["hero_bran", "hero_torin"]

const HEROES := {
	"hero_bran": {
		"id": "hero_bran",
		"combat_unit_id": "unit_player_001",
		"display_name": "Bran",
		"class_name": "Warrior",
		"slot_id": "front",
		"target_id": "party_slot_front",
		"portrait_path": "res://assets/ui/dungeon/processed/mercenary_pose_for_portrait/mercenary_pose_for_portrait_head.png",
		"visual": {"faction": "heroes", "character": "warrior"},
		"stats": {
			"max_hp": 14,
			"strength": 5,
			"defense": 1,
			"initiative": 9,
			"move_points": 4,
			"max_ap": 2,
			"accuracy": 0,
			"evasion": 0,
		},
		"resources": {"hp": 14, "ap": 2, "mp": 4},
		"available_actions": ["move", "defend", "end_turn"],
		"loadout": {"armor": null, "main_hand": "hero_sword", "off_hand": null},
	},
	"hero_torin": {
		"id": "hero_torin",
		"combat_unit_id": "unit_player_002",
		"display_name": "Torin",
		"class_name": "Archer",
		"slot_id": "back",
		"target_id": "party_slot_back",
		"portrait_path": "res://assets/ui/dungeon/processed/archer_portrait/archer_portrait_head.png",
		"visual": {"faction": "heroes", "character": "archer_1"},
		"stats": {
			"max_hp": 10,
			"strength": 3,
			"defense": 0,
			"initiative": 11,
			"move_points": 4,
			"max_ap": 2,
			"accuracy": 12,
			"evasion": 8,
		},
		"resources": {"hp": 10, "ap": 2, "mp": 4},
		"available_actions": ["move", "defend", "end_turn"],
		"loadout": {"armor": null, "main_hand": "hero_bow", "off_hand": null},
	},
}


static func default_party() -> Array:
	var party: Array = []
	for hero_id: String in DEFAULT_PARTY_IDS:
		party.append(hero(hero_id))
	return party


static func hero(hero_id: String) -> Dictionary:
	return HEROES.get(hero_id, {}).duplicate(true)


static func hero_for_combat_unit(combat_unit_id: String) -> Dictionary:
	for hero_id: String in DEFAULT_PARTY_IDS:
		var next_hero: Dictionary = HEROES.get(hero_id, {})
		if str(next_hero.get("combat_unit_id", "")) == combat_unit_id:
			return next_hero.duplicate(true)
	return {}


static func default_party_formation() -> Array:
	var formation: Array = []
	for next_hero: Dictionary in default_party():
		formation.append({
			"slot_id": str(next_hero.get("slot_id", "")),
			"target_id": str(next_hero.get("target_id", "")),
			"combat_unit_id": str(next_hero.get("combat_unit_id", "")),
			"label": "%s (%s)" % [str(next_hero.get("display_name", "")), str(next_hero.get("class_name", ""))],
		})
	return formation


static func heroes_for_formation(formation: Array) -> Array:
	var heroes: Array = []
	for slot: Dictionary in formation:
		var next_hero := hero_for_combat_unit(str(slot.get("combat_unit_id", "")))
		if next_hero.is_empty():
			next_hero = {
				"combat_unit_id": str(slot.get("combat_unit_id", "")),
				"display_name": str(slot.get("label", "Hero")),
				"class_name": "Hero",
				"slot_id": str(slot.get("slot_id", "")),
				"target_id": str(slot.get("target_id", "")),
				"portrait_path": "res://assets/ui/dungeon/processed/mercenary_pose_for_portrait/mercenary_pose_for_portrait_head.png",
				"visual": {"faction": "heroes", "character": "warrior"},
				"stats": {},
				"resources": {},
			}
		heroes.append(next_hero)
	return heroes


static func combat_unit(combat_unit_id: String, position: Dictionary) -> Dictionary:
	var next_hero := hero_for_combat_unit(combat_unit_id)
	if next_hero.is_empty():
		return {}
	var stats: Dictionary = next_hero.get("stats", {}).duplicate(true)
	return {
		"id": combat_unit_id,
		"team": "player",
		"position": position.duplicate(true),
		"stats": stats,
		"resources": next_hero.get("resources", {}).duplicate(true),
		"statuses": [],
		"available_actions": next_hero.get("available_actions", []).duplicate(true),
		"loadout": next_hero.get("loadout", {}).duplicate(true),
		"visual": next_hero.get("visual", {}).duplicate(true),
	}


static func display_name_for_combat_unit(combat_unit_id: String) -> String:
	var next_hero := hero_for_combat_unit(combat_unit_id)
	if next_hero.is_empty():
		return ""
	return str(next_hero.get("display_name", ""))

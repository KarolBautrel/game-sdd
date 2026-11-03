extends RefCounted

const Party := preload("res://scripts/domain/party_roster.gd")
const PATH := "res://resources/data/progression/party_levels.json"


static func levels() -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data.levels.duplicate(true)


static func defaults() -> Dictionary:
	var result: Dictionary = {}
	for hero: Dictionary in Party.default_party():
		result[hero.combat_unit_id] = 1
	return result


static func allocated(advancement: Dictionary) -> int:
	var total := 0
	var rows := levels()
	for level in advancement.values():
		for index in range(1, int(level)):
			total += int(rows[index].cost)
	return total


static func valid(value: Variant, earned: int) -> bool:
	if not value is Dictionary or value.size() != defaults().size():
		return false
	for id: String in defaults():
		var level: Variant = value.get(id)
		if not (level is int or level is float) or not is_finite(float(level)) or float(level) != floor(float(level)) or level < 1 or level > levels().size():
			return false
	return allocated(value) <= earned


static func next_tier(advancement: Dictionary, id: String) -> Dictionary:
	var rows := levels()
	var level := int(advancement.get(id, rows.size()))
	return {} if level >= rows.size() else rows[level].duplicate(true)


static func stats(id: String, level: int) -> Dictionary:
	var result: Dictionary = Party.hero_for_combat_unit(id).get("stats", {}).duplicate(true)
	var bonuses: Dictionary = levels()[clampi(level - 1, 0, levels().size() - 1)].bonuses
	for key: String in bonuses:
		result[key] = int(result.get(key, 0)) + int(bonuses[key])
	return result


static func apply(encounter: Dictionary, advancement: Dictionary) -> Dictionary:
	var next := encounter.duplicate(true)
	for unit: Dictionary in next.get("units", []):
		if advancement.has(unit.id):
			unit.stats = stats(unit.id, int(advancement[unit.id]))
	return next

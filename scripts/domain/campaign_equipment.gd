extends RefCounted
## Campaign ownership/slots only. Combat outcomes stay in CombatResolver.

const Items := preload("res://scripts/domain/item_catalog.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Identity := preload("res://scripts/domain/hero_equipment_identity.gd")
const SLOTS := ["main_hand", "off_hand", "armor", "boots", "helmet"]
const LEGACY_SLOTS := ["main_hand", "off_hand", "armor"]


static func normalized(equipment: Dictionary) -> Dictionary:
	var next:=equipment.duplicate(true)
	for loadout: Dictionary in next.values():
		for slot: String in SLOTS:
			if not loadout.has(slot):loadout[slot]=null
	return next


static func defaults() -> Dictionary:
	var result: Dictionary = {}
	for hero: Dictionary in Party.default_party():
		result[hero.combat_unit_id] = hero.loadout.duplicate(true)
	return result


static func assigned(equipment: Dictionary, item_id: String) -> int:
	var count := 0
	for loadout: Dictionary in equipment.values():
		for id in loadout.values():
			if id == item_id:
				count += 1
	return count


static func valid(equipment: Variant, owned: Array) -> bool:
	if not equipment is Dictionary or equipment.size() != Party.DEFAULT_PARTY_IDS.size():
		return false
	var counts: Dictionary = {}
	for hero: Dictionary in Party.default_party():
		var loadout: Variant = equipment.get(hero.combat_unit_id)
		if not loadout is Dictionary or loadout.size() not in [LEGACY_SLOTS.size(),SLOTS.size()]:
			return false
		var slots: Array=SLOTS if loadout.size()==SLOTS.size() else LEGACY_SLOTS
		for slot: String in slots:
			if not loadout.has(slot):
				return false
			var id: Variant = loadout[slot]
			if id == null:
				continue
			if not id is String:
				return false
			var profile: Dictionary = Items.item(id).get("combat_profile", {})
			if profile.is_empty() or profile.get("slot") != slot:
				return false
			counts[id] = int(counts.get(id, 0)) + 1
			if counts[id] > owned.count(id):
				return false
		if loadout.main_hand != null and bool(Items.item(loadout.main_hand).get("combat_profile", {}).get("two_handed", false)) and loadout.off_hand != null:
			return false
	return true


static func apply(encounter: Dictionary, equipment: Dictionary) -> Dictionary:
	var next := encounter.duplicate(true)
	var profiles: Dictionary = next.get("item_profiles", {}).duplicate(true)
	for unit: Dictionary in next.get("units", []):
		var hero := Party.hero_for_combat_unit(str(unit.id))
		if hero.is_empty() or not equipment.has(unit.id):
			continue
		unit.loadout = normalized(equipment)[unit.id]
		unit.available_actions = hero.available_actions.duplicate(true)
		for id in unit.loadout.values():
			if id != null:
				profiles[id] = Items.item(id).combat_profile.duplicate(true)
		unit.visual = Identity.visual(hero, unit.loadout)
	next.item_profiles = profiles
	return next

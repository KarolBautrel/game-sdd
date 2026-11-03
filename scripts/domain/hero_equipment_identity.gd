extends RefCounted
## Authored hero/kit variants. Inventory mechanics remain in CampaignEquipment.
const PATH := "res://resources/data/presentation/hero_equipment_identity.json"
const Items := preload("res://scripts/domain/item_catalog.gd")


static func visual(hero: Dictionary, loadout: Dictionary) -> Dictionary:
	var main_id: Variant = loadout.get("main_hand")
	var fallback: Dictionary = hero.visual.duplicate(true)
	if main_id != null:
		fallback = Items.item(main_id).get("visual", hero.visual).duplicate(true)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var identity: Dictionary = data.get("heroes", {}).get(hero.id, {})
	if identity.get("combat_unit_id", "") != hero.combat_unit_id:
		return fallback
	var weapon := "none" if main_id == null else str(Items.item(main_id).get("appearance", {}).get("weapon", "unknown"))
	var off_id: Variant = loadout.get("off_hand")
	var offhand := "none" if off_id == null else str(Items.item(off_id).get("appearance", {}).get("offhand", "unknown"))
	for kit: Dictionary in identity.get("kits", []):
		if kit.weapon == weapon and kit.offhand == offhand:
			return kit.visual.duplicate(true)
	return fallback

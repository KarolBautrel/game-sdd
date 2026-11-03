extends RefCounted
## Opt-in ordinary campaign, using only this isolated, resumable QA profile.
const SAVE_PATH := "user://qa_hero_equipment_pilot_v1.json"
const BRAN := "unit_player_001"


static func open(campaign: Node, path: String = SAVE_PATH) -> bool:
	if not path.begins_with("user://qa_hero_equipment_") or not path.ends_with(".json"):
		campaign.loaded = false
		campaign.last_feedback = "Equipment pilot save path is invalid."
		return false
	var existed := FileAccess.file_exists(path)
	if not campaign.load_profile(path):
		return false
	if existed:
		return true
	campaign.state.items.append_array(["salvaged_shield", "hero_greatsword"])
	if not campaign.equip(BRAN, "off_hand", "salvaged_shield"):
		campaign.loaded = false
		return false
	campaign.last_feedback = "Equipment pilot: Bran owns both sword/shield and greatsword. Unequip the shield before equipping the greatsword."
	return true

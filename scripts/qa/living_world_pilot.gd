extends RefCounted
const SAVE_PATH := "user://qa_living_world_v1.json"
static func open(campaign: Node,path: String = SAVE_PATH) -> bool:
	if not path.begins_with("user://qa_living_world_") or not path.ends_with(".json"): return false
	if not campaign.load_profile(path): return false
	if campaign.living_active(): return true
	return campaign.enable_living_world()

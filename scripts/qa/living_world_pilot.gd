extends RefCounted
const SAVE_PATH := "user://qa_living_world_v1.json"
static func open(campaign: Node,path: String = SAVE_PATH) -> bool:
	if not path.begins_with("user://qa_living_world_") or not path.ends_with(".json"): return false
	var previous:=_snapshot(campaign)
	if not campaign.load_profile(path): _restore(campaign,previous);return false
	if campaign.living_active(): return true
	if campaign.enable_living_world(): return true
	_restore(campaign,previous);return false

static func _snapshot(campaign: Node) -> Dictionary:
	var result: Dictionary={}
	for key in ["state","loaded","save_path","memory_only","living_motion","requested_campaign_tab"]: result[key]=campaign.get(key)
	return result
static func _restore(campaign: Node,previous: Dictionary) -> void:
	for key in previous: campaign.set(key,previous[key])

static func generated_path(seed_value: int,preset: String,version: int=1) -> String:
	return "user://qa_living_world_generated_v%d_%s_%d.json" % [version,preset,seed_value]

static func open_generated(campaign: Node,seed_value: int,preset: String,version: int=1) -> bool:
	if seed_value<1 or seed_value>1000000000 or version not in [1,2,3] or not preload("res://scripts/domain/region_generator.gd").PRESETS.has(preset): return false
	if campaign.living_active():
		var current: Dictionary=campaign.state.living_world.get("geography",{})
		if int(current.get("seed",-1))==seed_value and current.get("preset","")==preset and int(current.get("version",0))==version: return true
	var previous:=_snapshot(campaign)
	if campaign.memory_only:
		campaign.load_profile("",true)
	else:
		if not campaign.load_profile(generated_path(seed_value,preset,version)): _restore(campaign,previous);return false
	if campaign.living_active():
		var geo: Dictionary=campaign.state.living_world.get("geography",{})
		if int(geo.get("seed",-1))==seed_value and geo.get("preset","")==preset and int(geo.get("version",0))==version: return true
	elif campaign.enable_generated_region(seed_value,preset,version): return true
	_restore(campaign,previous);return false

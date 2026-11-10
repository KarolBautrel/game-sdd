extends Node
## Explicit opt-in owner for existing dungeon/combat UI. Never writes legacy files.
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const Region := Session.Region
const Travel := Session.Company.Travel
const Gear := Session.Company.Gear
var session := Session.new()
var active := false
var loaded: bool:
	get: return active and session.loaded and Session.World._count(session.state.get("version"),3,4)
var state: Dictionary:
	get: return session.state.company if loaded else {}
var last_feedback: String:
	get: return session.last_feedback
var memory_only: bool:
	get: return session.memory_only

func regional_active() -> bool: return loaded
func world_return_scene() -> String:
	var vast: bool=loaded and session.state.region.base.version==3
	if loaded and session.state.version==4: return "res://scenes/world/StrategistVastWorld.tscn" if vast else "res://scenes/world/StrategistWorld.tscn"
	return "res://scenes/world/StrategicVastWorld.tscn" if vast else "res://scenes/world/StrategicWorld.tscn"
func living_active() -> bool: return false
static func campaign_path(seed_value: int, preset: String, model: bool, geography_version: int=2) -> String:
	return "user://qa_strategy_world_"+("model_v4_" if model else "region_v3_")+("g3_" if geography_version==3 else "")+"%s_%d.json" % [preset,seed_value]

func open_seed(seed_value: int=2087, preset: String="marches", in_memory: bool=false, geography_version: int=2) -> bool:
	return _open_seed(seed_value,preset,in_memory,false,geography_version)
func open_model_seed(seed_value: int=2087, preset: String="marches", in_memory: bool=false, geography_version: int=2) -> bool:
	return _open_seed(seed_value,preset,in_memory,true,geography_version)
func _open_seed(seed_value: int, preset: String, in_memory: bool, model: bool, geography_version: int) -> bool:
	if geography_version not in [2,3]: return false
	var next := Session.new()
	var path := campaign_path(seed_value,preset,model,geography_version)
	var accepted: bool=next.call("create_model" if model else "create_region",seed_value,"",true,preset,geography_version) if in_memory else (next.load_profile(path) if FileAccess.file_exists(path) else next.call("create_model" if model else "create_region",seed_value,path,false,preset,geography_version))
	if not accepted:
		session.last_feedback=next.last_feedback;return false
	if next.state.get("version")!=(4 if model else 3) or next.state.region.base.version!=geography_version or next.state.region.base.seed!=seed_value or next.state.region.base.preset!=preset:
		session.last_feedback="Saved campaign does not match the selected size, seed or biome.";return false
	session=next;active=true
	if has_node("/root/DungeonRunSession"): get_node("/root/DungeonRunSession").clear()
	session.last_feedback="Company ready in "+session.state.region.base.name+". Time is paused."
	return true

func pump_strategy() -> bool: return session.pump_model() if loaded and session.state.version==4 else false

func order(action: String, payload: Dictionary={}) -> bool:
	if not loaded or not session.regional(action,payload): return false
	if action=="course": session.last_feedback="Course set."
	elif action=="begin_run": session.last_feedback="Expedition packed from owned supplies."
	elif action=="checkpoint": session.last_feedback="Expedition progress saved."
	elif action=="model_mode": session.last_feedback="Strategist mode: "+("Classic." if payload.mode=="classic" else "Recorded examples; no live model.")
	elif not session.state.notes.is_empty(): session.last_feedback=session.state.notes.back().text
	return true
func at_town() -> bool: return loaded and Region.at_town(session.state)
func can_trade() -> bool: return at_town()
func begin_run(data: Dictionary, run_state: Dictionary) -> bool:
	return order("begin_run",{"data":data,"state":run_state})
func checkpoint(data: Dictionary, run_state: Dictionary, seed_value: int=0) -> bool:
	return order("checkpoint",{"data":data,"state":run_state,"seed":seed_value})
func settle(payload: Dictionary) -> bool: return order("settle",{"payload":payload})
func purchase(id: String) -> bool: return order("buy_supply",{"id":id})
func recover() -> bool: return order("recover")
func equip(hero: String, slot: String, item: Variant) -> bool:
	return order("equip",{"hero":hero,"slot":slot,"item":item})
func purchase_item(id: String) -> bool: return order("purchase_item",{"id":id})
func sell_item(id: String) -> bool: return order("sell_item",{"id":id})
func train(hero: String) -> bool: return order("train",{"hero":hero})
func available_xp() -> int:
	return int(state.xp)-Session.Company.Advancement.allocated(state.advancement) if loaded else 0

func deactivate() -> void:
	active=false
	if has_node("/root/DungeonRunSession"): get_node("/root/DungeonRunSession").clear()

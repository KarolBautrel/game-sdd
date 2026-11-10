extends RefCounted
## Dedicated opt-in session; not an autoload and never a live-map replacement.
const World := preload("res://scripts/domain/world_strategy.gd")
const Classic := preload("res://scripts/domain/classic_world.gd")
const Region := preload("res://scripts/domain/strategic_region.gd")
const Model := preload("res://scripts/domain/strategist_campaign.gd")
const Recorded := preload("res://scripts/domain/recorded_strategist.gd")
const Company := preload("res://scripts/session/campaign_session.gd")
const Kind := preload("res://scripts/session/campaign_profile_kind.gd")
var state: Dictionary = {}
var loaded := false
var save_path := ""
var memory_only := true
var last_feedback := ""
var last_motion: Dictionary={}
static var transport_counter := 0
static var dispatch_times: Array[int]=[]
var transport_epoch := 0
var transport_tickets: Dictionary={}
var reply_cache: Dictionary={}

static func initial(seed_value: int = 2087) -> Dictionary:
	var world := World.initial(seed_value)
	if world.is_empty(): return {}
	var company := Company.initial_profile()
	company.gold = 80; company.supplies.food = 16; company.world.seed = seed_value
	return {"schema":Kind.STRATEGY_SCHEMA,"version":1,"company":company,"strategy_world":world,"current_settlement_id":"town_ravenford"}

static func valid(value: Variant) -> bool:
	if value is Dictionary and World._count(value.get("version"),4,4): return Model.valid(value)
	if value is Dictionary and World._count(value.get("version"),3,3): return Region.valid(value)
	if not World._shape(value,["schema","version","company","strategy_world","current_settlement_id"]): return false
	if Kind.classify(value) != "strategy" or not World._count(value.version,1,2): return false
	if not (World.valid(value.strategy_world) if value.version==1 else Classic.S.valid(value.strategy_world)): return false
	var core: Dictionary=value.strategy_world if value.version==1 else value.strategy_world.core
	if not World._id(value.current_settlement_id) or not core.settlements.has(value.current_settlement_id): return false
	if not value.company is Dictionary or not World._count(value.company.get("version"),4,4) or value.company.has("living_world"): return false
	var accepted: bool = Company._valid_profile(value.company)
	if not accepted or not value.company.active_run.is_empty() or not value.company.world.pending_event.is_empty(): return false
	if value.company.world.seed != core.seed or int(value.company.world.elapsed_hours) != int(core.tick)/4: return false
	return true

func create(seed_value: int = 2087, path: String = "", in_memory: bool = true) -> bool:
	return _create(seed_value,path,in_memory,1)

func create_classic(seed_value: int = 2087, path: String = "", in_memory: bool = true) -> bool:
	return _create(seed_value,path,in_memory,2)

func create_region(seed_value: int=2087, path: String="", in_memory: bool=true, preset: String="marches", geography_version: int=2) -> bool:
	return _create(seed_value,path,in_memory,3,preset,geography_version)

func create_model(seed_value: int=2087, path: String="", in_memory: bool=true, preset: String="marches", geography_version: int=2) -> bool:
	return _create(seed_value,path,in_memory,4,preset,geography_version)

func _create(seed_value: int, path: String, in_memory: bool, format_version: int, preset: String="marches", geography_version: int=2) -> bool:
	if loaded: return _reject("A strategy campaign is already loaded.")
	if not in_memory and (not Kind.is_strategy_path(path) or FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path))):
		return _reject("Create requires a fresh dedicated strategy QA path.")
	_reset_transport()
	var candidate := Model.initial(seed_value,preset,geography_version) if format_version==4 else (Region.initial(seed_value,preset,geography_version) if format_version==3 else initial(seed_value))
	if candidate.is_empty(): return _reject("Invalid strategy seed or foundation data.")
	if format_version==2:
		candidate.version=2;candidate.strategy_world=Classic.initial(seed_value)
		if candidate.strategy_world.is_empty(): return _reject("Invalid classic configuration.")
	save_path = path; memory_only = in_memory
	if not _commit(candidate): return false
	loaded = true
	return true

func load_profile(path: String) -> bool:
	_reset_transport()
	loaded = false
	if not Kind.is_strategy_path(path): return _reject("Use a dedicated strategy QA profile.")
	if not FileAccess.file_exists(path): return _reject("Strategy profile is missing; no campaign was created.")
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return _reject("Cannot read strategy profile.")
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or not valid(json.data): return _reject("Invalid or unsupported strategy profile. Existing file preserved.")
	state = json.data
	save_path = path; memory_only = false; loaded = true
	last_feedback = "Strategy foundation loaded without advancing time."
	return true

func apply_command(cmd: Dictionary) -> bool:
	if not loaded: return _reject("No valid strategy campaign is loaded.")
	if state.version==4:
		var model := Model.apply(state,cmd)
		if not model.ok: return _reject(str(model.reason))
		if not _commit(model.state): return false
		last_motion=model.motion;return true
	if state.version==3:
		var regional := Region.apply(state,cmd)
		if not regional.ok: return _reject(str(regional.reason))
		if not _commit(regional.state): return false
		last_motion=regional.motion
		return true
	var result := World.apply(state.strategy_world,cmd) if state.version==1 else Classic.apply(state.strategy_world,cmd)
	if not result.ok: return _reject(str(result.reason))
	var next := state.duplicate(true)
	next.strategy_world = result.state
	if next.version==2: next.company.world.elapsed_hours=int(result.state.core.tick)/4
	return _commit(next)

func regional(action: String, payload: Dictionary={}) -> bool:
	if not loaded or not World._count(state.version,3,4): return _reject("No regional campaign is loaded.")
	return apply_command(Region.command(state,action,payload))

func _reset_transport() -> void:
	transport_counter+=1;transport_epoch=transport_counter;transport_tickets={};reply_cache={}

func _model_active() -> bool:
	return loaded and state.version==4 and state.strategist.mode=="recorded" and state.company.active_run.is_empty()

func _sync_transport(now_ms: int) -> bool:
	if transport_epoch!=transport_counter: _reset_transport()
	var a: Dictionary=state.strategist
	for id: String in Model.A.C.S.sorted_ids(a.pending):
		var pending: Dictionary=a.pending[id];var q: Dictionary=pending.request
		if pending.status!="sent" or reply_cache.has(q.request_id): continue
		var reason := ""
		if not transport_tickets.has(q.request_id): reason="interrupted"
		elif now_ms-int(transport_tickets[q.request_id].started_ms)>=int(a.rules.timeout_ms): reason="timeout"
		if reason!="" and regional("model_fault",{"request_id":q.request_id,"reason":reason}):
			transport_tickets.erase(q.request_id);return true
	for id: String in transport_tickets.keys():
		if Model.A.pending_actor(state.strategist,id)=="": transport_tickets.erase(id);reply_cache.erase(id)
	return false

func take_model_request(now_ms: int=-1) -> Dictionary:
	if not _model_active(): return {}
	if now_ms<0: now_ms=Time.get_ticks_msec()
	_sync_transport(now_ms)
	var a: Dictionary=state.strategist
	dispatch_times=dispatch_times.filter(func(at): return now_ms-at<60000)
	for actor: String in Model.A.C.S.sorted_ids(a.pending):
		var pending: Dictionary=a.pending[actor];var q: Dictionary=pending.request
		if pending.status!="ready": continue
		if dispatch_times.size()>=int(a.rules.calls_per_minute):
			regional("model_fault",{"request_id":q.request_id,"reason":"budget"});return {}
		if not regional("model_dispatch",{"request_id":q.request_id}): return {}
		if state.strategist.pending[actor].status!="sent": return {}
		var ticket := {"epoch":transport_epoch,"generation":int(q.generation),"request_id":q.request_id,"started_ms":now_ms}
		transport_tickets[q.request_id]=ticket;dispatch_times.append(now_ms)
		return {"ticket":ticket.duplicate(true),"request":q.duplicate(true)}
	return {}

func submit_model_reply(ticket: Dictionary, raw: String, now_ms: int=-1) -> bool:
	if not _model_active() or not World._shape(ticket,["epoch","generation","request_id","started_ms"]) or not World._count(ticket.epoch,1) or not World._count(ticket.generation,1) or not World._count(ticket.started_ms) or ticket.epoch!=transport_epoch or transport_epoch!=transport_counter or ticket.generation!=state.strategist.generation or not ticket.request_id is String or not transport_tickets.has(ticket.request_id) or not Company.same_data(ticket,transport_tickets[ticket.request_id]): return false
	var actor := Model.A.pending_actor(state.strategist,ticket.request_id)
	if actor=="" or state.strategist.pending[actor].status!="sent": return false
	if now_ms<0: now_ms=Time.get_ticks_msec()
	if not reply_cache.has(ticket.request_id) and now_ms-int(ticket.started_ms)>=int(state.strategist.rules.timeout_ms):
		if regional("model_fault",{"request_id":ticket.request_id,"reason":"timeout"}): transport_tickets.erase(ticket.request_id)
		return false
	var json := JSON.new();var reason := "malformed"
	if raw.to_utf8_buffer().size()<=16384 and json.parse(raw)==OK: reason=Model.A.P.reply_reason(state.strategist.pending[actor].request,json.data)
	if reason!="":
		if regional("model_fault",{"request_id":ticket.request_id,"reason":reason}): transport_tickets.erase(ticket.request_id)
		return false
	reply_cache[ticket.request_id]={"ticket":ticket.duplicate(true),"raw":raw}
	if not regional("model_reply",{"request_id":ticket.request_id,"raw":raw}): return false
	reply_cache.erase(ticket.request_id);transport_tickets.erase(ticket.request_id);return true

func pump_model(now_ms: int=-1) -> bool:
	if not _model_active(): return false
	if now_ms<0: now_ms=Time.get_ticks_msec()
	var sequence := int(state.request_seq)
	var changed := _sync_transport(now_ms)
	for id: String in reply_cache.keys():
		var cached: Dictionary=reply_cache[id]
		if submit_model_reply(cached.ticket,cached.raw,now_ms): return true
		if Model.A.pending_actor(state.strategist,id)=="": reply_cache.erase(id)
	var dispatch := take_model_request(now_ms)
	if dispatch.is_empty(): return changed or state.request_seq!=sequence
	return submit_model_reply(dispatch.ticket,Recorded.reply(dispatch.request),now_ms) or changed

func _commit(candidate: Dictionary) -> bool:
	if not valid(candidate): return _reject("Invalid strategy transaction.")
	if not memory_only:
		if not Kind.is_strategy_path(save_path): return _reject("Strategy writes require the dedicated QA path.")
		var temporary := save_path+".tmp"
		var file := FileAccess.open(temporary,FileAccess.WRITE)
		if file == null: return _reject("Cannot write strategy profile; transaction cancelled.")
		file.store_string(JSON.stringify(candidate,"\t",true,true)+"\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(save_path)) != OK:
			return _reject("Cannot replace strategy profile; transaction cancelled.")
	state = candidate
	last_feedback = "Strategy transaction saved."
	return true

func _reject(message: String) -> bool:
	last_feedback = message
	return false

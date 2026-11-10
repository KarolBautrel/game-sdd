extends SceneTree
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const M := Session.Model
const A := M.A
const P := A.P
var checks := 0
var failures: Array[String]=[]
var baseline: Dictionary={}
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func order(s: RefCounted, action: String, payload: Dictionary={}) -> bool:
	var ok: bool=s.regional(action,payload);check(ok,action+" / "+s.last_feedback);return ok
func clone_ready() -> RefCounted:
	var s := Session.new();s.state=baseline.duplicate(true);s.loaded=true;s._reset_transport();Session.dispatch_times=[];return s
func advance(s: RefCounted) -> void: order(s,"advance",{"ticks":24})
func _initialize() -> void:
	var setup := Session.new();check(setup.create_model(),"explicit in-memory v4 creation")
	order(setup,"model_mode",{"mode":"recorded"});order(setup,"advance",{"ticks":192});order(setup,"advance",{"ticks":72});baseline=setup.state.duplicate(true)
	check(baseline.strategist.pending.size()==1,"real first request from native world clock")
	lifecycle();stale();disk()
	for failure: String in failures: push_error(failure)
	print("strategist_session_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func lifecycle() -> void:
	var s := clone_ready();var dispatch: Dictionary=s.take_model_request(100000)
	check(not dispatch.is_empty(),"persist dispatch before exposing request ticket")
	if dispatch.is_empty(): return
	var bad: Dictionary=dispatch.ticket.duplicate();bad.epoch=true
	check(not s.submit_model_reply(bad,Session.Recorded.reply(dispatch.request)),"boolean ticket version fails without diagnostics")
	check(s.pump_model(110001),"timeout recorded asynchronously")
	check(s.state.strategy_world.core.tick==264 and s.state.strategist.pending.values()[0].fault=="timeout","timeout advances no strategic time")
	advance(s);check(s.state.strategist.journal.back().reason=="timeout","timeout chooses classic plan at boundary")
	s=clone_ready();dispatch=s.take_model_request(100000)
	check(not s.submit_model_reply(dispatch.ticket,Session.Recorded.reply(dispatch.request),110001),"callback itself enforces real-time timeout before another poll")
	check(s.state.strategy_world.core.tick==264 and s.state.strategist.pending.values()[0].fault=="timeout","late callback advances no strategic time")
	advance(s);check(s.state.strategist.journal.back().reason=="timeout","late callback falls back at fixed boundary")
	s=clone_ready();dispatch=s.take_model_request(100000)
	check(not s.submit_model_reply(dispatch.ticket,"{bad"),"malformed transport reply rejected")
	advance(s);check(s.state.strategist.journal.back().reason=="malformed","malformed response falls back")
	for budget: String in ["calls_per_day","tokens_per_day"]:
		s=clone_ready();s.state.strategist.rules[budget]=0
		check(s.take_model_request(100000).is_empty() and s.state.strategist.budget.calls==0,"daily budget prevents dispatch / "+budget)
		advance(s);check(s.state.strategist.journal.back().reason=="budget","budget exhaustion uses classic")
	s=clone_ready();s.state.strategist.rules.calls_per_minute=1
	for id: String in s.state.strategist.next_review: s.state.strategist.next_review[id]=264
	A.review(s.state.strategist,A.observations(s.state.strategy_world))
	check(M.valid(s.state) and s.state.strategist.pending.size()==4,"one bounded request per faction")
	dispatch=s.take_model_request(100000)
	check(s.submit_model_reply(dispatch.ticket,Session.Recorded.reply(dispatch.request)),"first rate-limited response queues")
	check(s.take_model_request(100001).is_empty() and s.state.strategist.budget.calls==1,"global real-minute ceiling blocks second dispatch")
	s=clone_ready();dispatch=s.take_model_request(100000)
	var raw := Session.Recorded.reply(dispatch.request)
	order(s,"model_mode",{"mode":"classic"})
	var before := P.encoded(s.state)
	check(s.state.strategist.pending.is_empty() and s.state.strategist.totals.cancelled==1,"mode switch cancels outstanding work")
	check(not s.submit_model_reply(dispatch.ticket,raw) and P.encoded(s.state)==before,"old-generation callback cannot mutate")
	order(s,"model_mode",{"mode":"recorded"});check(s.state.strategist.generation==3 and s.state.strategist.request_seq==1,"switch preserves request watermark")
func stale() -> void:
	var s := clone_ready();var dispatch: Dictionary=s.take_model_request(100000)
	check(s.submit_model_reply(dispatch.ticket,Session.Recorded.reply(dispatch.request)),"queue proposal before public context changes")
	var world: Dictionary=s.state.strategy_world;var actor: String=dispatch.request.faction_id
	var target := "river_league" if actor!="river_league" else "cinder_compact"
	var pact := A.C.S.next_id(world,"pact")
	check(A.C._operate(world,actor,"propose_pact",{"id":pact,"target":target,"kind":"nonaggression","duration_ticks":672,"valid_for_ticks":96})=="","ordinary pact proposal")
	check(A.C._operate(world,target,"accept_pact",{"id":pact})=="" and M.valid(s.state),"actual counterpart consent changes public context")
	advance(s);check(s.state.strategist.journal.back().reason=="stale","changed diplomatic facts invalidate stale model context")
func block(path: String) -> void:
	check(not FileAccess.file_exists(path+".tmp") and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path+".tmp")),"fresh owned failure fixture")
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"owned empty directory blocks atomic writer")
func unblock(path: String) -> void:
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"remove only owned empty blocker")
func disk() -> void:
	var path := "user://qa_strategy_world_model_atomic_%d.json" % Time.get_ticks_usec()
	check(not FileAccess.file_exists(path),"fresh QA file, never a player save")
	if FileAccess.file_exists(path): return
	var s := clone_ready();s.memory_only=false;s.save_path=path
	check(s._commit(baseline.duplicate(true)),"persist real pending checkpoint")
	var before := P.encoded(s.state);var bytes := FileAccess.get_file_as_string(path)
	block(path)
	check(s.take_model_request(100000).is_empty() and P.encoded(s.state)==before and FileAccess.get_file_as_string(path)==bytes,"failed dispatch-save reserves/calls nothing")
	check(s.transport_tickets.is_empty() and Session.dispatch_times.is_empty(),"failed save exposes no transport work")
	unblock(path)
	var dispatch: Dictionary=s.take_model_request(100000);check(not dispatch.is_empty(),"dispatch retry succeeds once")
	if dispatch.is_empty(): return
	before=P.encoded(s.state);bytes=FileAccess.get_file_as_string(path);block(path)
	check(not s.submit_model_reply(dispatch.ticket,Session.Recorded.reply(dispatch.request)) and s.reply_cache.size()==1,"failed reply save retains exact bytes in runtime cache")
	check(P.encoded(s.state)==before and FileAccess.get_file_as_string(path)==bytes,"failed reply write leaves durable state untouched")
	unblock(path)
	check(s.pump_model(100001) and s.state.strategist.totals.dispatched==1 and s.reply_cache.is_empty(),"cached reply retry does not dispatch again")
	var reader := Session.new();check(reader.load_profile(path) and P.encoded(reader.state)==P.encoded(s.state),"queued reply persists through exact disk reload")
	before=P.encoded(reader.state);bytes=FileAccess.get_file_as_string(path);block(path)
	check(not reader.regional("advance",{"ticks":24}) and P.encoded(reader.state)==before and FileAccess.get_file_as_string(path)==bytes,"failed apply boundary rolls back plan/time/effects/journal/receipts")
	unblock(path);advance(reader)
	check(reader.state.strategist.totals.accepted==1 and M.valid(reader.state),"boundary retry applies once")
	var exact := Session.new();check(exact.load_profile(path) and P.encoded(exact.state)==P.encoded(reader.state),"accepted decisions and actual world roundtrip")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK,"remove own atomic QA profile")
	# A sent request cannot be silently reissued after a process/session restart.
	path="user://qa_strategy_world_model_interrupt_%d.json" % Time.get_ticks_usec()
	s=clone_ready();s.memory_only=false;s.save_path=path
	check(not FileAccess.file_exists(path) and s._commit(s.state.duplicate(true)),"fresh interruption checkpoint")
	dispatch=s.take_model_request(100000)
	var resumed := Session.new();check(resumed.load_profile(path),"resume sent request")
	bytes=FileAccess.get_file_as_string(path)
	check(not s.submit_model_reply(dispatch.ticket,Session.Recorded.reply(dispatch.request)) and FileAccess.get_file_as_string(path)==bytes,"abandoned session callback cannot rewrite active profile")
	check(resumed.pump_model(100001) and resumed.state.strategist.pending.values()[0].fault=="interrupted","restart records interrupted transport without redispatch")
	advance(resumed);check(resumed.state.strategist.journal.back().reason=="interrupted" and resumed.state.strategist.totals.dispatched==1,"restart falls back with one dispatch watermark")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK,"remove own interruption QA profile")

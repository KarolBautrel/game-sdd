extends SceneTree
const C := preload("res://scripts/domain/classic_world.gd")
const S := C.S
const P := C.Planner
const Company := preload("res://scripts/session/campaign_session.gd")
var checks := 0
var failures: Array[String]=[]
var diagnostics: Array=[]

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)

func _initialize() -> void:
	var s := C.initial(2089)
	var obs := C.observe(s,"iron_march")
	var choice := P.choose(obs)
	check(choice.goal=="claim" and choice.target=="river_league","actual disputed ore motivates a claim plan")
	check(choice.commit_until-choice.selected_tick==288 and choice.review_tick-choice.selected_tick==672,"three-day commitment / weekly review")
	check(not obs.has("core") and not obs.has("company") and not obs.has("plans") and not obs.own.policy.has("river_league"),"observation excludes world/company/opponents' private plans")
	var hidden := s.duplicate(true)
	hidden.plans.river_league.reason="secret_changed"
	hidden.rules.policies.river_league.personality.aggression=99
	check(Company.same_data(obs,C.observe(hidden,"iron_march")),"hidden enemy ambition/plan cannot affect observation")
	check(Company.same_data(P.choose(obs),choice),"planner has no random/global mutation")
	var reordered := s.duplicate(true)
	for field: String in ["factions","settlements","routes","parties","diplomacy"]:
		var original: Dictionary=reordered.core[field].duplicate(true)
		reordered.core[field].clear();var keys: Array=original.keys();keys.reverse()
		for key: String in keys: reordered.core[field][key]=original[key]
	var a := C.apply(s,C.command(s,"world_clock","advance",{"ticks":672}))
	var b := C.apply(reordered,C.command(reordered,"world_clock","advance",{"ticks":672}))
	check(a.ok and b.ok and Company.same_data(a.state,b.state),"dictionary insertion order cannot alter a week of decisions")
	var peace_world := C.initial(2088)
	check(peace_world.plans.iron_march.goal!="claim","cooperative premise does not force scheduled war")
	for seed_value in range(2080,2096): soak(seed_value,180)
	soak(2088,720);soak(2089,720)
	var total_wars := 0;var total_peace := 0;var total_volume := 0
	for row: Dictionary in diagnostics:
		total_wars+=int(row.wars);total_peace+=int(row.peace);total_volume+=int(row.trade_volume)
	check(total_wars>0 and total_peace>0 and total_volume>0,"campaign matrix exercises real trade, conflict and peace")
	# Explicit QA output path only; no player files or desktop.
	var directory := "res://artifacts/qa-runs/classic-strategy-diagnostics"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/campaigns.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(diagnostics,"\t",true,true)+"\n");file.close()
	for failure: String in failures: push_error(failure)
	print("faction_planner_tests: %d checks, %d failures, %d campaigns" % [checks,failures.size(),diagnostics.size()])
	quit(0 if failures.is_empty() else 1)

func soak(seed_value: int, days: int) -> void:
	var s := C.initial(seed_value)
	var elapsed := 0
	while elapsed<days:
		var step := mini(7,days-elapsed)
		var result := C.apply(s,C.command(s,"world_clock","advance",{"ticks":step*96}))
		check(result.ok,"seed%d day%d: %s" % [seed_value,elapsed+step,result.reason])
		if not result.ok: return
		s=result.state;elapsed+=step
		check(S.reconciles(s),"all stocks/cargo/escrow reconcile seed%d day%d" % [seed_value,elapsed])
		if elapsed==7:
			var reload: Variant=JSON.parse_string(JSON.stringify(s,"",true,true))
			var cmd := C.command(s,"world_clock","advance",{"ticks":96})
			var normal := C.apply(s,cmd);var restored := C.apply(reload,cmd)
			check(normal.ok and restored.ok and Company.same_data(normal.state,restored.state),"exact JSON continuation seed%d" % seed_value)
	check(s.events.size()<=128 and s.receipts.size()<=64 and s.trades.size()<512 and s.core.pact_offers.size()<512,"histories remain bounded seed%d" % seed_value)
	for records: Array in s.decisions.values(): check(records.size()<=16,"bounded private decision history")
	var row: Dictionary=s.metrics.duplicate(true)
	row.merge({"seed":seed_value,"days":days,"premise":s.premise,"entity_seq":s.entity_seq,"event_seq":s.event_seq,"retained_trades":s.trades.size(),"retained_pacts":s.core.pact_offers.size(),"ending_stocks":S.totals(s),"ending_manpower":s.core.factions.values().reduce(func(n,f): return n+f.manpower,0)})
	diagnostics.append(row)

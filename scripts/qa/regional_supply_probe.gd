extends SceneTree
## Native regional clock/job/upkeep probe. Memory only; no player save/session.
const R := preload("res://scripts/domain/strategic_region.gd")
const P := preload("res://scripts/domain/strategist_protocol.gd")
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=2 or args[0]!="--label" or RegEx.create_from_string("^[a-z0-9][a-z0-9-]{0,63}$").search(args[1])==null: fail("Use --label with a safe new identifier.");return
	var directory := "res://artifacts/qa-runs/regional-supply-"+args[1]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)): fail("Native probe output already exists.");return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK: fail("Cannot create owned probe directory.");return
	var rows: Array=[]
	for seed_value: int in [2087,2088,2089]:
		for size: int in [2,3]:
			var s := R.initial(seed_value,"marches",size)
			if s.is_empty(): fail("Native region creation failed.");return
			var start := P.digest(s)
			var stats := {"food_shortfall_faction_days":0,"rejections":{},"steps":0}
			var observer := func(phase: String, payload: Dictionary) -> Dictionary:
				if phase=="review":
					for o: Dictionary in payload.values():
						if int(o.tick)%96==0 and o.own.shortfalls.food>0: stats.food_shortfall_faction_days+=1
				if phase=="outcomes":
					for result: Dictionary in payload.results:
						if result.reason!="": stats.rejections[result.reason]=int(stats.rejections.get(result.reason,0))+1
				return {}
			for step in range(15):
				var result := R.apply(s,R.command(s,"advance",{"ticks":192}),observer)
				if not result.ok or not R.C.S.reconciles(result.state.strategy_world): fail("Native day%d: %s" % [(step+1)*2,result.reason]);return
				s=result.state;stats.steps+=1
			var row := {"seed":seed_value,"generator_version":size,"days":30,"initial_digest":start,"final_digest":P.digest(s),"geography_checksum":s.region.checksum,"metrics":s.strategy_world.metrics.duplicate(true),"food_shortfall_faction_days":stats.food_shortfall_faction_days,"rejections":stats.rejections,"job_seq":int(s.job_seq),"retained_jobs":s.jobs.size(),"company_gold":int(s.company.gold),"company_food":int(s.company.supplies.food),"mine":s.mine.status,"reconciled":R.C.S.reconciles(s.strategy_world),"steps":stats.steps}
			rows.append(row)
			print("native supply seed%d g%d: %d deliveries / %d shortage faction-days / %d issued jobs" % [seed_value,size,row.metrics.trade_delivered,row.food_shortfall_faction_days,row.job_seq])
	var file := FileAccess.open(directory+"/campaigns.json",FileAccess.WRITE)
	if file==null: fail("Cannot write native probe result.");return
	file.store_string(JSON.stringify({"schema":"sdd.native-supply-probe","version":1,"mode":"classic","scope":"actual regional jobs/upkeep; idle company, occupied mine, no user save","cases":rows},"\t",true,true)+"\n");file.close()
	print("regional_supply_probe: 6 cases PASS / no player file or transport");quit(0)
func fail(reason: String) -> void:
	push_error(reason);quit(1)

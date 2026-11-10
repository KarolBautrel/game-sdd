extends SceneTree
const Bench := preload("res://scripts/qa/strategy_comparison.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args();var days := 180;var label := ""
	if args.size()%2!=0: fail("Expected --days N / --label ID.");return
	for i in range(0,args.size(),2):
		if args[i]=="--days" and args[i+1].is_valid_int(): days=int(args[i+1])
		elif args[i]=="--label": label=args[i+1]
		else: fail("Unknown comparison argument.");return
	if days<1 or days>720 or RegEx.create_from_string("^[a-z0-9][a-z0-9-]{0,63}$").search(label)==null: fail("Use1..720days and a safe explicit --label.");return
	var directory := "res://artifacts/qa-runs/strategy-comparison-"+label
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)): fail("Comparison output already exists.");return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK: fail("Cannot create owned output.");return
	var rows: Array=[]
	for seed_value: int in [2087,2088,2089]:
		for size: int in [2,3]:
			var campaign := Bench.R.initial(seed_value,"marches",size)
			if campaign.is_empty(): fail("Cannot bind opening region.");return
			var starting := Bench.P.digest(campaign.strategy_world)
			for mode: String in ["classic","recorded"]:
				var experiment := Bench.initial(campaign.strategy_world,mode)
				for boundary in range(days*4):
					var result := Bench.step(experiment)
					if not result.ok: fail("seed%d size%d %s boundary%d: %s" % [seed_value,size,mode,boundary,result.reason]);return
					experiment=result.state
				var row := Bench.report(experiment)
				row["size"]="Large" if size==2 else "Vast";row["generator_version"]=size;row["geography_checksum"]=campaign.region.checksum
				if row.initial_digest!=starting: fail("Matched starting world changed.");return
				rows.append(row)
				print("comparison seed%d %s %s day%d: %d deliveries / %d shortage faction-days / %d rejected" % [seed_value,row.size,mode,days,row.metrics.trade_delivered,row.food_shortfall_faction_days,row.metrics.rejected_intents])
	var report := {"schema":"sdd.strategy-comparison-report","version":1,"reply_source":"authored_offline","scope":"terrain-bound faction simulation; no company play or wall-time transport","cases":rows}
	var file := FileAccess.open(directory+"/campaigns.json",FileAccess.WRITE)
	if file==null: fail("Cannot write comparison results.");return
	file.store_string(JSON.stringify(report,"\t",true,true)+"\n");file.close()
	file=FileAccess.open(directory+"/RESULTS.md",FileAccess.WRITE)
	if file==null: fail("Cannot write comparison table.");return
	file.store_string(Bench.table(rows));file.close()
	print("strategy_comparison: %d matched cases PASS; no transport / no player files" % rows.size());quit(0)

func fail(reason: String) -> void:
	push_error(reason);quit(1)

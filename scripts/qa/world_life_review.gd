extends SceneTree
const F := preload("res://scripts/domain/life_campaign.gd")
func save_json(path: String, data: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t",true,true)+"\n");file.close()
func _initialize() -> void:
	if "--export-only" in OS.get_cmdline_user_args():
		save_json("res://resources/data/autonomous_campaigns/marches_2087.json",F.initial(2087,"marches",2));quit(0);return
	var results: Array=[]
	for version: int in [2,3]:
		for seed_value: int in [42,2087,170717]:
			var s := F.initial(seed_value,"marches",version)
			if s.is_empty(): push_error("Invalid review opening.");quit(1);return
			if version==2 and seed_value==2087: save_json("res://resources/data/autonomous_campaigns/marches_2087.json",s)
			for day in range(1,91):
				var result := F.apply(s,F.R.command(s,"advance",{"ticks":96}))
				if not result.ok: push_error("Review day%d: %s" % [day,result.reason]);quit(1);return
				s=result.state
				if day not in [30,90]: continue
				var phases := {};var choices := 0
				for e: Dictionary in s.life.episodes.values():
					phases[e.phase]=int(phases.get(e.phase,0))+1
					if e.contract.get("status")=="offered": choices+=1
				var report := {"geography_version":version,"seed":seed_value,"days":day,"valid":F.valid(s),"stats":s.life.stats.duplicate(true),"episodes":s.life.episodes.size(),"phases":phases,"open_commissions":choices,"migrations":s.life.regions.migrations.size(),"migration_reserve":s.life.regions.reserve.duplicate(true),"convoy_raids":s.life.regions.raids,"wars":s.strategy_world.metrics.wars,"outpost_campaigns":s.life.politics.campaigns.size(),"captures":s.life.politics.captures,"old_mine":s.mine.status,"state_sha256":JSON.stringify(s,"",true,true).sha256_text()}
				results.append(report)
				report.dispute=s.life.politics.dispute.duplicate(true)
				print("WORLD_LIFE_REVIEW ",JSON.stringify(report))
				save_json("res://artifacts/qa-runs/world-life-review/g%d_%d_day%d.json" % [version,seed_value,day],s)
	save_json("res://artifacts/qa-runs/world-life-review/summary.json",{"headless":true,"physical":"NOT_RUN","provider":"none","company_orders":0,"results":results})
	quit(0)

extends SceneTree
## Boundary fixtures, not an ordinary-victory or physical play receipt.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames() -> void:
	for i in range(4): await process_frame

func _run() -> void:
	var campaign:=root.get_node("CampaignSession")
	var session:=root.get_node("DungeonRunSession")
	for managed in [true,false]:
		campaign.load_profile("",true)
		# Explicit location fixture isolates preparation from travel simulation.
		campaign.state.world.location_id="dungeon_old_mine"
		session.clear();session.town_preparation=managed
		var hud=load("res://scenes/dungeon/DungeonDebug.tscn").instantiate()
		root.add_child(hud);await frames()
		var before: Dictionary=campaign.state.duplicate(true)
		for change: Callable in [
			func() -> void: hud._set_dungeon_source(hud.DUNGEON_SOURCE_AUTHORED),
			func() -> void: hud._set_dungeon_source(hud.DUNGEON_SOURCE_GENERATED),
			func() -> void: hud._reroll_generated_dungeon(),
			func() -> void: hud._set_generated_difficulty(1),
			func() -> void: hud._set_generated_difficulty(3),
		]:
			change.call();await frames()
			check(session.town_preparation==managed,"source/reroll/difficulty preserves preparation origin "+str(managed))
			check(campaign.state==before and not session.managed_run and not hud.expedition_started,"preview changes never charge or create a run")
		hud._set_dungeon_source(hud.DUNGEON_SOURCE_AUTHORED);await frames()
		if managed:
			# Failure must retain the same owned preparation; no sandbox fallback.
			var stock: int=campaign.state.supplies.lamp_oil
			campaign.state.supplies.lamp_oil=0
			var poor: Dictionary=campaign.state.duplicate(true)
			hud._start_expedition_with_loadout();await frames()
			check(session.town_preparation and not session.managed_run and not hud.expedition_started and campaign.state==poor,"insufficient owned stock rejects without losing preparation")
			campaign.state.supplies.lamp_oil=stock
		var loadout: Dictionary=hud.selected_supply_loadout.duplicate(true)
		hud._start_expedition_with_loadout();await frames()
		check(hud.expedition_started and session.managed_run==managed,"Start retains intended managed/sandbox mode")
		if managed:
			check(not campaign.state.active_run.is_empty() and not session.town_preparation,"successful owned Start creates receipt and leaves preparation")
			for supply: String in loadout:
				check(int(campaign.state.supplies[supply])==int(before.supplies[supply])-int(loadout[supply]),"exactly-once owned packing "+supply)
			check(campaign.state.active_run.equipment_snapshot==before.equipment,"managed start retains equipped weapons")
		else:
			check(campaign.state==before and campaign.state.active_run.is_empty(),"standalone Start cannot charge campaign")
		hud.queue_free();await frames();session.clear()
	for failure in failures: push_error(failure)
	print("dungeon_preparation_context_tests: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

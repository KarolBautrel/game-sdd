extends SceneTree
const Campaign := preload("res://scripts/session/campaign_session.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const Items := preload("res://scripts/domain/item_catalog.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Dungeon := preload("res://scripts/domain/dungeon_state_model.gd")
var errors: Array[String]=[]
var checks:=0
func _initialize() -> void:_run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:errors.append(message)
func write(path: String,data: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
func _run() -> void:
	var campaign:=Campaign.new()
	campaign.load_profile("",true)
	var owned: Array=["leather_boots","steel_boots","leather_cap","closed_helm","weathered_cuirass"]
	campaign.state.items.append_array(owned)
	var before: Dictionary=campaign.state.duplicate(true)
	for id: String in owned:
		var slot: String=Items.item(id).combat_profile.slot
		check(campaign.equip("unit_player_001",slot,id),"five-slot transaction "+id)
		check(not campaign.equip("unit_player_002",slot,id),"owned copy cannot be assigned twice "+id)
		check(campaign.state.items==before.items and campaign.state.effects==before.effects,"cosmetic change preserves ownership/wounds "+id)
	var path:="user://qa-appearance-%s.json" % Time.get_ticks_usec()
	write(path,campaign.state)
	var saved: Dictionary=campaign.state.duplicate(true)
	check(campaign.load_profile(path) and Campaign.same_data(campaign.state,saved),"five slots survive saved reload")
	var legacy:=campaign.state.duplicate(true)
	for loadout: Dictionary in legacy.equipment.values():loadout.erase("boots");loadout.erase("helmet")
	write(path,legacy)
	var bytes:=FileAccess.get_file_as_string(path)
	check(campaign.load_profile(path) and campaign.state.equipment==Gear.normalized(legacy.equipment),"legacy v4 three slots extend without lost equipment")
	check(FileAccess.get_file_as_string(path)==bytes and campaign.state.items==legacy.items,"migration never rewrites/regrants")
	var partial:=legacy.duplicate(true);partial.equipment.unit_player_001.boots=null
	write(path,partial);check(not campaign.load_profile(path),"partial four-slot save rejected")
	partial=legacy.duplicate(true);partial.equipment.unit_player_001.unknown=null
	write(path,partial);check(not campaign.load_profile(path),"unknown slot save rejected")
	for id: String in ["leather_boots","steel_boots","leather_cap","closed_helm"]:
		check(Items.item(id).combat_profile.grants_actions.is_empty() and not Items.item(id).combat_profile.has("armor_reduction"),"cosmetic gear no hidden mechanics "+id)
	campaign.load_profile("",true)
	campaign.state.world.location_id="dungeon_old_mine"
	var dungeon: Dictionary=Selection.dungeon_for_payload(Selection.default_payload())
	check(campaign.begin_run(dungeon,Dungeon.initial_state(dungeon)),"legacy active-run fixture starts")
	legacy=campaign.state.duplicate(true)
	for equipment: Dictionary in [legacy.equipment,legacy.active_run.equipment_snapshot]:
		for loadout: Dictionary in equipment.values():loadout.erase("boots");loadout.erase("helmet")
	write(path,legacy)
	check(campaign.load_profile(path) and campaign.state.active_run.equipment_snapshot==campaign.state.equipment and campaign.state.equipment.unit_player_001.has("helmet"),"legacy active-run matching snapshots extend together")
	legacy.active_run.equipment_snapshot.unit_player_001.armor="patched_leather"
	write(path,legacy)
	check(not campaign.load_profile(path),"mismatched legacy snapshot stays rejected")
	campaign.load_profile("",true);campaign.state.world.seed=1
	check(campaign.travel("dungeon_old_mine") and campaign.choose_road_event("fight"),"legacy road-fight fixture starts")
	legacy=campaign.state.duplicate(true)
	for equipment: Dictionary in [legacy.equipment,legacy.world.pending_event.equipment_snapshot]:
		for loadout: Dictionary in equipment.values():loadout.erase("boots");loadout.erase("helmet")
	write(path,legacy)
	check(campaign.load_profile(path) and campaign.state.world.pending_event.equipment_snapshot==campaign.state.equipment,"legacy pending fight slots extend together")
	var encounter: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/roadside_ambush.json"))
	var equipment:=Gear.defaults();equipment.unit_player_002.main_hand=null;equipment.unit_player_001.main_hand="hero_bow"
	var launched:=Gear.apply(encounter,equipment)
	for unit: Dictionary in launched.units:
		var hero:=Party.hero_for_combat_unit(unit.id)
		if not hero.is_empty():
			var worn: Variant=equipment[unit.id].main_hand
			var expected: Dictionary=Items.item(worn).get("visual",hero.visual) if worn!=null else hero.visual
			check(unit.visual==expected and unit.loadout==equipment[unit.id],"restored weapon sprite and five-slot combat handoff "+str(unit.id))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	campaign.free()
	for error in errors:push_error(error)
	print("Equipment appearance: %s checks, %s failures" % [checks,errors.size()])
	quit(0 if errors.is_empty() else 1)

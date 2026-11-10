extends Node
## Durable town boundary. Mutations publish only after a successful save.

const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const Trade := preload("res://scripts/domain/town_trade.gd")
const Advancement := preload("res://scripts/domain/party_advancement.gd")
const Living := preload("res://scripts/domain/living_world.gd")
const ProfileKind := preload("res://scripts/session/campaign_profile_kind.gd")
const PRICES := {"lamp_oil": 2, "pickaxe": 4, "trap_tools": 3, "bandage": 2, "camping_kit": 5, "food": 1}
const SUPPLY_NAMES := {"lamp_oil": "Torch oil", "pickaxe": "Pickaxe", "trap_tools": "Trap tools", "bandage": "Bandage", "camping_kit": "Camping kit", "food": "Food"}
var state: Dictionary = {}
var loaded := false
var save_path := "user://campaign_v1.json"
var memory_only := false
var last_feedback := ""
var requested_campaign_tab := ""
var living_motion: Dictionary={}


static func initial_profile() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/campaign/new_game.json"))
	return data if data is Dictionary else {}


func load_profile(path: String = "user://campaign_v1.json", in_memory: bool = false) -> bool:
	living_motion={}
	save_path = path
	memory_only = in_memory
	loaded = false
	if path.begins_with(ProfileKind.STRATEGY_PREFIX):
		return _reject("Strategy profiles require the dedicated strategy session.")
	if in_memory or not FileAccess.file_exists(path):
		state = initial_profile()
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return _reject("Cannot read campaign save.")
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			return _reject("Campaign save is invalid or unsupported. Existing file preserved.")
		var parsed: Variant = json.data
		if ProfileKind.classify(parsed) == "strategy":
			return _reject("Strategy profiles require the dedicated strategy session.")
		if not parsed is Dictionary or not _valid_profile(parsed):
			return _reject("Campaign save is invalid or unsupported. Existing file preserved.")
		state = parsed
		if int(state.version) < 3:
			state = state.duplicate(true)
			if int(state.version) == 1:
				state.world = initial_profile().world.duplicate(true)
			state.equipment = Gear.defaults()
			for id: String in ["hero_sword", "hero_bow"]:
				if state.items.count(id) < Gear.assigned(state.equipment, id):
					state.items.append(id)
			if not state.active_run.is_empty():
				state.active_run.equipment_snapshot = state.equipment.duplicate(true)
			if not state.world.pending_event.is_empty() and state.world.pending_event.phase == "combat":
				state.world.pending_event.equipment_snapshot = state.equipment.duplicate(true)
			state.version = 3
		if int(state.version) < 4:
			state = state.duplicate(true)
			state.advancement = Advancement.defaults()
			if not state.active_run.is_empty():
				state.active_run.advancement_snapshot = state.advancement.duplicate(true)
			if not state.world.pending_event.is_empty() and state.world.pending_event.phase == "combat":
				state.world.pending_event.advancement_snapshot = state.advancement.duplicate(true)
			state.version = 4
	# Validate the raw legacy snapshot first, then extend matching slots in memory.
	state.equipment=Gear.normalized(state.equipment)
	if not state.active_run.is_empty():state.active_run.equipment_snapshot=Gear.normalized(state.active_run.equipment_snapshot)
	if not state.world.pending_event.is_empty() and state.world.pending_event.phase=="combat":
		state.world.pending_event.equipment_snapshot=Gear.normalized(state.world.pending_event.equipment_snapshot)
	loaded = true
	last_feedback = "Campaign ready."
	return true


func living_active() -> bool:
	return loaded and state.has("living_world")


func enable_living_world() -> bool:
	if not loaded or living_active() or not state.active_run.is_empty() or not state.world.pending_event.is_empty() or (not memory_only and not save_path.begins_with("user://qa_living_world_")):
		return _reject("Living-world initialization requires its separate pilot profile.")
	var next:=state.duplicate(true)
	next.living_world=Living.initial(int(next.world.seed),int(next.world.elapsed_hours))
	next.world.location_id="town_ravenford"
	next.gold=80
	next.supplies.food=16
	return _commit(next,"Living Marches: a new mercenary company in Ravenford.")


func living_course(destination: Vector2,goal: String = "") -> bool:
	if not _living_available(): return _reject("Resolve the expedition or road event before travelling.")
	var next:=state.duplicate(true)
	if not Living.course(next,destination,goal): return _reject("No accessible route. Water and high peaks are blocked; use bridges, fords or a mountain pass.")
	return _commit(next,"Course set. Pause or change direction at any time.")

func enable_generated_region(seed_value: int,preset: String="marches",version: int=1) -> bool:
	if not loaded or living_active() or not state.active_run.is_empty() or not state.world.pending_event.is_empty() or (not memory_only and not save_path.begins_with("user://qa_living_world_generated_v%d_" % version)):
		return _reject("Generated regions require their separate new/resumable pilot profile.")
	var geography:=Living.Generator.generate(seed_value,preset,version)
	if geography.is_empty(): return _reject(Living.Generator.last_error)
	var next:=state.duplicate(true)
	next.world.seed=seed_value;next.world.location_id="town_ravenford"
	next.living_world=Living.initial(seed_value,int(next.world.elapsed_hours),geography)
	next.gold=80;next.supplies.food=16
	return _commit(next,"Company established in "+str(geography.name)+".")


func advance_living(ticks: int = 1) -> bool:
	if not _living_available() or ticks<1 or ticks>192: return _reject("Strategic time is paused while an expedition or road event is active.")
	var next:=state.duplicate(true)
	var motion: Dictionary={}
	var contact:=Living.advance(next,ticks,false,motion)
	if contact:
		next.world.journey_count=int(next.world.journey_count)+1
		next.world.pending_event=Travel.pending_for(next.world,{"to":next.world.location_id,"danger":1.0})
	if not _commit(next,"Raider contact. Resolve the encounter to continue." if contact else last_feedback): return false
	living_motion=motion
	return true


func living_camp(enabled: bool) -> bool:
	if not _living_available(): return _reject("Camping is unavailable during an expedition or road event.")
	var next:=state.duplicate(true)
	next.living_world.party.path=[]
	next.living_world.party.goal=""
	next.living_world.party.camping=enabled
	return _commit(next,"Camp established. Time and upkeep continue while resting." if enabled else "Camp packed.")


func accept_living_contract(id: String) -> bool:
	var reason := str(living_contract_availability(id).accept_reason)
	if not reason.is_empty(): return _reject(reason)
	var next:=state.duplicate(true)
	if not Living.accept(next,id): return _reject(str(living_contract_availability(id).accept_reason))
	return _commit(next,"Accepted "+str(Living.contract(id).name)+".")


func report_living_contract(id: String) -> bool:
	var reason := str(living_contract_availability(id).report_reason)
	if not reason.is_empty(): return _reject(reason)
	var next:=state.duplicate(true)
	if not Living.report(next,id): return _reject(str(living_contract_availability(id).report_reason))
	return _commit(next,"Contract paid: "+str(Living.contract(id).name)+".")

func living_contract_availability(id: String) -> Dictionary:
	return Living.contract_availability(state if living_active() else {},id)


func _living_available() -> bool:
	return living_active() and state.active_run.is_empty() and state.world.pending_event.is_empty()


func supply_price(id: String) -> int:
	return Living.food_price(state.living_world) if id=="food" and living_active() else int(PRICES.get(id,0))


func purchase(supply_id: String) -> bool:
	if not loaded or not PRICES.has(supply_id) or not state.active_run.is_empty() or not at_town():
		return _reject("Purchase unavailable.")
	var cost: int = supply_price(supply_id)
	if int(state.gold) < cost:
		return _reject("Not enough gold.")
	var next := state.duplicate(true)
	next.gold = int(next.gold) - cost
	next.supplies[supply_id] = int(next.supplies[supply_id]) + 1
	return _commit(next, "Bought %s for %sg." % [SUPPLY_NAMES[supply_id], cost])


func recover() -> bool:
	if not loaded or not state.active_run.is_empty() or int(state.gold) < 5 or not at_town():
		return _reject("Inn recovery unavailable (5g, no active expedition).")
	var next := state.duplicate(true)
	next.gold = int(next.gold) - 5
	next.effects = initial_profile().effects
	if living_active(): next.living_world.party.fatigue=0
	return _commit(next, "Party recovered at the inn (5g).")


func can_trade() -> bool:
	return loaded and state.active_run.is_empty() and at_town() and state.world.location_id == Trade.catalogue().get("town_id", "")


func purchase_item(item_id: String) -> bool:
	if not can_trade():
		return _reject("Trading requires Ravenford with no active expedition or road event.")
	var offer := Trade.buy_offer(item_id)
	if offer.is_empty():
		return _reject("That item is not offered here.")
	var price := int(offer.buy_price)
	if int(state.gold) < price:
		return _reject("Not enough gold (%sg required)." % price)
	var next := state.duplicate(true)
	next.gold = int(next.gold) - price
	next.items.append(item_id)
	return _commit(next, "Bought %s for %sg. Equip it from your stash." % [offer.name, price])


func sell_item(item_id: String) -> bool:
	if not can_trade():
		return _reject("Trading requires Ravenford with no active expedition or road event.")
	var quote := Trade.sale(item_id, state.items, state.equipment)
	if quote.is_empty():
		return _reject("No unassigned copy to sell. Quest and legacy items are kept.")
	var next := state.duplicate(true)
	next.items.erase(item_id)
	next.gold = int(next.gold) + int(quote.value)
	return _commit(next, "Sold one %s for %sg." % [quote.name, int(quote.value)])


func begin_run(data: Dictionary, run_state: Dictionary) -> bool:
	if not loaded or not state.active_run.is_empty() or data.get("rooms", []).is_empty() or state.world.location_id != "dungeon_old_mine" or not state.world.pending_event.is_empty():
		return _reject("An expedition is already active or campaign is unavailable.")
	if living_active() and (not Living.at_site(state.living_world,"dungeon_old_mine") or (data.get("id","")!="dungeon_old_mine" and data.get("generated_profile",{}).get("theme","")!="mine")):
		return _reject("Travel to the Old Mine before preparing its expedition.")
	if living_active() and state.living_world.mine.status=="cleared": return _reject("The restored mine stays cleared. Seek another contract.")
	var loadout: Dictionary = run_state.get("selected_supply_loadout", {})
	if loadout.is_empty() or Model.clamp_supply_loadout(data, loadout) != loadout:
		return _reject("Invalid expedition loadout.")
	if int(state.supplies.food) - int(loadout.get("food", 0)) < Travel.return_food(Travel.region(), state.world.location_id):
		return _reject("Keep food in the stash for the return journey.")
	for key in loadout:
		if not PRICES.has(key) or not _count(loadout[key]) or int(loadout[key]) > int(state.supplies[key]):
			return _reject("Not enough owned supplies: %s. Buy them in Ravenford." % key)
	var next := state.duplicate(true)
	for key in loadout:
		next.supplies[key] = int(next.supplies[key]) - int(loadout[key])
	var carried := run_state.duplicate(true)
	for key in ["party_effects", "target_effects", "active_debuffs"]:
		carried[key] = state.effects.get(key, {}).duplicate(true)
	next.active_run = {"id": Crypto.new().generate_random_bytes(16).hex_encode(),
		"data": data.duplicate(true), "state": carried, "combat_seed": 0,
		"equipment_snapshot": state.equipment.duplicate(true),
		"advancement_snapshot": state.advancement.duplicate(true)}
	if living_active():
		next.active_run.living_site="dungeon_old_mine"
		next.active_run.living_room_count=carried.get("visited_room_ids",[]).size()
		next.active_run.living_camp_count=carried.get("camp_log",[]).size()
	return _commit(next, "Expedition packed from owned supplies.")


func checkpoint(data: Dictionary, run_state: Dictionary, combat_seed: int = 0) -> bool:
	if not loaded or state.active_run.is_empty() or str(data.get("id", "")) != str(state.active_run.data.get("id", "")):
		return _reject("No matching active expedition.")
	var next := state.duplicate(true)
	if living_active():
		var rooms: int=run_state.get("visited_room_ids",[]).size()
		var camps: int=run_state.get("camp_log",[]).size()
		var ticks:=maxi(0,rooms-int(next.active_run.get("living_room_count",rooms)))+16*maxi(0,camps-int(next.active_run.get("living_camp_count",camps)))
		if ticks>1000: return _reject("Invalid expedition time checkpoint.")
		Living.advance(next,ticks,true)
		next.active_run.living_room_count=maxi(rooms,int(next.active_run.get("living_room_count",rooms)))
		next.active_run.living_camp_count=maxi(camps,int(next.active_run.get("living_camp_count",camps)))
	next.active_run.data = data.duplicate(true)
	next.active_run.state = run_state.duplicate(true)
	next.active_run.combat_seed = combat_seed
	return _commit(next, "Expedition checkpoint saved.")


func settle(payload: Dictionary) -> bool:
	if not loaded:
		return _reject("Campaign unavailable.")
	var receipt := str(payload.get("run_id", ""))
	if receipt == "" or state.receipts.has(receipt):
		return _reject("Return receipt missing or already processed.")
	var active: Dictionary = state.active_run
	if active.is_empty() or receipt != str(active.id):
		return _reject("Return receipt does not match active expedition.")
	var run_state: Dictionary = active.state
	var outcome := str(payload.get("outcome", ""))
	if not bool(run_state.get("completed", false)) or outcome not in ["completed", "retreated", "failed"] or outcome != str(run_state.get("run_outcome", "")):
		return _reject("Expedition is not finished.")
	var expected := Model.run_result_payload(active.data, run_state, outcome)
	var supplied := payload.duplicate(true)
	supplied.erase("run_id")
	if not same_data(supplied, expected):
		return _reject("Return payload differs from saved domain result.")
	var delta: Dictionary = expected.inventory_delta
	if not _count(delta.get("gold")) or not _count(delta.get("xp")) or not _string_array(delta.get("items")):
		return _reject("Invalid inventory delta.")
	var next := state.duplicate(true)
	next.gold = int(next.gold) + int(delta.gold)
	next.xp = int(next.xp) + int(delta.xp)
	next.items.append_array(delta.items.duplicate())
	next.effects = expected.persistent_effects.duplicate(true)
	var remaining: Dictionary = run_state.get("supplies", {})
	for key in PRICES:
		if not _count(remaining.get(key, 0)):
			return _reject("Invalid remaining supplies.")
		next.supplies[key] = int(next.supplies[key]) + int(remaining.get(key, 0))
	next.receipts.append(receipt)
	next.last_return = {"outcome": outcome, "gold": delta.gold, "xp": delta.xp, "items": delta.items.duplicate()}
	if living_active(): Living.expedition_result(next,active,outcome)
	next.active_run = {}
	return _commit(next, "Expedition settled: %s, +%sg, +%s XP." % [outcome, delta.gold, delta.xp])


func at_town() -> bool:
	if living_active(): return Living.at_town(state.living_world) and state.world.pending_event.is_empty()
	return loaded and Travel.node(Travel.region(), str(state.world.location_id)).get("type", "") == "town" and state.world.pending_event.is_empty()


func travel(destination: String) -> bool:
	if living_active(): return _reject("Use the continuous living map to travel.")
	if not loaded or not state.active_run.is_empty() or not state.world.pending_event.is_empty():
		return _reject("Travel unavailable while an expedition/event is active.")
	var quote := Travel.quote(state.world, destination)
	if quote.is_empty():
		return _reject("No road to that destination.")
	if int(state.supplies.food) < int(quote.food) + int(quote.return_food):
		return _reject("Not enough food for the trip and return reserve.")
	var next := state.duplicate(true)
	next.supplies.food = int(next.supplies.food) - int(quote.food)
	next.world.location_id = destination
	next.world.elapsed_hours = int(next.world.elapsed_hours) + int(quote.time_hours)
	next.world.journey_count = int(next.world.journey_count) + 1
	next.world.last_journey = quote.duplicate(true)
	next.world.last_journey.id = next.world.journey_count
	next.world.pending_event = Travel.pending_for(next.world, quote)
	return _commit(next, "Arrived at %s. %sh, %s food." % [Travel.node_name(destination), quote.time_hours, quote.food])


func choose_road_event(choice: String) -> bool:
	if not loaded or state.world.pending_event.is_empty() or not state.active_run.is_empty():
		return _reject("No road event to resolve.")
	var pending: Dictionary = state.world.pending_event
	if pending.phase != "choice":
		return _reject("Resume the pending ambush.")
	var definitions := Travel.event_definitions()
	var next := state.duplicate(true)
	if pending.kind == "ambush":
		if choice == "fight":
			next.world.pending_event.phase = "combat"
			next.world.pending_event.equipment_snapshot = state.equipment.duplicate(true)
			next.world.pending_event.advancement_snapshot = state.advancement.duplicate(true)
			return _commit(next, "Ambush ready. Resume combat from encounter entry.")
		if choice != "pay" or int(state.gold) < int(definitions.ambush.toll_gold):
			return _reject("Cannot pay the toll or unknown choice.")
		next.gold = int(next.gold) - int(definitions.ambush.toll_gold)
	else:
		var selected: Dictionary = {}
		for entry: Dictionary in definitions.cart.choices:
			if entry.id == choice:
				selected = entry
		if selected.is_empty() or int(state.gold) < int(selected.gold_cost):
			return _reject("Road event choice unavailable.")
		next.gold = int(next.gold) - int(selected.gold_cost)
		next.world.elapsed_hours = int(next.world.elapsed_hours) + int(selected.time_hours)
		_add_rewards(next, selected.rewards)
		next.world.resolved_nodes.append(pending.node_id)
	next.world.last_journey.event_result = choice
	next.world.pending_event = {}
	return _commit(next, "Road event resolved.")


func finish_road_combat(payload: Dictionary) -> bool:
	if not loaded or state.world.pending_event.is_empty() or not state.active_run.is_empty():
		return _reject("No matching ambush.")
	var pending: Dictionary = state.world.pending_event
	if pending.kind != "ambush" or pending.phase != "combat" or not _valid_road_result(payload, pending):
		return _reject("Invalid ambush result.")
	var next := state.duplicate(true)
	next.effects = Model.returned_party_effects(state.effects, payload)
	if payload.result == "victory":
		_add_rewards(next, Travel.event_definitions().ambush.victory_rewards)
	next.world.last_journey.event_result = payload.result
	next.world.pending_event = {}
	return _commit(next, "Ambush %s. Party and loot saved." % payload.result)


func equip(hero_id: String, slot: String, item_id: Variant) -> bool:
	if not loaded or not state.active_run.is_empty() or not state.world.pending_event.is_empty():
		return _reject("Equipment locked until the expedition or road event is resolved.")
	if not state.equipment.has(hero_id) or slot not in Gear.SLOTS or (item_id != null and not item_id is String):
		return _reject("Unknown hero, slot or item.")
	var next := state.duplicate(true)
	next.equipment[hero_id][slot] = item_id
	if not Gear.valid(next.equipment, next.items):
		return _reject("Cannot equip: check owned copies, slot and two-handed/off-hand conflict. Unequip the conflicting item first.")
	return _commit(next, "Equipment saved.")


func available_xp() -> int:
	return int(state.xp) - Advancement.allocated(state.advancement) if loaded else 0


func train(hero_id: String) -> bool:
	if not can_trade() or not state.advancement.has(hero_id):
		return _reject("Training requires Ravenford, a known hero and no active expedition or road event.")
	var tier := Advancement.next_tier(state.advancement, hero_id)
	if tier.is_empty():
		return _reject("This hero has reached the current training cap.")
	if available_xp() < int(tier.cost):
		return _reject("Not enough available XP (%s required)." % int(tier.cost))
	var next := state.duplicate(true)
	next.advancement[hero_id] = int(tier.level)
	return _commit(next, "%s advanced to level %s (%s XP allocated)." % [Party.display_name_for_combat_unit(hero_id), int(tier.level), int(tier.cost)])


static func _add_rewards(next: Dictionary, rewards: Dictionary) -> void:
	next.gold = int(next.gold) + int(rewards.gold)
	next.xp = int(next.xp) + int(rewards.xp)
	next.items.append_array(rewards.items)


static func _valid_road_result(payload: Dictionary, pending: Dictionary) -> bool:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(Travel.event_definitions().ambush.encounter_path))
	if not source is Dictionary or payload.get("result") not in ["victory", "defeat"] or payload.get("combat_id") != source.get("id") or payload.get("source_dungeon_id") != "road_region_001" or payload.get("source_room_id") != pending.id:
		return false
	for key in ["surviving_players", "remaining_enemies", "defeated_player_ids", "defeated_enemy_ids"]:
		if not payload.get(key) is Array:
			return false
	var heroes: Dictionary = {}
	for hero: Dictionary in Party.default_party():
		heroes[hero.combat_unit_id] = int(hero.stats.max_hp)
	var enemies: Dictionary = {}
	for unit: Dictionary in source.get("units", []):
		if unit.get("team") == "enemy":
			enemies[unit.id] = int(unit.stats.max_hp)
	for spec in [["surviving_players", "defeated_player_ids", heroes], ["remaining_enemies", "defeated_enemy_ids", enemies]]:
		var seen: Dictionary = {}
		for row in payload[spec[0]]:
			if not row is Dictionary or not spec[2].has(row.get("id")) or seen.has(row.id) or not _count(row.get("hp")) or int(row.hp) < 1 or int(row.hp) > int(spec[2][row.id]) or row.get("max_hp") != spec[2][row.id]:
				return false
			seen[row.id] = true
		for id in payload[spec[1]]:
			if not id is String or not spec[2].has(id) or seen.has(id):
				return false
			seen[id] = true
		if seen.size() != spec[2].size():
			return false
	return (payload.result == "victory" and payload.remaining_enemies.is_empty() and not payload.surviving_players.is_empty()) or (payload.result == "defeat" and payload.surviving_players.is_empty() and not payload.remaining_enemies.is_empty())


func _commit(next: Dictionary, message: String) -> bool:
	if not _valid_profile(next):
		return _reject("Invalid campaign transaction.")
	if not memory_only:
		var temporary := save_path + ".tmp"
		var file := FileAccess.open(temporary, FileAccess.WRITE)
		if file == null:
			return _reject("Cannot write campaign save; transaction cancelled.")
		file.store_string(JSON.stringify(next, "\t", true, true) + "\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(save_path)) != OK:
			return _reject("Cannot replace campaign save; transaction cancelled.")
	state = next
	last_feedback = message
	return true


func _reject(message: String) -> bool:
	last_feedback = message
	return false


static func _count(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= 0 and float(value) <= 1000000000


static func same_data(left: Variant, right: Variant) -> bool:
	# JSON parses integral numbers as floats; compare values recursively.
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key in left:
			if not right.has(key) or not same_data(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index in range(left.size()):
			if not same_data(left[index], right[index]):
				return false
		return true
	if (left is int or left is float) and (right is int or right is float):
		return left == right
	return typeof(left) == typeof(right) and left == right


static func _string_array(value: Variant) -> bool:
	if not value is Array:
		return false
	for item in value:
		if not item is String:
			return false
	return true


static func _valid_profile(value: Dictionary) -> bool:
	if not _count(value.get("version")) or int(value.version) not in [1, 2, 3, 4] or not _count(value.get("gold")) or not _count(value.get("xp")) or not _string_array(value.get("items")) or not _string_array(value.get("receipts")):
		return false
	if int(value.version) >= 2 and not Travel.valid(value.get("world")):
		return false
	if value.has("living_world"):
		if not value.get("active_run") is Dictionary: return false
		if int(value.version)!=4 or not Living.valid(value.living_world) or int(value.world.elapsed_hours)!=int(value.living_world.tick)/4: return false
		if not value.get("active_run",{}).is_empty():
			var active: Dictionary=value.active_run
			if active.get("living_site")!="dungeon_old_mine" or not _count(active.get("living_room_count")) or not _count(active.get("living_camp_count")): return false
			if not active.get("state") is Dictionary or not active.state.get("visited_room_ids") is Array or not active.state.get("camp_log") is Array: return false
			if int(active.living_room_count)>active.state.visited_room_ids.size() or int(active.living_camp_count)>active.state.camp_log.size(): return false
	if int(value.version) >= 2 and value.get("active_run") is Dictionary and not value.active_run.is_empty() and not value.world.pending_event.is_empty():
		return false
	for key in ["supplies", "effects", "active_run", "last_return"]:
		if not value.get(key) is Dictionary:
			return false
	if int(value.version) >= 3:
		if not Gear.valid(value.get("equipment"), value.items):
			return false
		if not value.active_run.is_empty() and not same_data(value.active_run.get("equipment_snapshot"), value.equipment):
			return false
		if not value.world.pending_event.is_empty() and value.world.pending_event.phase == "combat" and not same_data(value.world.pending_event.get("equipment_snapshot"), value.equipment):
			return false
	if int(value.version) == 4:
		if not Advancement.valid(value.get("advancement"), int(value.xp)):
			return false
		if not value.active_run.is_empty() and not same_data(value.active_run.get("advancement_snapshot"), value.advancement):
			return false
		if not value.world.pending_event.is_empty() and value.world.pending_event.phase == "combat" and not same_data(value.world.pending_event.get("advancement_snapshot"), value.advancement):
			return false
	for key in PRICES:
		if not _count(value.supplies.get(key)):
			return false
	for key in ["party_effects", "target_effects", "active_debuffs"]:
		if not value.effects.get(key) is Dictionary:
			return false
	if not _valid_effects(value.effects):
		return false
	if not value.active_run.is_empty():
		var active: Dictionary = value.active_run
		if not active.get("id") is String or str(active.id) == "" or not active.get("data") is Dictionary or not active.get("state") is Dictionary or not _count(active.get("combat_seed")):
			return false
		if not active.data.get("rooms") is Array or active.data.rooms.is_empty() or not active.state.get("supplies") is Dictionary or not active.state.get("party_formation") is Array:
			return false
		if not _valid_effects(active.state):
			return false
		for key in PRICES:
			if not _count(active.state.supplies.get(key)):
				return false
	return true


static func _valid_effects(value: Dictionary) -> bool:
	for key in ["party_effects", "target_effects", "active_debuffs"]:
		if not value.get(key) is Dictionary:
			return false
	if not _count(value.party_effects.get("hp_loss", 0)) or not _string_array(value.party_effects.get("debuffs", [])):
		return false
	for key in value.target_effects:
		var effect: Variant = value.target_effects[key]
		if not effect is Dictionary or not _count(effect.get("hp_loss", 0)) or not effect.get("debuffs", {}) is Dictionary:
			return false
		if effect.has("incapacitated") and not effect.incapacitated is bool:
			return false
		for debuff in effect.get("debuffs", {}):
			if not _count(effect.debuffs[debuff]):
				return false
	for key in value.active_debuffs:
		var effect: Variant = value.active_debuffs[key]
		if not effect is Dictionary or not _count(effect.get("stacks", 0)) or not _string_array(effect.get("targets", [])):
			return false
	return true

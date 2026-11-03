extends SceneTree

const Campaign := preload("res://scripts/session/campaign_session.gd")
const Trade := preload("res://scripts/domain/town_trade.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const BRAN := "unit_player_001"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _run() -> void:
	check(Trade.validation_errors(Trade.catalogue()).is_empty(), "canonical offers")
	for price in [-1, 0, 1.5, 5, true, 1000000001]:
		var bad := Trade.catalogue()
		bad.offers[0].buy_price = price
		check(not Trade.validation_errors(bad).is_empty(), "invalid/no-profit price rejected: %s" % str(price))
	var bad := Trade.catalogue()
	bad.offers.append(bad.offers[0].duplicate(true))
	check(not Trade.validation_errors(bad).is_empty(), "duplicate offer rejected")
	bad = Trade.catalogue()
	bad.offers[0].item_id = "rusty_key"
	check(not Trade.validation_errors(bad).is_empty(), "quest offer rejected")
	var path := "user://qa-trade-%s.json" % Time.get_ticks_usec()
	var campaign := Campaign.new()
	check(campaign.load_profile(path) and campaign.can_trade(), "new town trade")
	campaign.state.items.append_array(["generated_old_mine_trinket", "generated_old_mine_trinket", "rusty_key", "legacy_relic"])
	campaign.state.effects.target_effects = {"party_slot_front":{"hp_loss":3,"debuffs":{}}}
	var before := campaign.state.duplicate(true)
	check(campaign.purchase_item("salvaged_blade"), "buy blade")
	check(campaign.state.gold == 24 and campaign.state.items == before.items + ["salvaged_blade"] and campaign.state.equipment == before.equipment and campaign.state.effects == before.effects and campaign.state.supplies == before.supplies and campaign.state.xp == before.xp, "exact purchase, no unrelated mutation")
	check(campaign.sell_item("salvaged_blade") and campaign.state.gold == 31 and campaign.state.items == before.items, "exact sale/no buy-sell profit")
	check(campaign.sell_item("generated_old_mine_trinket") and campaign.state.gold == 34 and campaign.state.items.count("generated_old_mine_trinket") == 1, "sell single stack copy")
	before = campaign.state.duplicate(true)
	for id in ["rusty_key", "legacy_relic", "missing", "hero_sword", "hero_bow"]:
		check(not campaign.sell_item(id) and campaign.state == before, "untradeable/assigned sale atomic: " + id)
	check(not campaign.purchase_item("rusty_key") and not campaign.purchase_item("missing") and campaign.state == before, "unlisted purchase atomic")
	check(campaign.purchase_item("hero_sword") and campaign.state.items.count("hero_sword") == 2, "buy spare equipped item")
	var equipment: Dictionary = campaign.state.equipment.duplicate(true)
	check(campaign.sell_item("hero_sword") and campaign.state.items.count("hero_sword") == 1 and campaign.state.equipment == equipment, "sell spare, preserve assigned copy")
	before = campaign.state.duplicate(true)
	check(not campaign.sell_item("hero_sword") and campaign.state == before, "cannot sell final assigned copy")
	check(campaign.equip(BRAN,"main_hand",null) and campaign.sell_item("hero_sword") and not campaign.state.items.has("hero_sword"), "explicit unequip allows final sale")
	check(campaign.load_profile(path) and not campaign.state.items.has("hero_sword") and campaign.state.equipment[BRAN].main_hand == null, "restart never regrants sold v3 starter")
	before = campaign.state.duplicate(true)
	var bytes := FileAccess.get_file_as_string(path)
	campaign.save_path = "user://qa-missing-trade-%s/save.json" % Time.get_ticks_usec()
	check(not campaign.purchase_item("patched_leather") and not campaign.sell_item("generated_old_mine_trinket") and campaign.state == before and FileAccess.get_file_as_string(path) == bytes, "failed buy and sell leave state/file unchanged")
	campaign.save_path = path
	campaign.state.gold = 0
	before = campaign.state.duplicate(true)
	check(not campaign.purchase_item("hero_sword") and campaign.state == before, "insufficient gold atomic")
	campaign.state.gold = 1000000000
	before = campaign.state.duplicate(true)
	check(not campaign.sell_item("generated_old_mine_trinket") and campaign.state == before, "gold cap rejection never consumes loot")
	campaign.state.gold = 0
	check(campaign.sell_item("generated_old_mine_trinket") and campaign.state.gold == 3, "sell final free valuable")
	before = campaign.state.duplicate(true)
	check(not campaign.sell_item("generated_old_mine_trinket") and campaign.state == before, "stale repeat sale rejected")
	campaign.load_profile("",true)
	check(campaign.travel("dungeon_old_mine"), "remote arrival")
	before = campaign.state.duplicate(true)
	check(not campaign.can_trade() and not campaign.purchase_item("hero_sword") and not campaign.sell_item("hero_sword") and campaign.state == before, "remote service gate")
	var data := Selection.dungeon_for_payload(Selection.default_payload())
	check(campaign.begin_run(data,Model.initial_state(data)), "active expedition fixture")
	# Legacy active runs can still be located in town; exercise the independent active gate.
	campaign.state.world.location_id = "town_ravenford"
	before = campaign.state.duplicate(true)
	check(not campaign.can_trade() and not campaign.purchase_item("patched_leather") and not campaign.sell_item("hero_sword") and campaign.state == before, "active gate even at town")
	campaign.load_profile("",true)
	campaign.travel("event_broken_cart")
	campaign.choose_road_event("help")
	# Find a deterministic dangerous return, then use the real travel transaction.
	for seed in range(1,101):
		var projected: Dictionary = campaign.state.world.duplicate(true)
		projected.seed = seed
		projected.journey_count += 1
		projected.location_id = "town_ravenford"
		if not Travel.pending_for(projected,Travel.quote(campaign.state.world,"town_ravenford")).is_empty():
			campaign.state.world.seed = seed
			break
	check(campaign.travel("town_ravenford") and not campaign.state.world.pending_event.is_empty(), "pending town ambush fixture")
	before = campaign.state.duplicate(true)
	check(not campaign.can_trade() and not campaign.purchase_item("patched_leather") and not campaign.sell_item("hero_sword") and campaign.state == before, "pending event town gate")
	campaign.loaded = false
	check(not campaign.purchase_item("hero_sword") and not campaign.sell_item("hero_sword"), "unloaded gate")
	var singleton := root.get_node("CampaignSession")
	singleton.load_profile("",true)
	singleton.state.items.append_array(["generated_old_mine_trinket","generated_old_mine_trinket"])
	var app: Control = load("res://scenes/town/town_shell.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.action_buttons.has("trade") and not app.action_buttons.trade.disabled, "town exposes Trading Post")
	app.action_buttons.trade.pressed.emit()
	await process_frame
	var view := app.find_child("TradingView",true,false)
	check(view != null and app.trading_view and app.action_buttons.has("close_trade"), "actual open control")
	before = singleton.state.duplicate(true)
	check(view.buy_grid.item_buttons.has("salvaged_blade") and view.sell_grid.item_buttons.has("generated_old_mine_trinket"), "named offer and loot tiles")
	view.buy_grid.item_buttons.salvaged_blade.pressed.emit()
	view.sell_grid.item_buttons.generated_old_mine_trinket.pressed.emit()
	check(singleton.state == before, "selection alone never commits")
	view.buy_button.pressed.emit()
	await process_frame
	view = app.find_child("TradingView",true,false)
	check(singleton.state.gold == 24 and singleton.state.items.count("salvaged_blade") == 1 and view.selected_buy_id() == "salvaged_blade", "actual Buy and retained selection")
	view.sell_button.pressed.emit()
	await process_frame
	view = app.find_child("TradingView",true,false)
	check(singleton.state.gold == 27 and singleton.state.items.count("generated_old_mine_trinket") == 1 and view.selected_sell_id() == "generated_old_mine_trinket", "actual Sell one and retained selection")
	singleton.state.gold = 0
	app._render()
	await process_frame
	view = app.find_child("TradingView",true,false)
	check(view.buy_button.disabled, "insufficient funds reflected in UI")
	app.action_buttons.close_trade.pressed.emit()
	await process_frame
	check(not app.trading_view and app.action_buttons.has("buy_food") and app.action_buttons.has("trade"), "actual Back restores town")
	app.action_buttons.inventory.pressed.emit()
	await process_frame
	view = app.find_child("EquipmentView",true,false)
	var inventory := app.find_child("InventoryView",true,false)
	check(inventory.grid.item_buttons.has("salvaged_blade"), "purchased weapon appears in actual stash")
	inventory.grid.item_buttons.salvaged_blade.pressed.emit()
	view.equip_button.pressed.emit()
	await process_frame
	check(singleton.state.equipment[BRAN].main_hand == "salvaged_blade" and singleton.state.items.count("salvaged_blade") == 1, "purchased gear equips through existing controller")
	app.queue_free()
	await process_frame
	# Empty sell selector: only assigned starters, no protected items offered.
	singleton.load_profile("",true)
	var passive: Control = load("res://scripts/presentation/world/trading_view.gd").new()
	root.add_child(passive)
	passive.configure(singleton.state.items,singleton.state.equipment,40,true)
	check(passive.sell_grid.item_buttons.is_empty() and passive.sell_button.disabled, "no free loot empty state")
	passive.queue_free()
	await process_frame
	campaign.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures:
		push_error(failure)
	print("town_trade_tests: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

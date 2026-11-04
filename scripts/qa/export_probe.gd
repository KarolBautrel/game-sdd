extends Node
## Explicit opt-in probe: export templates disable CLI script/scene overrides.

const Checks := preload("res://scripts/qa/asset_catalog_checks.gd")
const SCENES := [
	"res://scenes/app/App.tscn", "res://scenes/dungeon/DungeonDebug.tscn",
	"res://scenes/town/town_shell.tscn",
	"res://scenes/town/TownExploration.tscn",
	"res://scenes/combat/CombatDebug.tscn", "res://scenes/combat/CombatMapEditor.tscn",
]


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--qa-campaign-review") or OS.get_cmdline_user_args().has("--qa-play-review"):
		get_node("/root/CampaignSession").load_profile("",true)
		_start_native_review.call_deferred()
	elif OS.get_cmdline_user_args().has("--qa-export-smoke"):
		_run.call_deferred()

func _start_native_review() -> void:
	var current := get_tree().current_scene
	if current != null:
		current.queue_free()
		await get_tree().process_frame
	var script: Script = preload("res://scripts/qa/play_render_review.gd") if OS.get_cmdline_user_args().has("--qa-play-review") else preload("res://scripts/qa/campaign_render_review.gd")
	get_tree().root.add_child(script.new())


func _run() -> void:
	var failures := Checks.validate()
	var current := get_tree().current_scene
	if current != null:
		current.queue_free()
		await get_tree().process_frame
	for path: String in SCENES:
		var packed := load(path) as PackedScene
		if packed == null:
			failures.append("Cannot load scene: %s" % path)
			continue
		var scene := packed.instantiate()
		get_tree().root.add_child(scene)
		for frame in range(5):
			await get_tree().process_frame
		if path.ends_with("CombatMapEditor.tscn") and (scene.floor_asset_paths.is_empty() or scene.decoration_paths.is_empty()):
			failures.append("Exported editor catalogue is empty")
		if path.ends_with("CombatDebug.tscn"):
			scene.selected_scenario_id = "clearing_crossfire"
			scene._load_selected_scenario()
			for frame in range(5):
				await get_tree().process_frame
			var valid: bool = scene.state.get("id", "") == "clearing_crossfire" and scene.state.grid.width == 12 and scene.state.units.size() == 4
			for key in ["hp", "ap", "mp"]:
				valid = valid and scene.overlay_resource_bars[key].get_node_or_null("AmountLabel") != null
			if valid:
				var prior_mp: int = scene._unit_by_id("unit_player_001").resources.mp
				scene._on_tile_pressed({"x":1,"y":9})
				scene._on_tile_pressed({"x":1,"y":9})
				await get_tree().create_timer(1.0).timeout
				var moved: Dictionary = scene._unit_by_id("unit_player_001")
				valid = moved.position == {"x":1,"y":9} and int(moved.resources.mp) == prior_mp - 1 and not scene.animation_locked
			if valid:
				print("SDD_EXPORT_ENCOUNTER_PASS clearing_crossfire")
			else:
				failures.append("Exported data-authored encounter/UI/movement failed")
		scene.queue_free()
		await get_tree().process_frame
		print("SDD_EXPORT_SCENE_PASS ", path)
	await _campaign_probe(failures)
	await _trade_probe(failures)
	await _interface_probe(failures)
	await _polish_probe(failures)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("SDD_EXPORT_SMOKE_PASS")
	get_tree().quit(0 if failures.is_empty() else 1)


func _campaign_probe(failures: Array[String]) -> void:
	var campaign := get_node("/root/CampaignSession")
	var session := get_node("/root/DungeonRunSession")
	session.clear()
	campaign.load_profile("", true)
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	get_tree().root.add_child(app)
	await get_tree().process_frame
	app.action_buttons.travel_event_broken_cart.pressed.emit()
	await get_tree().process_frame
	app.action_buttons.travel_confirm.pressed.emit()
	await get_tree().process_frame
	app.action_buttons.event_salvage.pressed.emit()
	await get_tree().process_frame
	app.action_buttons.inventory.pressed.emit()
	await get_tree().process_frame
	var inventory := app.find_child("InventoryView", true, false)
	var gear := app.find_child("EquipmentView", true, false)
	var valid: bool = inventory != null and gear != null and inventory.shown_ids.size() == 4 and campaign.state.world.elapsed_hours == 3
	if gear != null:
		inventory.grid.item_buttons.patched_leather.pressed.emit()
		gear.equip_button.pressed.emit()
		await get_tree().process_frame
	valid = valid and campaign.state.equipment.unit_player_001.armor == "patched_leather"
	var owned: Array = campaign.state.items.duplicate()
	var equipment: Dictionary = campaign.state.equipment.duplicate(true)
	app.queue_free()
	await get_tree().process_frame
	# Isolated seeded road-entry fixture, preserving the equipment just chosen.
	campaign.load_profile("", true)
	campaign.state.items = owned
	campaign.state.equipment = equipment
	campaign.state.world.seed = 1
	valid = valid and campaign.travel("dungeon_old_mine") and campaign.choose_road_event("fight") and session.restore_road_combat()
	if valid:
		var combat: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
		get_tree().root.add_child(combat)
		for frame in range(5):
			await get_tree().process_frame
		var bran: Dictionary = combat._unit_by_id("unit_player_001")
		valid = combat.state.id == "roadside_ambush" and bran.loadout.armor == "patched_leather" and combat.state.item_profiles.patched_leather.armor_reduction == 1 and not campaign.equip("unit_player_001", "armor", null)
		combat.queue_free()
		await get_tree().process_frame
	session.clear()
	campaign.load_profile("", true)
	if valid:
		print("SDD_EXPORT_CAMPAIGN_PASS travel_stash_equipment_road")
	else:
		failures.append("Exported travel/stash/equipment/road launch failed")


func _trade_probe(failures: Array[String]) -> void:
	var campaign := get_node("/root/CampaignSession")
	campaign.load_profile("", true)
	var equipment: Dictionary = campaign.state.equipment.duplicate(true)
	var town: Control = load("res://scenes/town/town_shell.tscn").instantiate()
	get_tree().root.add_child(town)
	await get_tree().process_frame
	town.action_buttons.trade.pressed.emit()
	await get_tree().process_frame
	var view := town.find_child("TradingView", true, false)
	var valid := view != null
	if view != null:
		view.buy_grid.item_buttons.salvaged_blade.pressed.emit()
		view.buy_button.pressed.emit()
		await get_tree().process_frame
		view = town.find_child("TradingView", true, false)
		valid = campaign.state.gold == 24 and campaign.state.items.count("salvaged_blade") == 1 and view.selected_sell_id() == "salvaged_blade"
		view.sell_button.pressed.emit()
		await get_tree().process_frame
		view = town.find_child("TradingView", true, false)
		valid = valid and campaign.state.gold == 31 and not campaign.state.items.has("salvaged_blade") and campaign.state.equipment == equipment and view.sell_button.disabled
		town.action_buttons.close_trade.pressed.emit()
		await get_tree().process_frame
		valid = valid and town.action_buttons.has("buy_food") and town.action_buttons.has("trade")
	town.queue_free()
	await get_tree().process_frame
	campaign.load_profile("", true)
	if valid:
		print("SDD_EXPORT_TRADE_PASS ravenford_buy_sell")
	else:
		failures.append("Exported Ravenford trade/UI failed")


func _interface_probe(failures: Array[String]) -> void:
	var campaign := get_node("/root/CampaignSession")
	campaign.load_profile("",true)
	campaign.state.xp = 10
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	get_tree().root.add_child(app)
	await get_tree().process_frame
	app.shell.nav_buttons.training.pressed.emit()
	for frame in range(5): await get_tree().process_frame
	var view := app.find_child("TrainingView",true,false)
	var valid := view != null
	if view != null:
		view.train_buttons.unit_player_001.pressed.emit()
		for frame in range(5): await get_tree().process_frame
		view = app.find_child("TrainingView",true,false)
		valid = campaign.state.advancement.unit_player_001 == 2 and campaign.available_xp() == 0 and view.train_buttons.unit_player_002.disabled and app.shell.footer.get_global_rect().end.y <= app.size.y+1
	app.queue_free()
	await get_tree().process_frame
	campaign.load_profile("",true)
	if valid: print("SDD_EXPORT_INTERFACE_PASS shell_training")
	else: failures.append("Exported campaign shell/training failed")

func _polish_probe(failures: Array[String]) -> void:
	var campaign := get_node("/root/CampaignSession")
	campaign.load_profile("",true)
	var app: Control = load("res://scenes/town/town_shell.tscn").instantiate()
	get_tree().root.add_child(app)
	await get_tree().process_frame
	app.action_buttons.trade.pressed.emit()
	await get_tree().process_frame
	var trade := app.find_child("TradingView",true,false)
	trade.buy_grid.item_buttons.patched_leather.pressed.emit()
	trade.buy_button.pressed.emit()
	await get_tree().process_frame
	app.shell.nav_buttons.stash.pressed.emit()
	await get_tree().process_frame
	var gear := app.find_child("EquipmentView",true,false)
	var inventory := app.find_child("InventoryView",true,false)
	gear.hero_buttons.unit_player_002.pressed.emit()
	inventory.grid.item_buttons.patched_leather.pressed.emit()
	gear.equip_button.pressed.emit()
	await get_tree().process_frame
	gear = app.find_child("EquipmentView",true,false)
	var valid: bool = campaign.state.gold == 26 and campaign.state.equipment.unit_player_002.armor == "patched_leather" and gear.selected_hero == "unit_player_002" and gear.selected_item == "patched_leather"
	app.shell.nav_buttons.region.pressed.emit()
	for frame in range(5): await get_tree().process_frame
	var map := app.find_child("RegionMap",true,false)
	map.marker_buttons.event_broken_cart.pressed.emit()
	await get_tree().process_frame
	app.action_buttons.travel_confirm.pressed.emit()
	await get_tree().process_frame
	map = app.find_child("RegionMap",true,false)
	valid = valid and campaign.state.world.location_id == "event_broken_cart" and campaign.state.world.elapsed_hours == 2 and campaign.state.world.pending_event.kind == "cart"
	for marker: Button in map.marker_buttons.values(): valid = valid and marker.disabled
	app.queue_free()
	await get_tree().process_frame
	campaign.load_profile("",true)
	if valid: print("SDD_EXPORT_POLISH_PASS inventory_services_map")
	else: failures.append("Exported visual inventory/service/map loop failed")

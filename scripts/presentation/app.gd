extends Control

const Catalog := preload("res://scripts/systems/data_catalog.gd")
const Campaign := preload("res://scripts/session/campaign_session.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Advancement := preload("res://scripts/domain/party_advancement.gd")
const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const PartyCard := preload("res://scenes/ui/PartyCard.tscn")
const Travel := preload("res://scripts/domain/world_travel.gd")
const RegionMap := preload("res://scripts/presentation/world/region_map.gd")
const InventoryView := preload("res://scripts/presentation/world/inventory_view.gd")
const Items := preload("res://scripts/domain/item_catalog.gd")
const EquipmentView := preload("res://scripts/presentation/world/equipment_view.gd")
const TradingView := preload("res://scripts/presentation/world/trading_view.gd")
const TrainingView := preload("res://scripts/presentation/world/training_view.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const CampaignShell := preload("res://scripts/presentation/world/campaign_shell.gd")
const CampaignColumns := preload("res://scripts/presentation/world/campaign_columns.gd")
const FRAME := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_10.png"
@export var town_view := false
var skin := PixelSkin.new()
var shell: Control
var content: VBoxContainer
var feedback: Label
var action_buttons: Dictionary = {}
var inventory_view := false
var trading_view := false
var training_view := false
var trade_buy_id := ""
var trade_sell_id := ""
var inventory_item_id := ""
var inventory_category := "all"
var inventory_hero_id := "unit_player_001"
var inventory_slot := "main_hand"


func _ready() -> void:
	var campaign := _campaign()
	if not campaign.loaded:
		if "--hero-equipment-pilot" in OS.get_cmdline_user_args() or bool(ProjectSettings.get_setting("debug/qa/hero_equipment_pilot", false)):
			preload("res://scripts/qa/hero_equipment_pilot.gd").open(campaign)
			inventory_view = true
		else:
			campaign.load_profile("user://campaign_v1.json", DisplayServer.get_name() == "headless")
	_render()


func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	action_buttons.clear()
	shell = CampaignShell.new()
	shell.name = "CampaignShell"
	add_child(shell)
	content = shell.content
	feedback = shell.feedback
	var campaign := _campaign()
	if not campaign.loaded:
		shell.configure("Campaign unavailable", "", {}, "region", false, false)
		feedback.text = campaign.last_feedback
		return
	var profile: Dictionary = campaign.state
	var selected := "training" if training_view else ("trade" if trading_view else ("stash" if inventory_view else ("town" if town_view else "region")))
	var titles := {"region":"The Marches", "town":"Ravenford", "stash":"Stash & equipment", "trade":"Trading Post", "training":"Party advancement"}
	shell.configure(titles[selected], "%s  /  %s" % [Travel.node_name(profile.world.location_id),Travel.clock_text(profile.world)], {"Gold":"%sg" % int(profile.gold),"Available XP":str(campaign.available_xp()),"Food":str(int(profile.supplies.food))}, selected, campaign.at_town(), campaign.can_trade())
	shell.navigation_requested.connect(_navigate)
	feedback.text = campaign.last_feedback
	feedback.tooltip_text = campaign.last_feedback
	_render_party(profile)
	if training_view:
		var training := TrainingView.new()
		training.name = "TrainingView"
		content.add_child(training)
		training.configure(profile.advancement,int(profile.xp),campaign.can_trade())
		training.train_requested.connect(func(id: String) -> void:
			campaign.train(id)
			_render()
		)
		_button("close_training","Back to town services",func() -> void:
			training_view = false
			_render()
		)
		return
	if trading_view:
		var trading := TradingView.new()
		trading.name = "TradingView"
		content.add_child(trading)
		trading.configure(profile.items,profile.equipment,int(profile.gold),campaign.can_trade(),trade_buy_id,trade_sell_id)
		trading.buy_requested.connect(_trade_buy)
		trading.sell_requested.connect(_trade_sell)
		_button("close_trade","Back to town services",_close_trade)
		return
	if inventory_view:
		var view := InventoryView.new()
		view.name = "InventoryView"
		view.configure(profile.items,profile.equipment,inventory_item_id,inventory_category)
		var equipment := EquipmentView.new()
		equipment.name = "EquipmentView"
		content.add_child(equipment)
		var hero_details: Dictionary = {}
		var party_state: Dictionary = profile.effects.duplicate(true) if profile.active_run.is_empty() else profile.active_run.state.duplicate(true)
		party_state.party_formation = Party.default_party_formation()
		for hero: Dictionary in Party.default_party():
			var id: String = hero.combat_unit_id
			hero_details[id] = {"level":int(profile.advancement[id]),"hp":Model.party_member_hp(party_state,id),"stats":Advancement.stats(id,int(profile.advancement[id]))}
		equipment.configure(profile.items,profile.equipment,not profile.active_run.is_empty() or not profile.world.pending_event.is_empty(),{"hero":inventory_hero_id,"item":inventory_item_id,"slot":inventory_slot},hero_details)
		equipment.attach_inventory(view)
		view.item_selected.connect(func(id: String) -> void:
			inventory_item_id = id
			equipment.select_item(id)
			inventory_slot = equipment.selected_slot
		)
		view.category_changed.connect(func(category: String) -> void: inventory_category = category)
		equipment.hero_selected.connect(func(id: String) -> void: inventory_hero_id = id)
		equipment.item_focused.connect(func(id: String) -> void:
			inventory_item_id = id
			view.select_item(id)
		)
		equipment.slot_selected.connect(func(slot: String) -> void:
			inventory_slot = slot
			view.highlight_slot(slot)
		)
		equipment.equip_requested.connect(func(hero_id: String,slot: String,item_id: Variant) -> void:
			var scroll_before: int=view.entries_scroll.scroll_vertical
			campaign.equip(hero_id,slot,item_id)
			_render()
			var restored: Control=find_child("InventoryView",true,false)
			if restored!=null: restored.restore_position(scroll_before,inventory_item_id)
		)
		_button("close_stash","Back",_close_stash)
		return
	if town_view:
		_render_town(profile)
	else:
		_render_region(profile)


func _render_party(profile: Dictionary) -> void:
	var party_state: Dictionary = profile.effects.duplicate(true) if profile.active_run.is_empty() else profile.active_run.state.duplicate(true)
	party_state.party_formation = Party.default_party_formation()
	UI.label(shell.rail,"YOUR COMPANY",20,UI.GOLD)
	var compact: Array[String] = []
	for hero: Dictionary in Party.default_party():
		var hp := Model.party_member_hp(party_state,str(hero.combat_unit_id))
		var level := int(profile.advancement[hero.combat_unit_id])
		compact.append("%s Lv%s  HP%s/%s" % [hero.display_name,level,hp,hero.stats.max_hp])
		var card := PartyCard.instantiate()
		card.configure(hero,hp,UI.GOLD,UI.box())
		card.custom_minimum_size = Vector2(220,190)
		card.get_node("Margin/Content/Name").add_theme_font_size_override("font_size",22)
		card.hp_label.add_theme_font_size_override("font_size",18)
		card.get_node("Margin/Content/Portrait").custom_minimum_size.y = 100
		shell.rail.add_child(card)
		UI.label(shell.rail,"%s  /  Level %s" % [hero.class_name,level],20,UI.MUTED)
	var supplies := UI.card(shell.rail,"Supplies")
	for key: String in Campaign.PRICES:
		UI.label(supplies,"%s   %s" % [Campaign.SUPPLY_NAMES[key],int(profile.supplies[key])],20,UI.MUTED)
	shell.compact_summary.text = "  |  ".join(compact)


func _render_town(profile: Dictionary) -> void:
	var main := content
	var columns := CampaignColumns.new()
	main.add_child(columns)
	var banner := UI.card(main,"Ravenford","Provisioner  /  Trading Post  /  Inn  /  Training grounds")
	banner.get_parent().add_theme_stylebox_override("panel",UI.hero_frame())
	var town_art := TextureRect.new()
	town_art.texture = load("res://assets/ui/campaign/ravenford.png")
	town_art.custom_minimum_size.y = 230
	town_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	town_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	town_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(town_art)
	main.move_child(banner.get_parent(),0)
	content = UI.card(columns,"Provisioner","Supplies go to your company stash.")
	var supplies := GridContainer.new()
	supplies.columns = 3
	supplies.add_theme_constant_override("h_separation",10)
	supplies.add_theme_constant_override("v_separation",10)
	content.add_child(supplies)
	for key: String in Campaign.PRICES:
		var tile := _button("buy_"+key,"",func() -> void: _buy(key),supplies)
		tile.custom_minimum_size = Vector2(120,148)
		tile.disabled = not _campaign().can_trade() or int(profile.gold) < int(Campaign.PRICES[key])
		tile.tooltip_text = "Buy %s for %sg / Owned %s" % [Campaign.SUPPLY_NAMES[key],Campaign.PRICES[key],int(profile.supplies[key])]
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,10)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(margin)
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(body)
		var supply_icons := {"food":"food","bandage":"bandage","camping_kit":"tent","pickaxe":"pickaxe","trap_tools":"trap","lamp_oil":"oil"}
		var supply_icon := TextureRect.new()
		supply_icon.texture = UI.icon(str(supply_icons.get(key,"food")))
		supply_icon.custom_minimum_size.y = 40
		supply_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		supply_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		supply_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(supply_icon)
		UI.label(body,Campaign.SUPPLY_NAMES[key],18)
		UI.label(body,"%sg  /  Owned %s" % [Campaign.PRICES[key],int(profile.supplies[key])],18,UI.GOLD)
	content = UI.card(columns,"Town services","Trade, recover and develop your company before the next journey.")
	_button("trade","Trading Post  /  Equipment & loot",_open_trade).disabled = not _campaign().can_trade()
	_button("training","Training grounds  /  Allocate XP",_open_training).disabled = not _campaign().can_trade()
	_button("recover","Rest at the inn  /  5g",_recover).disabled = not _campaign().can_trade() or int(profile.gold) < 5
	if not _campaign().can_trade(): _label("Services unlock after the current expedition or road event is resolved.",20,UI.MUTED)
	content = main
	_button("inventory","Open stash",_open_stash)
	_button("world","Return to region",func() -> void: _navigate("region"))


func _render_region(profile: Dictionary) -> void:
	var main := content
	var region: Dictionary = Catalog.load_vertical_slice().world_region
	var layout := preload("res://scripts/presentation/world/region_layout.gd").new()
	main.add_child(layout)
	var map_panel := UI.card(layout,"The Marches","Known roads  /  Keep provisions for the return")
	map_panel.get_parent().size_flags_stretch_ratio = 2.8
	var map := RegionMap.new()
	map.name = "RegionMap"
	map_panel.add_child(map)
	var quotes: Dictionary = {}
	for route: Dictionary in Travel.routes(region,profile.world.location_id):
		var quote := Travel.quote(profile.world,route.to)
		quotes[route.to] = {"allowed":profile.active_run.is_empty() and profile.world.pending_event.is_empty() and int(profile.supplies.food) >= int(quote.food)+int(quote.return_food),"caption":"%sh  /  %s food" % [quote.time_hours,quote.food],"tooltip":"%s / Danger %s%% / Keep %s food for return" % [Travel.node_name(route.to),int(quote.danger*100),quote.return_food]}
	map.configure(region,profile.world.location_id,quotes)
	map.destination_selected.connect(_travel)
	var columns := VBoxContainer.new()
	columns.custom_minimum_size.x = 360
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	layout.add_child(columns)
	content = UI.card(columns,"Journey","%s  /  %s" % [Travel.node_name(profile.world.location_id),Travel.clock_text(profile.world)])
	if not profile.world.pending_event.is_empty(): _render_road_event(profile.world.pending_event)
	elif not profile.active_run.is_empty():
		_label("Your expedition is in progress. Resume its saved checkpoint.",22)
		_button("resume","Resume expedition",_resume)
	else:
		for route: Dictionary in Travel.routes(region,profile.world.location_id):
			var destination: String = route.to
			var quote := Travel.quote(profile.world,destination)
			var text := "%s  /  %sh  /  %s food" % [Travel.node_name(destination),quote.time_hours,quote.food]
			_button("travel_"+destination,text,func() -> void: _travel(destination)).disabled = int(profile.supplies.food) < int(quote.food)+int(quote.return_food)
			_label("Danger %s%%  /  Return reserve %s food" % [int(quote.danger*100),quote.return_food],20,UI.MUTED)
	content = UI.card(columns,"At your destination","Town services require Ravenford; expeditions depart from the Old Mine.")
	_button("town","Enter Ravenford",func() -> void: _navigate("town")).disabled = not _campaign().at_town()
	if profile.active_run.is_empty(): _button("prepare","Old Mine  /  Prepare expedition",_prepare).disabled = profile.world.location_id != "dungeon_old_mine" or not profile.world.pending_event.is_empty()
	_button("inventory","Open stash",_open_stash)
	if profile.world.last_journey.has("event_result"): _label("Last road event: "+str(profile.world.last_journey.event_result).capitalize(),20,UI.MUTED)
	if not profile.last_return.is_empty(): _label("Last expedition: %s  /  +%sg  +%s XP  /  %s items" % [profile.last_return.outcome,int(profile.last_return.gold),int(profile.last_return.xp),profile.last_return.items.size()],20,UI.MUTED)
	content = main


func _navigate(id: String) -> void:
	if id == "town" and not _campaign().at_town(): return
	if id in ["trade","training"] and not _campaign().can_trade(): return
	inventory_view = id == "stash"
	trading_view = id == "trade"
	training_view = id == "training"
	if id == "region": town_view = false
	if id in ["town","trade","training"]: town_view = true
	_render()


func _label(text: String, font_size: int, color: Color = UI.TEXT) -> Label:
	return UI.label(content,text,font_size,color)


func _button(id: String,text: String,callback: Callable,parent: Node = null) -> Button:
	var button := UI.button(text,id in ["prepare","resume","event_fight"] or id.begins_with("travel_"))
	button.pressed.connect(callback)
	(parent if parent != null else content).add_child(button)
	action_buttons[id] = button
	return button


func _buy(key: String) -> void:
	_campaign().purchase(key)
	_render()


func _recover() -> void:
	_campaign().recover()
	_render()


func _prepare() -> void:
	if not _campaign().loaded or not _campaign().state.active_run.is_empty() or _campaign().state.world.location_id != "dungeon_old_mine" or not _campaign().state.world.pending_event.is_empty():
		return
	var session := get_node("/root/DungeonRunSession")
	session.clear()
	session.town_preparation = true
	get_tree().change_scene_to_file("res://scenes/dungeon/DungeonDebug.tscn")


func _resume() -> void:
	var session := get_node("/root/DungeonRunSession")
	if session.restore_campaign():
		get_tree().change_scene_to_file("res://scenes/dungeon/DungeonDebug.tscn")


func _campaign() -> Node:
	return get_node("/root/CampaignSession")


func _travel(destination: String) -> void:
	_campaign().travel(destination)
	_render()


func _open_stash() -> void:
	training_view = false
	trading_view = false
	inventory_view = true
	_render()


func _close_stash() -> void:
	inventory_view = false
	_render()


func _open_trade() -> void:
	if not town_view or not _campaign().can_trade():
		return
	inventory_view = false
	training_view = false
	trading_view = true
	_render()


func _open_training() -> void:
	if not town_view or not _campaign().can_trade():
		return
	inventory_view = false
	trading_view = false
	training_view = true
	_render()


func _remember_trade_selection() -> void:
	var view := find_child("TradingView", true, false)
	if view != null:
		trade_buy_id = view.selected_buy_id()
		trade_sell_id = view.selected_sell_id()


func _trade_buy(item_id: String) -> void:
	_remember_trade_selection()
	_campaign().purchase_item(item_id)
	_render()


func _trade_sell(item_id: String) -> void:
	_remember_trade_selection()
	_campaign().sell_item(item_id)
	_render()


func _close_trade() -> void:
	_remember_trade_selection()
	trading_view = false
	_render()


func _render_road_event(pending: Dictionary) -> void:
	var definitions := Travel.event_definitions()
	var entry: Dictionary = definitions[pending.kind]
	_label(entry.title, 30, Color("e9c36d"))
	_label(entry.description, 23)
	if pending.kind == "cart":
		for choice: Dictionary in entry.choices:
			var id: String = choice.id
			_button("event_" + id, choice.label, func() -> void: _choose_road_event(id))
	elif pending.phase == "combat":
		_button("resume_ambush", "Resume ambush", _resume_ambush)
	else:
		_button("event_fight", "Fight the bandits", func() -> void: _choose_road_event("fight"))
		_button("event_pay", "Pay toll  /  %sg" % int(entry.toll_gold), func() -> void: _choose_road_event("pay")).disabled = int(_campaign().state.gold) < int(entry.toll_gold)


func _choose_road_event(choice: String) -> void:
	if _campaign().choose_road_event(choice) and choice == "fight":
		_resume_ambush()
	else:
		_render()


func _resume_ambush() -> void:
	var session := get_node("/root/DungeonRunSession")
	if session.restore_road_combat():
		get_tree().change_scene_to_file(session.COMBAT_SCENE_PATH)

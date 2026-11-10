extends "res://scripts/presentation/dungeon/expedition_chrome.gd"
## Native composition; inherited preview/confirm/event rules remain authoritative.
const AshenStyle := preload("res://scripts/presentation/dungeon/ashen_skin.gd")
var header_art: TextureRect
var inspector_art: TextureRect
var title_plate: PanelContainer
var light_icon: TextureRect
var light_header: Label
var inspector_seal: TextureRect
var ui_scale := 1.0
var archetype := "mine"
var flavor: Label
var destination_state: Label
var pinned_start: Button

func apply_archetype(hud,id: String) -> void:
	if id not in ["mine","dungeon","castle","forest"]: return
	archetype = id
	var paper := "map-paper" if id=="mine" else id+"/map-paper"
	if ResourceLoader.exists(AshenStyle.ROOT+paper+".png"):
		hud.map_frame_panel.add_theme_stylebox_override("panel",AshenStyle.frame(paper,0,28))
	if inspector_seal!=null: inspector_seal.texture = AshenStyle.texture("seal-"+id)
	for room: Dictionary in hud.dungeon.get("rooms",[]):
		var panel: Control = hud.room_nodes.get(str(room.id))
		if panel!=null and panel.has_node("RoomBody/Art"):
			panel.get_node("RoomBody/Art").texture = AshenStyle.texture(archetype+"/"+illustration(room,str(hud.dungeon.start_room_id)))
	refresh(hud)

func setup(hud) -> void:
	super.setup(hud)
	hud.theme = AshenStyle.theme()
	hud.get_node("CampaignHide").hide()
	header_art = AshenStyle.picture(hud,"header","AshenHeader")
	header_art.stretch_mode = TextureRect.STRETCH_SCALE
	hud.move_child(header_art,1)
	hud.detail_panel.add_theme_stylebox_override("panel",AshenStyle.frame("inspector",30,28))
	hud.map_frame_panel.add_theme_stylebox_override("panel",AshenStyle.frame("map-paper",0,28))
	hud.party_panel.add_theme_stylebox_override("panel",AshenStyle.frame("company",0,24))
	map_heading.hide()
	light_summary.hide()
	title_plate = PanelContainer.new()
	title_plate.name = "AshenInspectorTitle"
	title_plate.add_theme_stylebox_override("panel",AshenStyle.frame("title-plaque",14,22))
	hud.detail_box.add_child(title_plate)
	hud.detail_box.move_child(title_plate,0)
	hud.panel_title.reparent(title_plate)
	hud.panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.panel_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_art = AshenStyle.picture(hud.detail_box,"mine/entrance","DestinationVignette")
	inspector_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	inspector_art.clip_contents = true
	hud.detail_box.move_child(inspector_art,1)
	flavor = Label.new()
	flavor.name = "LocationAtmosphere"
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.detail_box.add_child(flavor)
	hud.detail_box.move_child(flavor,2)
	var state_panel := PanelContainer.new()
	state_panel.name = "DestinationState"
	state_panel.add_theme_stylebox_override("panel",AshenStyle.frame("state-swash",5,3))
	preview_box.add_child(state_panel)
	preview_box.move_child(state_panel,1)
	destination_state = Label.new()
	destination_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_panel.add_child(destination_state)
	light_icon = AshenStyle.picture(hud,"light","AshenLight")
	light_header = Label.new()
	light_header.name = "AshenLightValue"
	hud.add_child(light_header)
	inspector_seal = AshenStyle.picture(hud,"seal-mine","InspectorSeal")
	current_button.text = "Back"
	for button: Button in hud.loadout_panel.find_children("*","Button",true,false):
		if button.text=="Start Expedition":
			pinned_start = button
			pinned_start.reparent(hud)
			break
	var strategic: bool=hud._run_session().campaign_owner().has_method("regional_active")
	hud.world_button.text = "Return to the region" if strategic else "Return to Ravenford"
	hud.world_button.tooltip_text = "Return to the strategic region [F7]" if strategic else "Return to the world / Ravenford [F7]"
	for card: PanelContainer in hud.party_cards.values():
		card.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		var portrait: TextureRect = card.find_child("Portrait",true,false)
		var hero_name: String = str(card.find_child("Name",true,false).text).to_lower()
		if ResourceLoader.exists(AshenStyle.ROOT+"portrait-"+hero_name+".png"):
			portrait.texture = AshenStyle.texture("portrait-"+hero_name)
		var ring := AshenStyle.picture(portrait,"portrait-ring","AshenPortraitRing")
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Every decorative root child must remain below the modal scrim and dialog.
	hud.move_child(shade,-1)
	hud.move_child(hud.corridor_event_panel,-1)
	layout(hud)
	refresh(hud)

func _style_text(parent: Node, color: Color) -> void:
	for label: Label in parent.find_children("*","Label",true,false):
		label.add_theme_font_override("font",AshenStyle.FONT)
		label.add_theme_font_size_override("font_size",maxi(18,roundi(22*ui_scale)))
		label.add_theme_color_override("font_color",color)

func style_button(button: Button) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]: button.remove_theme_stylebox_override(state)
	var primary := button.text in ["Travel to room","Start Expedition","Enter Combat","Claim Reward","Finish Expedition"]
	var returning := button.text in ["Return to Ravenford","Return to the region"]
	var id := "button-return" if returning else ("button-primary" if primary else "button-secondary")
	for state in ["normal","hover","pressed","disabled"]:
		var box := AshenStyle.frame(id,(6 if returning or button.text in ["+","-"] else 12)*ui_scale,20)
		box.modulate_color = Color(1.12,1.08,1.02) if state=="hover" else (Color(.65,.65,.65) if state=="disabled" else (Color(.8,.8,.8) if state=="pressed" else Color.WHITE))
		button.add_theme_stylebox_override(state,box)
	button.add_theme_font_override("font",AshenStyle.FONT)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,AshenStyle.IVORY if primary or returning else AshenStyle.INK)
	button.add_theme_font_size_override("font_size",maxi(18,roundi(23*ui_scale)))
	button.custom_minimum_size.y = 48*ui_scale
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.tooltip_text = button.text
	if button.text in ["+","-"]:
		button.custom_minimum_size.x = maxf(36,38*ui_scale)
		button.add_theme_font_override("font",AshenStyle.SYMBOL_FONT)

func _resources(hud) -> void:
	for child: Node in hud.resource_tray_panel.get_children():
		hud.resource_tray_panel.remove_child(child)
		child.queue_free()
	hud.resource_tiles.clear()
	hud.resource_tile_labels.clear()
	hud.resource_tray_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	hud.resource_tray_panel.add_child(row)
	var names := {"torch":"Oil","pickaxe":"Pick","trap_tools":"Tools","bandage":"Bandage","camping_kit":"Camp","food":"Food"}
	for id: String in hud._resource_tile_ids():
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		row.add_child(tile)
		var box := HBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation",5)
		tile.add_child(box)
		var art := TextureRect.new()
		art.texture = AshenStyle.texture("supply-"+id)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(30,36)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(art)
		var label := Label.new()
		label.name = "ResourceName"
		label.text = names[id]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(label)
		var value := Label.new()
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(value)
		hud.resource_tiles[id] = tile
		hud.resource_tile_labels[id] = value

func layout(hud) -> void:
	var view: Vector2 = hud.get_viewport_rect().size
	ui_scale = minf(view.x/1672.0,view.y/941.0)
	var s := ui_scale
	var detail_width := view.x*.272
	var top := 108*s
	var footer_height := 160*s
	hud.map_area = Rect2(12*s,top,view.x-detail_width-30*s,view.y-top-footer_height-24*s)
	hud.detail_area = Rect2(view.x-detail_width-10*s,top,detail_width,view.y-top-footer_height-8*s)
	hud.party_area = Rect2(8*s,view.y-footer_height,view.x-16*s,footer_height)
	hud.resource_tray_area = Rect2(584*s,14*s,view.x-836*s,62*s)
	for entry in [[hud.detail_panel,hud.detail_area],[hud.map_frame_panel,hud.map_area],[hud.party_panel,hud.party_area],[hud.resource_tray_panel,hud.resource_tray_area]]:
		var control: Control = entry[0]
		control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		control.custom_minimum_size = Vector2.ZERO
		control.position = entry[1].position
		control.size = entry[1].size
	var header: Control = hud.get_node("Header")
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	header.position = Vector2(108,7)*s
	header.size = Vector2(290,77)*s
	for side in ["left","top","right","bottom"]: header.add_theme_constant_override("margin_"+side,0)
	hud.title_label.add_theme_font_override("font",AshenStyle.FONT)
	hud.title_label.add_theme_color_override("font_color",AshenStyle.IVORY)
	hud.title_label.add_theme_font_size_override("font_size",roundi(50*s))
	hud.title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud.title_label.tooltip_text = str(hud.dungeon.get("display_name",""))
	hud.world_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.world_button.position = Vector2(view.x-222*s,18*s)
	hud.world_button.size = Vector2(208,46)*s
	style_button(hud.world_button)
	hud.world_button.add_theme_font_size_override("font_size",maxi(16,roundi(18*s)))
	if header_art!=null: header_art.size = Vector2(view.x,100*s)
	if inspector_seal!=null:
		inspector_seal.position = hud.detail_area.position+Vector2(2,-16)*s
		inspector_seal.size = Vector2(66,104)*s
	if pinned_start!=null:
		var inset := maxf(40,22*s)
		pinned_start.position = Vector2(hud.detail_area.position.x+inset,hud.detail_area.end.y-inset-48*s)
		pinned_start.size = Vector2(hud.detail_area.size.x-inset*2,48*s)
		style_button(pinned_start)
	if light_header!=null:
		light_icon.position = Vector2(415,18)*s
		light_icon.size = Vector2(30,43)*s
		light_header.position = Vector2(456,23)*s
		light_header.size = Vector2(126,42)*s
		_style_text(hud.resource_tray_panel,AshenStyle.IVORY)
		light_header.add_theme_font_override("font",AshenStyle.FONT)
		light_header.add_theme_font_size_override("font_size",roundi(22*s))
		light_header.add_theme_color_override("font_color",AshenStyle.IVORY)
		for tile: Control in hud.resource_tiles.values():
			var art: TextureRect = tile.find_children("*","TextureRect",true,false)[0]
			art.custom_minimum_size = Vector2(27,36)*s
	_style_text(hud.detail_box,AshenStyle.INK)
	# Texture border caps retain a physical minimum; paper copy must clear them.
	hud.detail_panel.get_theme_stylebox("panel").set_content_margin_all(maxf(40,22*s))
	var packing_margin: MarginContainer = hud.loadout_panel.get_child(0)
	for side in ["left","right","top","bottom"]: packing_margin.add_theme_constant_override("margin_"+side,0)
	for row: Dictionary in hud.loadout_rows.values():
		var row_box: HBoxContainer = row.value_label.get_parent()
		var supply_name: Label = row_box.get_child(0)
		supply_name.custom_minimum_size.x = 108*s
		supply_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.value_label.custom_minimum_size.x = 26*s
		row_box.add_theme_constant_override("separation",roundi(8*s))
	hud.panel_title.add_theme_color_override("font_color",AshenStyle.IVORY)
	hud.panel_title.add_theme_font_size_override("font_size",roundi(29*s))
	hud.detail_box.add_theme_constant_override("separation",roundi(12*s))
	if inspector_art!=null: inspector_art.custom_minimum_size = Vector2(0,145*s)
	if flavor!=null:
		flavor.add_theme_font_override("font",AshenStyle.ITALIC)
		flavor.add_theme_font_size_override("font_size",maxi(18,roundi(20*s)))
	if destination_state!=null:
		destination_state.add_theme_font_override("font",AshenStyle.ITALIC)
		destination_state.add_theme_font_size_override("font_size",maxi(18,roundi(21*s)))
		destination_state.add_theme_color_override("font_color",AshenStyle.IVORY)
	preview_box.add_theme_constant_override("separation",roundi(12*s))
	for button: Button in hud.detail_box.find_children("*","Button",true,false): style_button(button)
	for row: Dictionary in hud.loadout_rows.values():
		row.minus_button.custom_minimum_size = Vector2.ONE*maxf(36,36*s)
		row.plus_button.custom_minimum_size = Vector2.ONE*maxf(36,36*s)
	var margin: MarginContainer = hud.party_panel.get_child(0)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,roundi((112 if side=="left" else 18)*s))
	for card: PanelContainer in hud.party_cards.values():
		card.use_expedition_layout(false)
		var portrait: TextureRect = card.find_child("Portrait",true,false)
		portrait.custom_minimum_size = Vector2(114,114)*s
		card.custom_minimum_size = Vector2(346,120)*s
		_style_text(card,AshenStyle.IVORY)
		card.find_child("Name",true,false).add_theme_font_size_override("font_size",roundi(28*s))
		card.hp_bar.custom_minimum_size = Vector2(190,14)*s
	hud.party_log_label.custom_minimum_size = Vector2(0,66*s)
	hud.party_log_label.max_lines_visible = 2
	hud.party_log_label.add_theme_font_override("font",AshenStyle.ITALIC)
	hud.party_log_label.add_theme_font_size_override("font_size",maxi(18,roundi(20*s)))
	hud.party_log_label.add_theme_color_override("font_color",Color("baa990"))
	hud._recalculate_graph_transform()
	var rect := map_scroll_rect(hud)
	hud.map_scroll_container.position = rect.position
	hud.map_scroll_container.size = rect.size
	hud.map_scroll_container.custom_minimum_size = Vector2.ZERO
	hud.map_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hud.graph_layer.custom_minimum_size = hud.graph_content_size
	hud.graph_layer.size = hud.graph_content_size
	_style_text(hud.corridor_event_panel,AshenStyle.INK)
	hud.corridor_event_title_label.add_theme_font_override("font",AshenStyle.FONT)
	hud.corridor_event_title_label.add_theme_font_size_override("font_size",maxi(22,roundi(28*s)))
	center_event(hud)

func _event(hud) -> void:
	super._event(hud)
	var background: NinePatchRect = hud.corridor_event_panel.get_child(0)
	background.texture = AshenStyle.texture("inspector")
	for side in ["left","right","top","bottom"]: background.set("patch_margin_"+side,32)
	var margin: MarginContainer = hud.corridor_event_panel.get_child(1)
	margin.offset_left = 52
	margin.offset_top = 56
	margin.offset_right = -52
	margin.offset_bottom = -48

func map_scroll_rect(hud) -> Rect2:
	return Rect2(hud.map_area.position+Vector2(12,12)*ui_scale,hud.map_area.size-Vector2(24,24)*ui_scale)

func layout_graph(hud) -> void:
	hud.graph_axis_swap = hud._should_swap_graph_axes()
	var bounds: Dictionary = hud._authored_room_bounds()
	var span := Vector2(maxf(1,bounds.max_x-bounds.min_x),maxf(1,bounds.max_y-bounds.min_y))
	var padding := Vector2(12,16)*ui_scale
	hud.graph_node_scale = ui_scale
	hud.room_node_size = Vector2(200,180)*ui_scale
	var required: Vector2 = hud.room_node_size+span*Vector2(232,205)*ui_scale+padding*2
	hud.graph_content_size = map_scroll_rect(hud).size.max(required)
	hud.graph_step = (hud.graph_content_size-padding*2-hud.room_node_size)/span
	hud.graph_origin = padding-Vector2(bounds.min_x,bounds.min_y)*hud.graph_step

func use_mine_chart(_hud) -> bool: return false
func build_backdrop(_hud) -> void: pass
func room_style(_hud,_id: String,_kind: String) -> StyleBox: return StyleBoxEmpty.new()

func build_passages(hud) -> void:
	passages = Passages.new()
	passages.name = "DungeonPassages"
	passages.grid_cell = maxf(4,8*ui_scale)
	passages.room_clearance = maxf(4,4*ui_scale)
	passages.parchment_style = true
	hud.graph_layer.add_child(passages)
	var rooms: Dictionary = {}
	for room: Dictionary in hud.dungeon.get("rooms",[]):
		rooms[str(room.id)] = Rect2(hud._room_screen_position(room),hud.room_node_size)
	passages.configure(rooms,hud.dungeon.get("corridors",[]),hud.graph_content_size)
	passages.select_passage(str(hud.run_state.get("current_room_id","")),preview_room_id)

func illustration(room: Dictionary, start: String) -> String:
	if str(room.id)==start: return "entrance"
	if room.has("locked_by_item_id"): return "locked"
	var kind := str(room.get("kind","empty"))
	return {"combat":"spider","guarded_treasure":"guarded_treasure","treasure":"treasure","exit":"exit"}.get(kind,"crossing")

func room_panel(hud,room: Dictionary) -> PanelContainer:
	var id := str(room.id)
	var panel := PanelContainer.new()
	panel.position = hud._room_screen_position(room)
	panel.size = hud.room_node_size
	panel.custom_minimum_size = hud.room_node_size
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var body := Control.new()
	body.name = "RoomBody"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(body)
	var w: float = hud.room_node_size.x
	var h: float = hud.room_node_size.y
	var art := AshenStyle.picture(body,archetype+"/"+illustration(room,str(hud.dungeon.start_room_id)),"Art")
	art.position = Vector2(4,0)*ui_scale
	art.size = Vector2(w-8*ui_scale,h-34*ui_scale)
	var ring := AshenStyle.picture(body,"selection","Selection")
	ring.position = Vector2(-8,-4)*ui_scale
	ring.size = Vector2(w+16*ui_scale,h-24*ui_scale)
	var slip := AshenStyle.picture(body,"label-slip","Slip")
	slip.stretch_mode = TextureRect.STRETCH_SCALE
	slip.position = Vector2(0,h-45*ui_scale)
	slip.size = Vector2(w,48*ui_scale)
	var label := Label.new()
	label.name = "RoomName"
	label.text = str(room.display_name)
	label.position = Vector2(12*ui_scale,h-44*ui_scale)
	label.size = Vector2(w-24*ui_scale,46*ui_scale)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",AshenStyle.FONT)
	label.add_theme_font_size_override("font_size",maxi(18,roundi(22*ui_scale)))
	label.add_theme_color_override("font_color",AshenStyle.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(label)
	var state := Label.new()
	state.name = "State"
	state.hide()
	body.add_child(state)
	var pin := AshenStyle.picture(body,"current-pin","CurrentPin")
	pin.position = Vector2(22*ui_scale,h-79*ui_scale)
	pin.size = Vector2(24,38)*ui_scale
	var lock := AshenStyle.picture(body,"lock","Lock")
	lock.position = Vector2(w-30*ui_scale,h-38*ui_scale)
	lock.size = Vector2(18,26)*ui_scale
	lock.visible = room.has("locked_by_item_id")
	var seal := AshenStyle.picture(body,"seal-"+archetype,"SelectedSeal")
	seal.position = Vector2(w-25*ui_scale,h-42*ui_scale)
	seal.size = Vector2(32,48)*ui_scale
	var hit := Button.new()
	hit.name = "RoomHit"
	hit.tooltip_text = str(room.display_name)
	for state_id in ["normal","hover","pressed","disabled"]: hit.add_theme_stylebox_override(state_id,StyleBoxEmpty.new())
	hit.focus_mode = Control.FOCUS_ALL
	hit.pressed.connect(func() -> void: preview_room(hud,id))
	panel.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

func refresh(hud) -> void:
	super.refresh(hud)
	hud.reset_button.hide()
	if pinned_start!=null: pinned_start.visible = hud._loadout_pending()
	hud.detail_panel.get_node("MarginContainer").add_theme_constant_override("margin_bottom",roundi(62*ui_scale) if hud._loadout_pending() else 0)
	if hud._loadout_pending():
		hud.panel_title.text = "Prepare Expedition"
		hud.loadout_panel.get_child(0).get_child(0).get_child(0).hide()
		hud.loadout_summary_label.text = "Choose supplies for the expedition.\n"+hud._loadout_packing_text(hud.selected_supply_loadout)
		hud.generator_summary_label.tooltip_text = hud._generator_summary_text()
		var profile: Dictionary = hud.dungeon.get("generated_profile",{})
		hud.generator_summary_label.text = "%s · %s locations" % [profile.get("display_name","Old Mine"),hud.dungeon.get("rooms",[]).size()]
		for button: Button in hud.generated_difficulty_buttons: button.get_parent().visible = hud.dungeon_source==hud.DUNGEON_SOURCE_GENERATED
	if light_header!=null: light_header.text = "Light %s/%s" % [hud.run_state.get("light_level",0),hud.run_state.get("max_light_level",4)]
	for id: String in hud.room_nodes:
		var body: Control = hud.room_nodes[id].get_node_or_null("RoomBody")
		if body==null or not body.has_node("Selection"): continue
		body.get_node("Selection").visible = id==preview_room_id
		body.get_node("SelectedSeal").visible = id==preview_room_id
		body.get_node("SelectedSeal").texture = AshenStyle.texture("seal-"+archetype)
		body.get_node("CurrentPin").visible = id==str(hud.run_state.get("current_room_id",""))
		body.get_node("Lock").visible = not hud._room_is_unlocked_or_keyed(hud._rooms_by_id().get(id,{}))
		var hit: Button = hud.room_nodes[id].get_node("RoomHit")
		hit.tooltip_text = hud._room_display_name(id)+" — "+hud._room_state_summary(id)
	for button: Button in hud.generated_difficulty_buttons:
		style_button(button)
		if int(button.text.trim_prefix("D"))==hud.generated_dungeon_difficulty:
			button.add_theme_stylebox_override("normal",AshenStyle.frame("button-primary",12*ui_scale,20))
			button.add_theme_color_override("font_color",AshenStyle.IVORY)

func company_feedback(text: String) -> String:
	return "Company ready. Choose your path." if text.begins_with("Expedition started") else text

func _update_preview(hud) -> void:
	super._update_preview(hud)
	if inspector_art!=null:
		var id := preview_room_id if not preview_room_id.is_empty() else str(hud.run_state.get("current_room_id",""))
		var room: Dictionary = hud._rooms_by_id().get(id,{})
		inspector_art.visible = not hud._loadout_pending() and not room.is_empty()
		if not room.is_empty(): inspector_art.texture = AshenStyle.texture(archetype+"/"+illustration(room,str(hud.dungeon.start_room_id)))
		if flavor!=null:
			flavor.visible = inspector_art.visible
			flavor.text = {"mine":"Old passages run beneath the mountain.","dungeon":"Silent halls lie beneath the old stone.","castle":"Rain gathers between the old flagstones.","forest":"Old tracks vanish beneath the roots."}.get(archetype,"")
		if not room.is_empty():
			var summary: String = hud._content_summary(room)
			preview_label.text = preview_label.text.replace("\n\n"+summary+"\n","\n")
			hud.detail_label.text = hud.detail_label.text.replace("\n\n"+summary,"")
			if destination_state!=null:
				destination_state.text = "Locked" if not hud._room_is_unlocked_or_keyed(room) else hud._room_state_summary(id).capitalize()

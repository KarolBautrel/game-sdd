extends RefCounted
## Battle presentation only. No resolver, resource or turn mutation.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
var side_scroll: ScrollContainer
var side: VBoxContainer
var action_scroll: ScrollContainer
var portrait: TextureRect
var tools_button: Button
var tools_open := false

func setup(hud) -> void:
	var leather := TextureRect.new()
	leather.texture = UI.Assets.texture(UI.ART+"leather.png")
	leather.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leather.stretch_mode = TextureRect.STRETCH_TILE
	leather.modulate = Color(0.38,0.37,0.34)
	leather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(leather)
	hud.move_child(leather,1)
	var root_box: VBoxContainer = hud.get_node("RootMargin/RootVBox")
	root_box.add_theme_constant_override("separation",16)
	var middle := HBoxContainer.new()
	middle.name = "BattleMain"
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation",20)
	root_box.add_child(middle)
	root_box.move_child(middle,1)
	hud.board_viewport.reparent(middle)
	hud.board_viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.board_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hud.board_viewport.clip_contents = true
	side_scroll = ScrollContainer.new()
	side_scroll.name = "BattleInspectorScroll"
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_scroll.custom_minimum_size.x = 500
	middle.add_child(side_scroll)
	side = VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation",16)
	side_scroll.add_child(side)
	hud.overlay_resource_panel.reparent(side)
	hud.overlay_resource_panel.custom_minimum_size = Vector2.ZERO
	hud.overlay_resource_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var resources: VBoxContainer = hud.overlay_resource_panel.get_child(0)
	resources.add_theme_constant_override("separation",8)
	portrait = TextureRect.new()
	portrait.name = "ActiveHeroPortrait"
	portrait.custom_minimum_size = Vector2(128,120)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resources.add_child(portrait)
	resources.move_child(portrait,0)
	for bar: TextureProgressBar in hud.overlay_resource_bars.values():
		bar.custom_minimum_size = Vector2(400,42)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.get_node("AmountLabel").add_theme_font_size_override("font_size",24)
	hud.action_panel.reparent(side)
	hud.action_panel.custom_minimum_size = Vector2.ZERO
	hud.action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.action_panel.get_child(0).add_theme_constant_override("separation",12)
	hud.overlay_log_panel.reparent(side)
	hud.overlay_log_panel.custom_minimum_size = Vector2.ZERO
	hud.overlay_log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var history := VBoxContainer.new()
	history.add_theme_constant_override("separation",12)
	hud.overlay_log_panel.add_child(history)
	hud.overlay_log_label.reparent(history)
	var caption := UI.label(history,"Battle chronicle",28,UI.GOLD)
	history.move_child(caption,0)
	var bottom: HBoxContainer = hud.bottom_hud.get_child(0)
	action_scroll = ScrollContainer.new()
	action_scroll.name = "BattleActionScroll"
	action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom.add_child(action_scroll)
	hud.command_buttons.reparent(action_scroll)
	hud.command_buttons.alignment = BoxContainer.ALIGNMENT_BEGIN
	hud.command_buttons.add_theme_constant_override("separation",10)
	tools_button = UI.button("Tools")
	tools_button.custom_minimum_size.x = 104
	tools_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	tools_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tools_button.tooltip_text = "Show developer actions and encounter picker"
	tools_button.pressed.connect(func() -> void:
		tools_open=not tools_open
		refresh(hud)
	)
	bottom.add_child(tools_button)
	style_hud(hud)
	hud._render_command_buttons()
	refresh(hud)
	hud.resized.connect(func() -> void: _responsive(hud))
	_responsive(hud)
	_settle(hud)

func _settle(hud) -> void:
	await hud.get_tree().process_frame
	await hud.get_tree().process_frame
	if is_instance_valid(hud) and hud.is_inside_tree():
		_responsive(hud)
		hud._resize_board()

func style_hud(hud) -> void:
	hud.theme = hud.panel_skin.popup_theme()
	var margin: MarginContainer = hud.get_node("RootMargin")
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,24)
	hud.encounter_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",18))
	hud.turn_order_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",18))
	hud.overlay_resource_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",18))
	hud.overlay_log_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",18))
	hud.action_panel.add_theme_stylebox_override("panel",UI.paper_box(24))
	hud.bottom_hud.add_theme_stylebox_override("panel",UI.frame("frame_dark",18))
	hud.bottom_hud.custom_minimum_size.y = 204
	hud.bottom_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = hud.get_node("RootMargin/RootVBox/TopHud/EncounterPanel/TopLeft/TitleLabel")
	for label: Label in [title,hud.status_label,hud.turn_order_label,hud.action_title_label,hud.action_detail_label,hud.action_feed_label,hud.overlay_resource_label,hud.overlay_log_label]:
		label.add_theme_font_override("font",UI.body_font())
		label.add_theme_font_size_override("font_size",24)
		label.add_theme_color_override("font_color",UI.TEXT)
		label.remove_theme_color_override("font_shadow_color")
		label.remove_theme_constant_override("shadow_offset_x")
		label.remove_theme_constant_override("shadow_offset_y")
		label.custom_minimum_size.x = 0
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
	for label: Label in [title,hud.action_title_label]:
		label.add_theme_font_override("font",UI.heading_font())
		label.add_theme_font_size_override("font_size",32 if label==hud.action_title_label else 40)
	title.add_theme_color_override("font_color",UI.GOLD)
	for label: Label in [hud.action_title_label,hud.action_detail_label,hud.action_feed_label]: label.add_theme_color_override("font_color",UI.INK)
	hud.overlay_resource_label.add_theme_color_override("font_color",UI.GOLD)
	hud.overlay_resource_label.add_theme_font_size_override("font_size",28)
	for entry in [[title,1],[hud.status_label,1],[hud.turn_order_label,3],[hud.action_title_label,2],[hud.action_detail_label,4],[hud.action_feed_label,3],[hud.overlay_resource_label,1],[hud.overlay_log_label,4]]:
		var label: Label = entry[0]
		label.max_lines_visible = int(entry[1])
		label.custom_minimum_size.y = ceilf(label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))*int(entry[1]))
	hud.turn_order_panel.custom_minimum_size.x = 700

func _responsive(hud) -> void:
	var compact: bool = hud.size.x<1800
	side_scroll.custom_minimum_size.x = 360 if compact else 500
	for bar: TextureProgressBar in hud.overlay_resource_bars.values(): bar.custom_minimum_size.x = 300 if compact else 400
	hud.turn_order_panel.custom_minimum_size.x = 400 if compact else 700
	portrait.custom_minimum_size.y = 72 if hud.size.y<1000 else 120

func decorate_action(hud,button: Button,id: String,slot: int) -> void:
	button.set_meta("action_id",id)
	button.set_meta("action_slot",slot)
	var developer: bool = id in ["enemy_turn","enemy_ai","reset"] or id.begins_with("load_") or id=="full_combat_showcase"
	button.set_meta("developer_action",developer)
	button.custom_minimum_size = Vector2(160,156)
	button.icon = null
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	for state in ["normal","hover","pressed","disabled","focus"]: button.remove_theme_stylebox_override(state)
	if hud.selected_action==id: UI.select_button(button)
	button.add_theme_stylebox_override("focus",UI.focus_box())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side_name in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side_name,12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",4)
	margin.add_child(box)
	var icon := TextureRect.new()
	icon.texture = hud._action_icon_texture(id)
	if id in ["basic_attack","ranged_attack"]: icon.texture=UI.icon("sword" if id=="basic_attack" else "bow")
	icon.custom_minimum_size.y = 46
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var name := UI.label(box,str(hud.ACTION_LABELS.get(id,id)),24,UI.TEXT)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var active: Dictionary=hud._unit_by_id(hud.state.get("turn_state",{}).get("active_unit_id",""))
	var cost := "MP" if id=="move" else ("Finish" if id=="end_turn" else "%s AP" % hud._action_ap_cost(active,id,1))
	var hint := UI.label(box,"[%s]  %s" % [slot,cost] if slot<=9 else cost,24,UI.GOLD)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = "%s [%s]\n%s" % [hud.ACTION_LABELS.get(id,id),slot,cost]

func refresh(hud) -> void:
	if side==null: return
	var active: Dictionary=hud._unit_by_id(hud.state.get("turn_state",{}).get("active_unit_id",""))
	portrait.texture = null
	for hero: Dictionary in Party.default_party():
		if str(hero.combat_unit_id)==str(active.get("id","")): portrait.texture=UI.Assets.texture(hero.portrait_path)
	portrait.visible = portrait.texture!=null
	var order: Array[String] = []
	for id in hud.state.get("turn_state",{}).get("turn_order",[]):
		var unit: Dictionary=hud._unit_by_id(str(id))
		if not unit.is_empty() and int(unit.resources.hp)>0:
			order.append(("> " if str(id)==str(active.get("id","")) else "")+hud._unit_display_name(str(id)))
	hud.turn_order_label.tooltip_text = hud.turn_order_label.text
	hud.turn_order_label.text = "TURN ORDER\n"+"   /   ".join(order)
	for label: Label in [hud.action_title_label,hud.action_detail_label,hud.action_feed_label,hud.overlay_log_label,hud.status_label]: label.tooltip_text=label.text
	for child in hud.command_buttons.get_children():
		if child.is_queued_for_deletion(): continue
		if child is OptionButton or (child is Button and (not child.has_meta("action_id") or bool(child.get_meta("developer_action",false)))):
			child.visible=tools_open or (child is Button and "Return" in child.text)
			if child is Button:
				child.add_theme_font_size_override("font_size",24)
				child.custom_minimum_size=Vector2(164,64)
			if child is OptionButton: child.custom_minimum_size.x=260

func add_gallery_button(hud) -> void:
	var gallery_button := UI.button("Character gallery")
	gallery_button.name = "CharacterGalleryButton"
	gallery_button.pressed.connect(func() -> void:
		if hud.get_node_or_null("OriginalRosterGallery") == null:
			hud.add_child(load("res://scripts/presentation/combat/roster_gallery.gd").new())
	)
	hud.command_buttons.add_child(gallery_button)
	var studies_button := UI.button("Style A/B/C")
	studies_button.name = "CharacterStylePreviewButton"
	studies_button.pressed.connect(func() -> void:
		if hud.get_node_or_null("CharacterStylePreview") == null:
			hud.add_child(load("res://scenes/combat/CharacterStylePreview.tscn").instantiate())
	)
	hud.command_buttons.add_child(studies_button)

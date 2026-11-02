extends Control
signal navigation_requested(id: String)
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const NAV := {"region":["Region","Map","boot"],"town":["Ravenford","Town","tent"],"stash":["Stash & gear","Stash","bag"],"trade":["Trading Post","Trade","sword"],"training":["Training","Train","hourglass"]}
var nav_buttons: Dictionary = {}
var header: HBoxContainer
var footer: PanelContainer
var feedback: Label
var body_scroll: ScrollContainer
var content: VBoxContainer
var rail: VBoxContainer
var rail_scroll: ScrollContainer
var compact_summary: Label
var sidebar: HBoxContainer
var selected_tab := "region"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var background := TextureRect.new()
	background.texture = UI.Assets.texture(UI.ART+"leather.png")
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.modulate = Color(0.38,0.36,0.33)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: outer.add_theme_constant_override("margin_"+edge,24)
	add_child(outer)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	outer.add_child(stack)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation",16)
	stack.add_child(header)
	var nav_panel := PanelContainer.new()
	nav_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",10))
	stack.add_child(nav_panel)
	sidebar = HBoxContainer.new()
	sidebar.add_theme_constant_override("separation",6)
	nav_panel.add_child(sidebar)
	for id: String in NAV:
		var button := UI.button(NAV[id][0])
		button.icon = UI.icon(NAV[id][2])
		button.expand_icon = true
		button.pressed.connect(func() -> void: navigation_requested.emit(id))
		sidebar.add_child(button)
		nav_buttons[id] = button
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation",18)
	stack.add_child(main)
	body_scroll = ScrollContainer.new()
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(body_scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",18)
	body_scroll.add_child(content)
	compact_summary = UI.label(content,"",24,UI.MUTED)
	rail_scroll = ScrollContainer.new()
	rail_scroll.custom_minimum_size.x = 290
	rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(rail_scroll)
	rail = VBoxContainer.new()
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation",14)
	rail_scroll.add_child(rail)
	footer = PanelContainer.new()
	footer.custom_minimum_size.y = 62
	footer.add_theme_stylebox_override("panel",UI.frame("frame_dark",14))
	stack.add_child(footer)
	feedback = UI.label(footer,"",24,UI.GOLD)
	feedback.max_lines_visible = 2
	feedback.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	resized.connect(_fit)
	_fit()

func configure(title: String,location: String,counters: Dictionary,selected: String,town: bool,service: bool) -> void:
	selected_tab = selected
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	UI.label(heading,title,38,UI.GOLD)
	UI.label(heading,location,24,UI.MUTED)
	for key: String in counters:
		var chip := PanelContainer.new()
		chip.custom_minimum_size.x = 142
		chip.add_theme_stylebox_override("panel",UI.frame("frame_dark",14))
		header.add_child(chip)
		var body := VBoxContainer.new()
		chip.add_child(body)
		UI.label(body,"XP" if key == "Available XP" else key,24,UI.MUTED)
		UI.label(body,str(counters[key]),28,UI.GOLD)
	for id: String in nav_buttons:
		var button: Button = nav_buttons[id]
		button.disabled = (id == "town" and not town) or (id in ["trade","training"] and not service)
		if id == selected: UI.select_button(button)
	_fit()
	UI.focus_later(nav_buttons[selected])

func _fit() -> void:
	if sidebar == null: return
	var compact := size.x < 1500
	rail_scroll.visible = not compact and selected_tab == "region"
	compact_summary.visible = compact and selected_tab == "region"
	for id: String in nav_buttons:
		nav_buttons[id].text = NAV[id][1] if compact else NAV[id][0]

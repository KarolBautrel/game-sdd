extends RefCounted
## Shared dark-fantasy art family; no game-state decisions.
const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const BASE_THEME := preload("res://resources/ui/campaign_theme.tres")
const BODY_FONT := preload("res://assets/ui/fonts/SourceSans3-Semibold.ttf")
const HEADING_FONT := preload("res://assets/ui/fonts/Cinzel.ttf")
const ART := "res://assets/ui/campaign/"
const BG := Color("100f0e")
const PANEL := Color("201c18")
const RAISED := Color("30271e")
const EDGE := Color("79603c")
const GOLD := Color("d9b773")
const TEXT := Color("f8eedc")
const MUTED := Color("c9bba1")
const INK := Color("30231a")
const INK_MUTED := Color("66503a")
static func body_font() -> Font:
	return BODY_FONT

static func heading_font() -> Font: return HEADING_FONT

static func frame(file: String,padding: int = 24,tint: Color = Color.WHITE) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = Assets.texture(ART+("button" if file == "frame_metal" else file)+".png")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: result.set_texture_margin(side,16 if file == "frame_metal" else 36)
	result.set_content_margin_all(padding)
	result.modulate_color = tint
	result.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	result.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return result

static func hero_frame() -> StyleBox: return frame("frame_dark",28)
static func paper_box(padding: int = 28) -> StyleBoxTexture: return frame("frame_paper",padding)

static func box(color: Color = PANEL,border: Color = EDGE,padding: int = 20) -> StyleBox:
	if color == Color.TRANSPARENT or color == GOLD or padding == 0:
		var flat := PixelSkin.flat_frame(color,border,1,0)
		flat.set_content_margin_all(padding)
		return flat
	var tint := Color(1.2,1.12,0.95) if border == GOLD else Color(0.85,0.83,0.80)
	return frame("frame_dark" if color == PANEL else "frame_metal",padding,tint)

static func focus_box() -> StyleBoxFlat:
	var focus := PixelSkin.flat_frame(Color.TRANSPARENT,Color("f4d792"),2,1)
	focus.set_content_margin_all(0)
	focus.expand_margin_left = 3
	focus.expand_margin_top = 3
	focus.expand_margin_right = 3
	focus.expand_margin_bottom = 3
	return focus

static func theme() -> Theme:
	var result: Theme = BASE_THEME.duplicate(true)
	result.default_font = body_font()
	result.default_font_size = 26
	for type in ["Label","Button","OptionButton","CheckButton"]:
		result.set_color("font_color",type,TEXT)
	for type in ["Button","OptionButton"]:
		result.set_color("font_disabled_color",type,Color("8b8273"))
		result.set_stylebox("normal",type,frame("frame_metal",18,Color(0.78,0.75,0.70)))
		result.set_stylebox("hover",type,frame("frame_metal",18,Color(1.3,1.18,0.92)))
		result.set_stylebox("pressed",type,frame("frame_metal",18,Color(0.88,0.76,0.55)))
		result.set_stylebox("disabled",type,frame("frame_metal",18,Color(0.44,0.44,0.43)))
		result.set_stylebox("focus",type,focus_box())
		result.set_constant("icon_max_width",type,34)
	result.set_stylebox("panel","PanelContainer",hero_frame())
	result.set_stylebox("panel","PopupMenu",hero_frame())
	result.set_color("font_color","PopupMenu",TEXT)
	result.set_stylebox("hover","PopupMenu",frame("frame_metal"))
	result.set_stylebox("panel","TooltipPanel",hero_frame())
	result.set_color("font_color","TooltipLabel",TEXT)
	result.set_stylebox("scroll","VScrollBar",PixelSkin.flat_frame(BG,BG,0,0))
	result.set_stylebox("grabber","VScrollBar",PixelSkin.flat_frame(EDGE,EDGE,0,0))
	result.set_stylebox("grabber_highlight","VScrollBar",PixelSkin.flat_frame(GOLD,GOLD,0,0))
	return result

static func label(parent: Node,value: String,size: int = 26,color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font",HEADING_FONT if size >= 28 else body_font())
	result.add_theme_font_size_override("font_size",maxi(24,size))
	result.add_theme_color_override("font_color",color)
	parent.add_child(result)
	return result

static func rule(parent: Node) -> TextureRect:
	var result := TextureRect.new()
	result.texture = Assets.texture(ART+"divider.png")
	result.custom_minimum_size.y = 12
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

static func card(parent: Node,title: String,subtitle: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",hero_frame())
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",14)
	panel.add_child(column)
	if not title.is_empty():
		label(column,title,28,GOLD)
		rule(column)
	if not subtitle.is_empty(): label(column,subtitle,24,MUTED)
	return column

static func button(text: String,primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 68
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.focus_mode = Control.FOCUS_ALL
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.tooltip_text = text
	result.add_theme_font_size_override("font_size",26)
	if primary: select_button(result)
	result.mouse_entered.connect(func() -> void: _hover(result,Color(1.08,1.06,1.02)))
	result.mouse_exited.connect(func() -> void: _hover(result,Color.WHITE))
	return result

static func select_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal",frame("frame_metal",18,Color(1.2,1.02,0.72)))
	button.add_theme_color_override("font_color",Color("ffe1a0"))

static func focus_later(control: Control) -> void:
	var request := func() -> void:
		if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree(): control.grab_focus()
	request.call_deferred()

static func _hover(button: Button,color: Color) -> void:
	if not button.is_inside_tree() or button.disabled: return
	var previous: Variant = button.get_meta("campaign_hover") if button.has_meta("campaign_hover") else null
	if previous is Tween and previous.is_valid(): previous.kill()
	var tween := button.create_tween()
	button.set_meta("campaign_hover",tween)
	tween.tween_property(button,"modulate",color,0.12)

static func icon(name: String) -> Texture2D:
	var objects := {"boot":"brass_route_marker","bag":"legacy_unknown","sword":"hero_sword","bow":"hero_bow","shield":"salvaged_shield","hourglass":"old_mine_scrip"}
	if objects.has(name): return Assets.texture(ART+"items/"+str(objects[name])+".png")
	var path := ART+"glyphs/"+name+".png"
	if ResourceLoader.exists(path): return Assets.texture(path)
	return Assets.texture("res://assets/ui/combat/processed/icons/inner/icon_%s.png" % name)

static func portrait(parent: Node,path: String,side: int = 80) -> TextureRect:
	var result := TextureRect.new()
	result.texture = Assets.texture(path)
	result.custom_minimum_size = Vector2(side,side)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

extends PanelContainer

const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
var maximum_hp := 1
var hp_label: Label:
	get: return find_child("HP",true,false) as Label
var hp_bar: ProgressBar:
	get: return find_child("Bar",true,false) as ProgressBar


func configure(hero: Dictionary, current_hp: int, accent: Color, frame: StyleBox) -> void:
	add_theme_stylebox_override("panel", frame)
	(get_node("Margin/Content/Portrait") as TextureRect).texture = Assets.texture(str(hero.get("portrait_path", "")))
	(get_node("Margin/Content/Name") as Label).text = str(hero.get("display_name", "Hero"))
	var stats: Dictionary = hero.get("stats", {})
	maximum_hp = maxi(1, int(stats.get("max_hp", 1)))
	hp_label.tooltip_text = "%s | AP %s | MP %s" % [hero.get("class_name", "Hero"), stats.get("max_ap", 0), stats.get("move_points", 0)]
	for style_id in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = accent if style_id == "fill" else Color(0.08, 0.06, 0.04)
		hp_bar.add_theme_stylebox_override(style_id, style)
	set_hp(current_hp)


func set_hp(current_hp: int) -> void:
	var visible_hp := clampi(current_hp, 0, maximum_hp)
	hp_label.text = "HP %s/%s" % [visible_hp, maximum_hp]
	hp_bar.max_value = maximum_hp
	hp_bar.value = visible_hp


func use_expedition_layout(compact: bool) -> void:
	var margin := get_node("Margin") as MarginContainer
	var row := margin.get_node_or_null("PortraitRow") as HBoxContainer
	if row == null:
		var content := margin.get_node("Content") as VBoxContainer
		var portrait := content.get_node("Portrait") as TextureRect
		row = HBoxContainer.new()
		row.name = "PortraitRow"
		margin.add_child(row)
		portrait.reparent(row)
		content.reparent(row)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		content.add_theme_constant_override("separation",6)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		for label: Label in [content.get_node("Name"),hp_label]:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.add_theme_font_size_override("font_size",24)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("a43f32")
		hp_bar.add_theme_stylebox_override("fill",fill)
		hp_bar.custom_minimum_size = Vector2(124,14)
	row.add_theme_constant_override("separation",12)
	for side in ["left","top","right","bottom"]:
		margin.add_theme_constant_override("margin_"+side,0)
	var side := 80.0 if compact else 112.0
	(row.get_node("Portrait") as TextureRect).custom_minimum_size = Vector2(side,side)
	custom_minimum_size = Vector2(244 if compact else 296,side+24)

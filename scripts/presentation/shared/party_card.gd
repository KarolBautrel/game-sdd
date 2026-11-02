extends PanelContainer

const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
var maximum_hp := 1
var hp_label: Label:
	get: return get_node("Margin/Content/HP") as Label
var hp_bar: ProgressBar:
	get: return get_node("Margin/Content/Bar") as ProgressBar


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

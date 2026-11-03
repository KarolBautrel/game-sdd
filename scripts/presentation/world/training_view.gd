extends VBoxContainer
signal train_requested(hero_id: String)
const Advancement := preload("res://scripts/domain/party_advancement.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Columns := preload("res://scripts/presentation/world/campaign_columns.gd")
var train_buttons: Dictionary = {}
var xp_bars: Dictionary = {}
var next_stats: Dictionary = {}

func configure(advancement: Dictionary,earned_xp: int,available: bool) -> void:
	add_theme_constant_override("separation",16)
	var free := earned_xp - Advancement.allocated(advancement)
	UI.label(self,"Develop your company",30,UI.GOLD)
	UI.label(self,"%s XP available  /  %s earned  /  %s allocated" % [free,earned_xp,earned_xp-free],21,UI.MUTED)
	var columns := Columns.new()
	columns.collapse_width = 1400
	add_child(columns)
	for hero: Dictionary in Party.default_party():
		var id: String = hero.combat_unit_id
		var level := int(advancement[id])
		var stats := Advancement.stats(id,level)
		var tier := Advancement.next_tier(advancement,id)
		var card := UI.card(columns,hero.display_name,"%s  /  Level %s" % [hero.class_name,level])
		card.get_parent().add_theme_stylebox_override("panel",UI.hero_frame())
		var hero_row := HBoxContainer.new()
		hero_row.add_theme_constant_override("separation",18)
		card.add_child(hero_row)
		UI.portrait(hero_row,hero.portrait_path,192)
		var stats_grid := GridContainer.new()
		stats_grid.columns = 3
		stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_grid.add_theme_constant_override("h_separation",18)
		hero_row.add_child(stats_grid)
		var after := stats if tier.is_empty() else Advancement.stats(id,int(tier.level))
		next_stats[id] = after.duplicate(true)
		for key in ["strength","defense","accuracy"]:
			var stat_name := UI.label(stats_grid,str(key).capitalize(),24,UI.MUTED)
			stat_name.custom_minimum_size.x = 140
			stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var value := UI.label(stats_grid,str(stats[key]),24)
			value.custom_minimum_size.x = 44
			var delta := int(after[key])-int(stats[key])
			var difference := UI.label(stats_grid,"%+d next" % delta if delta != 0 else "-",24,Color("a9c899") if delta > 0 else UI.MUTED)
			difference.custom_minimum_size.x = 100
			difference.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var track := HBoxContainer.new()
		track.add_theme_constant_override("separation",6)
		card.add_child(track)
		for row: Dictionary in Advancement.levels():
			var step := UI.card(track,"","")
			step.get_parent().add_theme_stylebox_override("panel",UI.box(UI.RAISED,UI.GOLD if int(row.level) <= level else UI.EDGE,10))
			UI.label(step,"Lv %s" % int(row.level),18,UI.GOLD if int(row.level) <= level else UI.MUTED)
			UI.label(step,"Start" if int(row.cost) == 0 else "%s XP" % int(row.cost),17,UI.MUTED)
		var progress := ProgressBar.new()
		progress.custom_minimum_size.y = 12
		progress.show_percentage = false
		progress.max_value = maxi(1,int(tier.get("cost",1)))
		progress.value = min(free,int(progress.max_value))
		progress.add_theme_stylebox_override("background",UI.box(UI.BG,UI.EDGE,0))
		progress.add_theme_stylebox_override("fill",UI.box(UI.GOLD,UI.GOLD,0))
		card.add_child(progress)
		xp_bars[id] = progress
		var reason := "Current training cap reached." if tier.is_empty() else ("Training unlocks in Ravenford after your expedition/event." if not available else ("Need %s more XP." % (int(tier.cost)-free) if free < int(tier.cost) else "Ready to advance. Wounds are preserved."))
		UI.label(card,reason,19,UI.MUTED)
		var button := UI.button("Training complete" if tier.is_empty() else "Advance %s  /  %s XP" % [hero.display_name,int(tier.cost)],true)
		button.disabled = not available or tier.is_empty() or free < int(tier.get("cost",0))
		button.tooltip_text = reason
		button.pressed.connect(func() -> void:
			if not button.disabled: train_requested.emit(id)
		)
		card.add_child(button)
		train_buttons[id] = button

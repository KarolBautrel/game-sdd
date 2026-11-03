extends VBoxContainer
signal equip_requested(hero_id: String,slot: String,item_id: Variant)
signal hero_selected(hero_id: String)
signal item_focused(item_id: String)
signal slot_selected(slot: String)
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Items := preload("res://scripts/domain/item_catalog.gd")
const Gear := preload("res://scripts/domain/campaign_equipment.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Presentation := preload("res://scripts/presentation/world/item_presentation.gd")
const SLOT_NAMES := {"main_hand":"Weapon","off_hand":"Off hand","armor":"Armor","boots":"Boots","helmet":"Helmet"}
const EMPTY_ICONS := {"main_hand":"hero_sword","off_hand":"salvaged_shield","armor":"patched_leather","boots":"leather_boots","helmet":"closed_helm"}
var hero_buttons: Dictionary = {}
var slot_buttons: Dictionary = {}
var equip_button: Button
var unequip_button: Button
var detail: Label
var selected_hero := "unit_player_001"
var selected_item := ""
var selected_slot := "main_hand"
var rejection_reason := ""
var layout: GridContainer
var inspector: VBoxContainer
var hero_portrait: TextureRect
var item_art: TextureRect
var _inventory: Control
var _owned: Array = []
var _equipment: Dictionary = {}
var _details: Dictionary = {}
var _locked := false
var ownership_label: Label

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_fit)
	_fit()
	if layout!=null:_render()

func configure(owned: Array,equipment: Dictionary,locked: bool,selection: Dictionary = {},details: Dictionary = {}) -> void:
	_owned = owned.duplicate(true)
	_equipment = Gear.normalized(equipment)
	_details = details.duplicate(true)
	_locked = locked
	selected_hero = str(selection.get("hero",selected_hero))
	if not equipment.has(selected_hero): selected_hero = "unit_player_001"
	selected_slot = str(selection.get("slot","main_hand"))
	if selected_slot not in Gear.SLOTS: selected_slot = "main_hand"
	selected_item = str(selection.get("item",""))
	if not owned.has(selected_item): selected_item = ""
	_render()

func attach_inventory(view: Control) -> void:
	_inventory = view
	_render()

func select_item(id: String) -> void:
	selected_item = id if _owned.has(id) else ""
	var slot := str(Items.item(selected_item).get("combat_profile",{}).get("slot",""))
	if slot in Gear.SLOTS: selected_slot = slot
	_render()

func _render() -> void:
	if is_instance_valid(_inventory) and _inventory.get_parent() != null:
		_inventory.get_parent().remove_child(_inventory)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	hero_buttons.clear()
	slot_buttons.clear()
	ownership_label=null
	layout = GridContainer.new()
	layout.add_theme_constant_override("h_separation",18)
	layout.add_theme_constant_override("v_separation",18)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(layout)
	var loadout := UI.card(layout,"Company")
	loadout.get_parent().size_flags_stretch_ratio = 0.88
	var heroes := HBoxContainer.new()
	heroes.add_theme_constant_override("separation",8)
	loadout.add_child(heroes)
	for hero: Dictionary in Party.default_party():
		var id: String = hero.combat_unit_id
		var button := UI.button(hero.display_name,id == selected_hero)
		button.icon = UI.Assets.texture(hero.portrait_path)
		button.add_theme_constant_override("icon_max_width",42)
		heroes.add_child(button)
		button.pressed.connect(func() -> void:
			selected_hero = id
			_render()
			UI.focus_later(hero_buttons[id])
			hero_selected.emit(id)
		)
		hero_buttons[id] = button
	var hero := Party.hero_for_combat_unit(selected_hero)
	var info: Dictionary = _details.get(selected_hero,{"level":1,"hp":hero.stats.max_hp,"stats":hero.stats})
	UI.label(loadout,hero.display_name,38,UI.GOLD)
	UI.label(loadout,"%s  /  Level %s" % [hero.class_name,info.level],24,UI.MUTED)
	hero_portrait = UI.portrait(loadout,hero.portrait_path,200)
	hero_portrait.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_portrait.custom_minimum_size.y=200
	var health := ProgressBar.new()
	health.custom_minimum_size.y = 14
	health.max_value = hero.stats.max_hp
	health.value = info.hp
	health.show_percentage = false
	health.add_theme_stylebox_override("background",UI.PixelSkin.flat_frame(UI.BG,UI.EDGE,1,0))
	health.add_theme_stylebox_override("fill",UI.PixelSkin.flat_frame(Color("9b3628"),Color("b9543c"),1,0))
	loadout.add_child(health)
	UI.label(loadout,"HP %s/%s   ·   STR %s   ·   DEF %s" % [info.hp,hero.stats.max_hp,info.stats.strength,info.stats.defense],24)
	UI.rule(loadout)
	for slot: String in Gear.SLOTS:
		var worn: Variant = _equipment[selected_hero][slot]
		var text := "%s  /  %s" % [SLOT_NAMES[slot],"Empty" if worn == null else Items.item(worn).name]
		var button := UI.button(text,slot == selected_slot)
		button.add_theme_font_size_override("font_size",24)
		button.icon = Presentation.icon_for(Items.item(worn)) if worn != null else Presentation.icon_for(Items.item(EMPTY_ICONS[slot]))
		button.add_theme_constant_override("icon_max_width",44)
		loadout.add_child(button)
		button.pressed.connect(func() -> void:
			selected_slot = slot
			selected_item = "" if worn == null else str(worn)
			_render()
			UI.focus_later(slot_buttons[slot])
			slot_selected.emit(slot)
			item_focused.emit(selected_item)
		)
		slot_buttons[slot] = button
	if is_instance_valid(_inventory):
		var pack := UI.card(layout,"Company inventory")
		pack.get_parent().size_flags_stretch_ratio = 1.25
		pack.add_child(_inventory)
	inspector = UI.card(layout,"")
	inspector.get_parent().add_theme_stylebox_override("panel",UI.paper_box())
	inspector.add_theme_constant_override("separation",10)
	var item := Items.item(selected_item)
	var title := UI.label(inspector,"Select an item" if selected_item.is_empty() else item.name,30,UI.INK)
	title.max_lines_visible = 2
	title.tooltip_text = title.text
	UI.label(inspector,"Inspect your company's equipment" if selected_item.is_empty() else str(item.category).capitalize(),24,UI.INK_MUTED)
	item_art = UI.portrait(inspector,Presentation.icon_for(item).resource_path,144)
	item_art.name = "SelectedItemArt"
	UI.rule(inspector)
	if not selected_item.is_empty():
		detail = UI.label(inspector,item.description,24,UI.INK)
		detail.max_lines_visible = 3
		detail.tooltip_text = item.description
		UI.label(inspector,"Owned %s  ·  Value %sg" % [_owned.count(selected_item),int(item.value)],24,UI.INK_MUTED)
		ownership_label = UI.label(inspector,assignment_summary(selected_item),24,UI.INK_MUTED)
		ownership_label.name = "OwnershipSummary"
		ownership_label.max_lines_visible = 3
		ownership_label.tooltip_text = ownership_label.text
		var current: Variant = _equipment[selected_hero][selected_slot]
		UI.label(inspector,"Worn: %s" % ("Empty" if current == null else Items.item(current).name),24,UI.INK_MUTED).max_lines_visible = 1
		for comparison: Dictionary in Presentation.comparison(item,{} if current == null else Items.item(current)):
			UI.label(inspector,"%s   %s → %s   (%+d)" % [comparison.label,comparison.before,comparison.after,comparison.delta],24,Color("2d5832") if comparison.delta > 0 else (Color("8a3226") if comparison.delta < 0 else UI.INK_MUTED))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	inspector.add_child(actions)
	equip_button = UI.button("Equip selected",true)
	unequip_button = UI.button("Unequip %s" % SLOT_NAMES[selected_slot])
	actions.add_child(equip_button)
	actions.add_child(unequip_button)
	rejection_reason = _reason(item)
	equip_button.disabled = not rejection_reason.is_empty()
	unequip_button.disabled = _locked or _equipment[selected_hero][selected_slot] == null
	var reason := UI.label(inspector,rejection_reason if not rejection_reason.is_empty() else "Ready to equip. Wounds are preserved.",24,UI.INK_MUTED)
	reason.max_lines_visible = 2
	reason.tooltip_text = reason.text
	equip_button.pressed.connect(func() -> void:
		if not equip_button.disabled: equip_requested.emit(selected_hero,selected_slot,selected_item)
	)
	unequip_button.pressed.connect(func() -> void:
		if not unequip_button.disabled: equip_requested.emit(selected_hero,selected_slot,null)
	)
	_fit()

func _fit() -> void:
	if layout == null: return
	layout.columns = 3 if size.x >= 1700 else 1
	if hero_portrait != null: hero_portrait.custom_minimum_size.y = 200
	if item_art != null: item_art.custom_minimum_size.y = 250 if get_viewport_rect().size.y >= 1200 else 128
	for panel: Control in layout.get_children():
		panel.custom_minimum_size.x = 400 if layout.columns == 3 else 0
	if layout.columns == 3 and layout.get_child_count() == 3:
		layout.get_child(1).custom_minimum_size.x = 500

func _reason(item: Dictionary) -> String:
	if _locked: return "Equipment is locked until your expedition or road event is resolved."
	if selected_item.is_empty(): return "Choose an inventory item or a worn slot to inspect."
	if item.get("combat_profile",{}).get("slot") != selected_slot: return "This item cannot be equipped in this slot."
	if _equipment[selected_hero][selected_slot] == selected_item: return "Already equipped."
	if _owned.count(selected_item)-Gear.assigned(_equipment,selected_item)<=0:
		return "All copies are equipped: %s. Unequip a copy first." % ", ".join(assigned_to(selected_item))
	var profile: Dictionary=item.get("combat_profile",{})
	var hands: Dictionary=_equipment[selected_hero]
	if selected_slot=="main_hand" and bool(profile.get("two_handed",false)) and hands.off_hand!=null:
		return "Two-handed weapon: unequip Off hand first."
	if selected_slot=="off_hand" and hands.main_hand!=null and bool(Items.item(hands.main_hand).get("combat_profile",{}).get("two_handed",false)):
		return "Your two-handed weapon occupies both hands. Unequip Weapon first."
	var next := _equipment.duplicate(true)
	next[selected_hero][selected_slot] = selected_item
	if not Gear.valid(next,_owned): return "This equipment combination is unavailable."
	return ""

func assigned_to(id: String) -> PackedStringArray:
	var result: PackedStringArray=[]
	for hero: Dictionary in Party.default_party():
		for slot: String in Gear.SLOTS:
			if _equipment.get(hero.combat_unit_id,{}).get(slot)==id:
				result.append("%s (%s)" % [hero.display_name,SLOT_NAMES[slot]])
	return result

func assignment_summary(id: String) -> String:
	var worn: int=Gear.assigned(_equipment,id)
	var text: String="Available %s  /  Equipped %s" % [maxi(0,_owned.count(id)-worn),worn]
	var names:=assigned_to(id)
	if not names.is_empty(): text+="\nWorn by "+", ".join(names)
	return text

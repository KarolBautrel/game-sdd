extends Control
signal scene_requested(path: String)
const World := preload("res://scripts/domain/living_world.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Map := preload("res://scripts/presentation/world/living_map.gd")
@export var qa_memory := false
var speed:=0
var accumulated:=0.0
var selected_site: String="town_ravenford"
var selected_actor: String=""
var buttons: Dictionary={}
var contract_nodes: Dictionary={}
var map: Control
var header_label: Label
var region_title: Label
var stock_label: Label
var place_label: Label
var details_label: Label
var faction_label: Label
var journal_label: Label
var footer: Label
var tabs: TabContainer
var event_panel: PanelContainer
var event_label: Label
var body: HBoxContainer
var side: PanelContainer
var compact:=false
func _campaign() -> Node: return get_node("/root/CampaignSession")
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	compact=get_viewport_rect().size.x<1500
	theme=UI.theme()
	var campaign:=_campaign()
	if qa_memory or (DisplayServer.get_name()=="headless" and not campaign.loaded):
		campaign.load_profile("",true)
		campaign.enable_living_world()
	elif not campaign.living_active():
		if campaign.loaded and campaign.memory_only: campaign.enable_living_world()
		else: preload("res://scripts/qa/living_world_pilot.gd").open(campaign)
	_build()
	if not campaign.living_active():
		footer.text=campaign.last_feedback
		set_process(false)
		return
	selected_site=World.current_site(campaign.state.living_world)
	if selected_site.is_empty(): selected_site=str(campaign.state.living_world.party.goal)
	if selected_site.is_empty(): selected_site="town_ravenford"
	_refresh()
	UI.focus_later(buttons.pause)
func _label(parent: Node,text: String,font_size: int = 24,color: Color = UI.TEXT) -> Label:
	var label:=UI.label(parent,text,font_size,color)
	label.add_theme_font_size_override("font_size",mini(font_size,20) if compact else font_size)
	return label
func _button(parent: Node,id: String,text: String,callback: Callable) -> Button:
	var button:=UI.button(text)
	button.custom_minimum_size.y=44 if compact else 58
	button.add_theme_font_size_override("font_size",19 if compact else 24)
	if compact:
		for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,UI.frame("frame_metal",8))
	button.pressed.connect(callback)
	parent.add_child(button);buttons[id]=button
	return button
func _scroll_tab(title: String) -> VBoxContainer:
	var scroll:=ScrollContainer.new()
	scroll.name=title
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column:=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",14)
	scroll.add_child(column)
	return column
func _build() -> void:
	var background:=TextureRect.new()
	background.texture=UI.Assets.texture(UI.ART+"leather.png")
	background.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	background.stretch_mode=TextureRect.STRETCH_TILE
	background.modulate=Color(.38,.36,.33)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,20)
	add_child(margin)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	margin.add_child(stack)
	var heading:=HBoxContainer.new()
	stack.add_child(heading)
	var title:=VBoxContainer.new()
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	region_title=_label(title,"The Living Marches",36,UI.GOLD)
	header_label=_label(title,"",22,UI.MUTED)
	stock_label=_label(heading,"",22,UI.GOLD)
	stock_label.custom_minimum_size.x=300 if compact else 380
	stock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var toolbar:=HBoxContainer.new()
	toolbar.add_theme_constant_override("separation",8)
	stack.add_child(toolbar)
	for rate in [0,1,2,4]:
		var id: String="pause" if rate==0 else "speed_%s" % rate
		var button:=_button(toolbar,id,"Pause [Space]" if rate==0 else "%sx" % rate,func() -> void: set_speed(rate))
		button.toggle_mode=true
		button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size.x=(176 if compact else 232) if rate==0 else 64
	_button(toolbar,"camp","Make camp",_camp)
	_button(toolbar,"stash","Company & gear",func() -> void: _open_tab("stash"))
	_button(toolbar,"exit","Back to atlas",_exit_pilot)
	var terrain_button:=_button(toolbar,"terrain","Terrain",func() -> void:
		set_speed(0)
		preload("res://scripts/domain/terrain_navigation.gd").reload()
		_go_scene("res://scenes/world/TerrainEditor.tscn"))
	terrain_button.tooltip_text="Paint walkable terrain, rivers, mountain slopes and crossings."
	_button(toolbar,"regions","Regions",func() -> void: set_speed(0);_go_scene("res://scenes/world/RegionFoundry.tscn"))
	body=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",16)
	stack.add_child(body)
	var map_panel:=PanelContainer.new()
	map_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",12))
	map_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(map_panel)
	var map_column:=VBoxContainer.new()
	map_panel.add_child(map_column)
	map=Map.new()
	map.region_state=_campaign().state.get("living_world",{})
	map.name="LivingMap"
	map.size_flags_vertical=Control.SIZE_EXPAND_FILL
	map_column.add_child(map)
	map.course_requested.connect(_course)
	map.actor_selected.connect(_inspect_actor)
	_label(map_column,"Click land or a location to travel. C caravan / L League / I Iron March / R raiders.",18,UI.MUTED)
	side=PanelContainer.new()
	side.custom_minimum_size.x=344 if compact else 480
	side.add_theme_stylebox_override("panel",UI.frame("frame_dark",12))
	body.add_child(side)
	tabs=TabContainer.new()
	tabs.add_theme_font_size_override("font_size",18 if compact else 24)
	tabs.get_tab_bar().add_theme_font_size_override("font_size",18 if compact else 24)
	tabs.add_theme_stylebox_override("panel",UI.frame("frame_dark",8))
	var tab_bar:=tabs.get_tab_bar()
	tab_bar.add_theme_stylebox_override("tab_selected",UI.frame("frame_metal",10,Color(1.2,1.02,.72)))
	tab_bar.add_theme_stylebox_override("tab_unselected",UI.frame("frame_dark",10))
	tab_bar.add_theme_stylebox_override("tab_hovered",UI.frame("frame_metal",10))
	tab_bar.add_theme_color_override("font_selected_color",UI.GOLD)
	for state in ["tab_selected","tab_unselected","tab_hovered"]:
		tabs.add_theme_stylebox_override(state,tab_bar.get_theme_stylebox(state))
	tabs.add_theme_color_override("font_selected_color",UI.GOLD)
	side.add_child(tabs)
	var location:=_scroll_tab("Location")
	event_panel=PanelContainer.new()
	event_panel.add_theme_stylebox_override("panel",UI.box())
	location.add_child(event_panel)
	var event_column:=VBoxContainer.new()
	event_panel.add_child(event_column)
	event_label=_label(event_column,"",22,UI.GOLD)
	_button(event_column,"event_pay","Pay the road toll / 5g",func() -> void: _act(func() -> bool: return _campaign().choose_road_event("pay")))
	_button(event_column,"event_fight","Fight / resume encounter",_fight)
	place_label=_label(location,"",28,UI.GOLD)
	details_label=_label(location,"",22)
	_button(location,"food","Buy provisions",func() -> void: _act(func() -> bool: return _campaign().purchase("food")))
	_button(location,"inn","Rest at the inn / 5g",func() -> void: _act(func() -> bool: return _campaign().recover()))
	_button(location,"trade","Trading post",func() -> void: _open_tab("trade"))
	_button(location,"training","Training grounds",func() -> void: _open_tab("training"))
	_button(location,"prepare","Prepare Old Mine expedition",_prepare)
	_button(location,"resume","Resume saved expedition",_resume)
	UI.rule(location)
	faction_label=_label(location,"",21,UI.MUTED)
	var contracts:=_scroll_tab("Contracts")
	_label(contracts,"Work follows the state of the region. Accept and report at the issuing town.",20,UI.MUTED)
	for entry: Dictionary in World.definition().contracts:
		var id: String=entry.id
		var card:=UI.card(contracts,"")
		var name:=_label(card,str(entry.name),25,UI.GOLD)
		var status:=_label(card,"",20,UI.MUTED)
		_label(card,str(entry.description),21)
		_label(card,"Issuer: %s\nReward: %dg / %d XP" % [World.site(entry.issuer,_campaign().state.living_world).name,int(entry.gold),int(entry.xp)],20,UI.GOLD)
		var accept:=_button(card,"accept_"+id,"Accept contract",func() -> void: _act(func() -> bool: return _campaign().accept_living_contract(id)))
		var report:=_button(card,"report_"+id,"Report / collect payment",func() -> void: _act(func() -> bool: return _campaign().report_living_contract(id)))
		contract_nodes[id]={"panel":card.get_parent(),"name":name,"status":status,"accept":accept,"report":report}
	var chronicle:=_scroll_tab("Chronicle")
	journal_label=_label(chronicle,"",21)
	var footer_panel:=PanelContainer.new()
	footer_panel.custom_minimum_size.y=44
	footer_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",10))
	stack.add_child(footer_panel)
	footer=_label(footer_panel,"",20,UI.GOLD)
	footer.max_lines_visible=2
	footer.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	tabs.tab_changed.connect(func(index: int) -> void:
		if index==1: set_speed(0)
	)
func clock(tick: int) -> String:
	var hours:=tick/4+8
	return "Day %s %02d:%02d" % [hours/24+1,hours%24,(tick%4)*15]
func _refresh(world_tick: bool = false) -> void:
	var campaign:=_campaign()
	if not campaign.living_active(): return
	var profile: Dictionary=campaign.state
	var state: Dictionary=profile.living_world
	var current:=World.current_site(state)
	var locked: bool=not profile.active_run.is_empty() or not profile.world.pending_event.is_empty()
	var where: String=str(World.site(current,state).get("name","On the road"))
	region_title.text=str(state.geography.name) if state.has("geography") else "The Living Marches"
	header_label.text="%s / %s / %s" % [where,clock(int(state.tick)),"Paused" if speed==0 else "%sx time" % speed]
	if state.has("geography"): header_label.text+=" / Seed %d" % int(state.geography.seed)
	stock_label.text="%dg   |   Food %d\nFatigue %d/100" % [int(profile.gold),int(profile.supplies.food),int(state.party.fatigue)]
	for rate in [0,1,2,4]: buttons["pause" if rate==0 else "speed_%s" % rate].set_pressed_no_signal(speed==rate)
	buttons.camp.text="Break camp" if state.party.camping else "Make camp"
	buttons.camp.disabled=locked
	buttons.stash.disabled=not profile.world.pending_event.is_empty()
	buttons.terrain.disabled=state.has("geography")
	buttons.terrain.tooltip_text="Generated geography is fixed for this campaign. Use Regions to select another." if state.has("geography") else "Paint the authored Marches terrain."
	map.selected_site=selected_site
	map.update_state(profile,.6/maxi(1,speed),campaign.living_motion if world_tick else {})
	var entry:=World.site(selected_site,state)
	place_label.text=str(entry.get("name","The Marches"))
	var lines: Array[String]=[]
	if entry.get("kind","")=="town":
		var town: Dictionary=state.settlements[selected_site]
		lines.append("%s\nSupply %d/100 / Security %d/100" % [str(entry.owner).replace("_"," ").capitalize(),int(town.supply),int(town.security)])
		lines.append("Company is here." if current==selected_site else "Travel here to use settlement services.")
	elif selected_site=="dungeon_old_mine": lines.append("Raiders occupy the mine and threaten ore deliveries." if state.mine.status=="occupied" else "Mine restored. Raiders have departed and deliveries can resume.")
	else: lines.append("A known landmark. Visit High Pass for border reconnaissance; the abbey marks the forest road.")
	if selected_actor!="":
		for actor: Dictionary in state.actors:
			if actor.id==selected_actor: lines.append("\n%s / %s\nCargo %d / %s" % [str(actor.id).replace("_"," ").capitalize(),str(actor.faction).replace("_"," ").capitalize(),int(actor.cargo),"Active" if actor.active else "Dispersed"])
	details_label.text="\n".join(lines)
	var town_here: bool=campaign.at_town() and profile.active_run.is_empty()
	buttons.food.text="Buy food / %sg" % campaign.supply_price("food")
	buttons.food.disabled=not town_here or int(profile.gold)<campaign.supply_price("food")
	buttons.inn.disabled=not town_here or int(profile.gold)<5
	buttons.trade.disabled=not campaign.can_trade()
	buttons.training.disabled=not campaign.can_trade()
	buttons.prepare.visible=selected_site=="dungeon_old_mine" and profile.active_run.is_empty()
	buttons.prepare.disabled=locked or not World.at_site(state,"dungeon_old_mine") or state.mine.status=="cleared"
	buttons.resume.visible=not profile.active_run.is_empty()
	event_panel.visible=not profile.world.pending_event.is_empty()
	if event_panel.visible:
		event_label.text="Mine raiders / resolve the road encounter"
		buttons.event_pay.disabled=int(profile.gold)<5 or profile.world.pending_event.phase!="choice"
	var faction_text: Array[String]=[]
	for id: String in state.factions:
		var faction: Dictionary=state.factions[id]
		faction_text.append("%s\nRelation %+d / Strength %d" % [id.replace("_"," ").capitalize(),int(faction.relation),int(faction.strength)])
	faction_text.append("%s / Tension %d\nCaravan arrivals %d / Raids %d" % [str(state.politics.phase).replace("_"," ").capitalize(),int(state.politics.tension),int(state.deliveries),int(state.raids)])
	faction_label.text="\n\n".join(faction_text)
	for id: String in contract_nodes:
		var widgets: Dictionary=contract_nodes[id]
		var definition:=World.contract(id)
		var stage: String=str(state.contracts.get(id,{}).get("stage","unavailable"))
		widgets.panel.visible=stage!="unavailable"
		var description: String={"offered":"Offered","accepted":"In progress","objective":"Ready to report","completed":"Paid","expired":"Closed"}.get(stage,"Unavailable")
		var availability: Dictionary=campaign.living_contract_availability(id)
		widgets.status.text="%s / %s\n%s" % [description,World.site(definition.issuer,state).name,availability.progress]
		widgets.report.text="Deliver 3 food / collect payment" if definition.kind=="delivery" else "Report / collect payment"
		widgets.accept.disabled=not str(availability.accept_reason).is_empty()
		widgets.report.disabled=not str(availability.report_reason).is_empty()
		widgets.accept.tooltip_text=str(availability.accept_reason) if widgets.accept.disabled else "Accept this contract at its issuing settlement."
		widgets.report.tooltip_text=str(availability.report_reason) if widgets.report.disabled else "Deliver 3 owned food and collect payment." if definition.kind=="delivery" else "Report the completed objective and collect payment."
	var history: Array[String]=[]
	for index in range(state.journal.size()-1,-1,-1):
		var event: Dictionary=state.journal[index]
		history.append("%s\n%s" % [clock(int(event.tick)),event.text])
	journal_label.text="\n\n".join(history)
	footer.text=str(state.journal.back().text) if world_tick and not state.journal.is_empty() else campaign.last_feedback
	footer.tooltip_text=footer.text
func set_speed(rate: int) -> void:
	if rate not in [0,1,2,4]: return
	if not _campaign().state.active_run.is_empty() or not _campaign().state.world.pending_event.is_empty(): rate=0
	speed=rate
	_refresh()
func _process(delta: float) -> void:
	if speed==0 or not _campaign().living_active(): return
	accumulated+=delta*speed
	var steps:=0
	while accumulated>=.6-.000000001 and steps<8:
		accumulated=maxf(0,accumulated-.6);steps+=1
		if not _campaign().advance_living():
			set_speed(0);break
		map.update_state(_campaign().state,.6/maxi(1,speed),_campaign().living_motion)
		if not _campaign().state.world.pending_event.is_empty():
			map.snap()
			tabs.current_tab=0
			set_speed(0);break
	if steps>0: _refresh(true)
	if speed>0: map.set_phase(accumulated/.6)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("living_pause"):
		set_speed(1 if speed==0 else 0);get_viewport().set_input_as_handled()
	for rate in [1,2,4]:
		if event.is_action_pressed("living_speed_%s" % rate):
			set_speed(rate);get_viewport().set_input_as_handled()
func _course(position: Vector2,id: String) -> void:
	selected_actor=""
	if id!="": selected_site=id
	if id!="" and World.at_site(_campaign().state.living_world,id):
		set_speed(0);tabs.current_tab=0;return
	if _campaign().living_course(position,id): set_speed(1)
	else: set_speed(0)
	_refresh()
func _inspect_actor(id: String) -> void:
	selected_actor=id;tabs.current_tab=0;set_speed(0)
func _act(callback: Callable) -> void:
	set_speed(0)
	callback.call()
	_refresh()
func _camp() -> void:
	var enabled: bool=not _campaign().state.living_world.party.camping
	if _campaign().living_camp(enabled): set_speed(1 if enabled else 0)
	_refresh()
func _go_scene(path: String) -> void:
	set_speed(0)
	if scene_requested.has_connections(): scene_requested.emit(path)
	else: get_tree().change_scene_to_file(path)
func _open_tab(tab: String) -> void:
	_campaign().requested_campaign_tab=tab
	_go_scene("res://scenes/app/App.tscn")
func _prepare() -> void:
	if not _campaign().living_active() or not World.at_site(_campaign().state.living_world,"dungeon_old_mine") or not _campaign().state.active_run.is_empty() or not _campaign().state.world.pending_event.is_empty() or _campaign().state.living_world.mine.status=="cleared": return
	var session:=get_node("/root/DungeonRunSession")
	session.clear();session.town_preparation=true
	_go_scene("res://scenes/dungeon/DungeonDebug.tscn")
func _resume() -> void:
	if get_node("/root/DungeonRunSession").restore_campaign(): _go_scene("res://scenes/dungeon/DungeonDebug.tscn")
func _fight() -> void:
	var campaign:=_campaign()
	if campaign.state.world.pending_event.is_empty(): return
	if campaign.state.world.pending_event.phase=="choice" and not campaign.choose_road_event("fight"): return
	if get_node("/root/DungeonRunSession").restore_road_combat(): _go_scene("res://scenes/combat/CombatDebug.tscn")
func _exit_pilot() -> void:
	var campaign:=_campaign()
	set_speed(0)
	get_node("/root/DungeonRunSession").clear()
	campaign.requested_campaign_tab=""
	campaign.load_profile("user://campaign_v1.json",campaign.memory_only)
	_go_scene("res://scenes/app/App.tscn")

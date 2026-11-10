extends Control
signal scene_requested(path: String)
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Map := preload("res://scripts/presentation/world/strategic_map.gd")
const F := preload("res://scripts/domain/life_campaign.gd")
const LifePanel := preload("res://scripts/presentation/world/world_life_panel.gd")
const R := preload("res://scripts/domain/strategic_region.gd")
const ModelFeedback := preload("res://scripts/presentation/world/strategist_feedback.gd")
var buttons: Dictionary={}
var job_rows: Dictionary={}
var map: Control
var tabs: TabContainer
var heading: Label
var stocks: Label
var location: Label
var site_title: Label
var factions: Label
var journal: Label
var company: Label
var footer: Label
var seed_input: SpinBox
var preset_input: OptionButton
var faction_input: OptionButton
var supply_input: OptionButton
var hero_input: OptionButton
var slot_input: OptionButton
var item_input: OptionButton
var trade_input: OptionButton
var jobs_box: VBoxContainer
var selected := "town_ravenford"
var speed := 0
var accumulated := 0.0
var inventory_signature := ""
var qa_memory := false
@export var qa_life := false
var life_panel: RefCounted
@export var qa_model := false
@export var qa_geography_version := 2
var world_size_input: OptionButton
var model_input: OptionButton
var model_status: Label
var model_notice: Label

func owner() -> Node: return get_node("/root/StrategicSession")
func _label(parent: Node, text: String, size_value: int=21, color: Color=UI.TEXT) -> Label:
	var label := Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_value);label.add_theme_color_override("font_color",color)
	label.add_theme_font_override("font",UI.heading_font() if size_value>=26 else UI.body_font())
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label);return label
func _button(parent: Node, id: String, text: String, callback: Callable) -> Button:
	var button := Button.new();button.text=text;button.custom_minimum_size.y=42;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",20);button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text=text;button.pressed.connect(callback);parent.add_child(button);buttons[id]=button;return button
func _option(parent: Node) -> OptionButton:
	var option := OptionButton.new();option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;option.custom_minimum_size.y=38
	option.add_theme_font_size_override("font_size",19);parent.add_child(option);return option
func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new();scroll.name=title;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;tabs.add_child(scroll)
	var column := VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10);scroll.add_child(column);return column

func _ready() -> void:
	set_process(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=UI.theme()
	if not owner().regional_active() or owner().session.state.version!=(5 if qa_life else (4 if qa_model else 3)) or owner().session.state.region.base.version!=qa_geography_version:
		var loading := _label(self,"Charting a "+("Vast" if qa_geography_version==3 else "Large")+" world...",28,UI.GOLD);loading.position=Vector2(30,30)
		await get_tree().process_frame
		var opened: bool=owner().call("open_life_seed" if qa_life else ("open_model_seed" if qa_model else "open_seed"),2087,"marches",qa_memory or DisplayServer.get_name()=="headless",qa_geography_version)
		loading.queue_free()
		if not opened:
			var unavailable := VBoxContainer.new();unavailable.set_anchors_and_offsets_preset(Control.PRESET_CENTER);unavailable.custom_minimum_size=Vector2(480,160);add_child(unavailable)
			_label(unavailable,"Campaign unavailable",28,UI.GOLD);_label(unavailable,owner().last_feedback,20)
			_button(unavailable,"exit","Return to regions",_exit);set_process(false);return
	_build()
	if not owner().regional_active(): footer.text=owner().last_feedback;set_process(false);return
	_refresh();UI.focus_later(buttons.pause);set_process(true)

func _build() -> void:
	var background := TextureRect.new();background.texture=UI.Assets.texture(UI.ART+"leather.png");background.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;background.stretch_mode=TextureRect.STRETCH_TILE;background.modulate=Color(.38,.36,.33);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin := MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin)
	var column := VBoxContainer.new();column.add_theme_constant_override("separation",8);margin.add_child(column)
	var header := HBoxContainer.new();column.add_child(header)
	heading=_label(header,"Four Banners",28,UI.GOLD);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stocks=_label(header,"",20,UI.GOLD);stocks.custom_minimum_size.x=230;stocks.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var controls := HBoxContainer.new();column.add_child(controls)
	_button(controls,"pause","Pause [Space]",func(): set_speed(0))
	for rate: int in [1,2,4]: _button(controls,"speed%d" % rate,"%dx" % rate,func(): set_speed(rate))
	_button(controls,"camp","Camp",func(): _act("camp",{"enabled":not owner().session.state.travel.camping}))
	seed_input=SpinBox.new();seed_input.min_value=1;seed_input.max_value=1000000000;seed_input.value=owner().session.state.strategy_world.core.seed if owner().regional_active() else 2087;seed_input.custom_minimum_size.x=130;seed_input.tooltip_text="World seed; the same seed resumes its saved company.";controls.add_child(seed_input)
	preset_input=_option(controls)
	for preset: String in R.G.Gen.PRESETS: preset_input.add_item(preset.capitalize());preset_input.set_item_metadata(preset_input.item_count-1,preset)
	if owner().regional_active(): preset_input.select(R.G.Gen.PRESETS.find(owner().session.state.region.base.preset))
	world_size_input=_option(controls);world_size_input.tooltip_text="Vast has four times the area of Large. New / Resume opens that size's separate company."
	for entry: Array in [["Large",2],["Vast",3]]: world_size_input.add_item(entry[0]);world_size_input.set_item_metadata(world_size_input.item_count-1,entry[1])
	world_size_input.select(1 if qa_geography_version==3 else 0)
	_button(controls,"open","New / Resume",_open_seed)
	_button(controls,"exit","Regions",_exit)
	if qa_model or qa_life:
		var notice := PanelContainer.new();notice.mouse_filter=Control.MOUSE_FILTER_IGNORE;notice.add_theme_stylebox_override("panel",UI.box(UI.RAISED,UI.EDGE,10));column.add_child(notice)
		model_notice=_label(notice,"",18,UI.GOLD)
	var body := HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);column.add_child(body)
	var map_panel := PanelContainer.new();map_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;map_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;map_panel.add_theme_stylebox_override("panel",UI.paper_box(10));body.add_child(map_panel)
	map=Map.new()
	if owner().regional_active(): map.profile=owner().session.state
	map_panel.add_child(map);map.course_requested.connect(_course);map.actor_selected.connect(_actor)
	var inspector := PanelContainer.new();inspector.custom_minimum_size.x=330 if get_viewport_rect().size.x<1500 else 420;inspector.add_theme_stylebox_override("panel",UI.box(UI.PANEL,UI.EDGE,20));body.add_child(inspector)
	tabs=TabContainer.new();tabs.add_theme_font_size_override("font_size",16);inspector.add_child(tabs)
	var place := _tab("Location")
	site_title=_label(place,"",26,UI.GOLD)
	location=_label(place,"",21)
	_button(place,"travel","Travel to selection",func(): _course(R.G.point(_catalog(owner().session.state)[selected].position),selected))
	supply_input=_option(place)
	for id: String in R.Legacy.PRICES: supply_input.add_item(R.Legacy.SUPPLY_NAMES[id]);supply_input.set_item_metadata(supply_input.item_count-1,id)
	supply_input.select(supply_input.item_count-1);supply_input.item_selected.connect(func(_i): _refresh())
	_button(place,"buy","Buy provisions",func(): _act("buy_supply",{"id":_selected(supply_input)}))
	_button(place,"inn","Rest at the inn / 5g",func(): _act("recover"))
	_button(place,"prepare","Prepare Old Mine expedition",_prepare)
	_button(place,"resume","Resume saved expedition",_resume)
	var politics := _tab("Factions")
	if qa_model:
		_label(politics,"Faction strategist",22,UI.GOLD)
		model_input=_option(politics)
		for entry: Array in [["Classic","classic"],["Recorded examples (offline)","recorded"]]: model_input.add_item(entry[0]);model_input.set_item_metadata(model_input.item_count-1,entry[1])
		model_input.item_selected.connect(func(_i):
			var mode: String=str(_selected(model_input));set_speed(0);_act("model_mode",{"mode":mode}))
		model_status=_label(politics,"",18,UI.MUTED)
	else:
		_button(politics,"model_lab","Open strategist campaign",_model_lab).tooltip_text="Start or resume a separate company with classic and offline example strategists."
	faction_input=_option(politics)
	if owner().regional_active():
		for id: String in R.C.S.sorted_ids(owner().session.state.strategy_world.core.factions): faction_input.add_item(owner().session.state.strategy_world.core.factions[id].name);faction_input.set_item_metadata(faction_input.item_count-1,id)
	faction_input.item_selected.connect(func(_i): _refresh())
	factions=_label(politics,"",20)
	jobs_box=_tab("Jobs");_label(jobs_box,"Accept and report at the issuer. Accepted rewards stay reserved.",19,UI.MUTED)
	journal=_label(_tab("Chronicle"),"",19)
	var gear := _tab("Company")
	company=_label(gear,"",19)
	hero_input=_option(gear)
	for hero: Dictionary in R.Legacy.Party.default_party(): hero_input.add_item(hero.display_name);hero_input.set_item_metadata(hero_input.item_count-1,hero.combat_unit_id)
	slot_input=_option(gear)
	for slot: String in R.Legacy.Gear.SLOTS: slot_input.add_item(slot.replace("_"," ").capitalize());slot_input.set_item_metadata(slot_input.item_count-1,slot)
	item_input=_option(gear)
	_button(gear,"equip","Equip selected item",func(): _act("equip",{"hero":_selected(hero_input),"slot":_selected(slot_input),"item":_selected(item_input)}))
	trade_input=_option(gear)
	for offer: Dictionary in R.Legacy.Trade.catalogue().offers: trade_input.add_item(R.Legacy.Gear.Items.item(offer.item_id).get("name",offer.item_id)+" / %dg" % offer.buy_price);trade_input.set_item_metadata(trade_input.item_count-1,offer.item_id)
	_button(gear,"purchase_item","Buy selected equipment",func(): _act("purchase_item",{"id":_selected(trade_input)}))
	_button(gear,"sell_item","Sell an unassigned copy",func(): _act("sell_item",{"id":_selected(item_input)}))
	_button(gear,"train","Train selected hero",func(): _act("train",{"hero":_selected(hero_input)}))
	tabs.tab_changed.connect(func(index):
		if index in [2,4]: set_speed(0)
		else: _refresh())
	if qa_life:
		life_panel=LifePanel.new();life_panel.build(self,_tab("World"))
	footer=_label(column,"",18,UI.GOLD);footer.custom_minimum_size.y=28

func _catalog(s: Dictionary) -> Dictionary:
	return R.sites(s,F.extras(s)) if qa_life else s.region.sites
func select_life_site(id: String) -> void:
	selected=id;tabs.current_tab=0
	map.camera.focus(R.G.point(_catalog(owner().session.state)[id].position),map.size);map._layout();_refresh()

func _selected(option: OptionButton) -> Variant:
	return option.get_item_metadata(option.selected) if option.selected>=0 else null
func clock(tick: int) -> String: return "Day%d %02d:%02d" % [tick/96+1,(tick/4)%24,(tick%4)*15]
func _refresh() -> void:
	if not owner().regional_active(): return
	var s: Dictionary=owner().session.state;var current := F.current(s) if qa_life else R.current(s);var world: Dictionary=s.strategy_world
	heading.text=s.region.base.name+" / "+("Vast" if int(s.region.base.version)==3 else "Large")+" / "+clock(int(world.core.tick))+" / "+("Paused" if speed==0 else "%dx" % speed)
	stocks.text="%dg / Food%d\nFatigue%d/100" % [s.company.gold,s.company.supplies.food,s.travel.fatigue]
	map.update_state(s,owner().session.last_motion)
	if model_status!=null:
		_refresh_model(s)
	var site: Dictionary=_catalog(s).get(selected,s.region.sites.town_ravenford)
	var actual_owner: String=site.owner if qa_life and not s.region.sites.has(site.id) else R.site_owner(s,site.id)
	site_title.text=site.name
	location.text="%s\n\nCompany: %s\n%s" % [world.core.factions.get(actual_owner,{}).get("name",actual_owner.capitalize()),_catalog(s).get(current,{}).get("name","On the road"),"The mine has been restored." if s.mine.status=="restored" else "The Old Mine's ore production is stopped."]
	var quote := R.supply_quote(s,str(_selected(supply_input)))
	buttons.buy.text="Buy %s / %dg" % [R.Legacy.SUPPLY_NAMES[_selected(supply_input)],quote.price]
	buttons.buy.disabled=quote.reason!="";buttons.buy.tooltip_text=quote.reason if quote.reason!="" else "Pay from owned gold and receive one carried supply."
	buttons.inn.disabled=not R.at_town(s) or s.company.gold<5
	buttons.prepare.disabled=current!="dungeon_old_mine" or s.mine.status!="occupied" or not s.company.active_run.is_empty()
	buttons.resume.disabled=s.company.active_run.is_empty();buttons.travel.disabled=not s.company.active_run.is_empty()
	for rate: int in [1,2,4]:
		buttons["speed%d" % rate].disabled=not s.company.active_run.is_empty() or tabs.current_tab in [2,4]
		buttons["speed%d" % rate].tooltip_text="Close Jobs/Company or resolve the expedition to advance time." if buttons["speed%d" % rate].disabled else "%dx travel speed" % rate
	var public := R.public_faction(s,str(_selected(faction_input)))
	if not public.is_empty():
		var lines: Array[String]=[public.name,"Company reputation: %+d" % public.reputation,"Known troops: %d" % public.troops,"Towns: "+", ".join(public.towns),""]
		for relation: Dictionary in public.diplomacy:
			lines.append(relation.name+" / "+relation.stance.capitalize())
			if not relation.pacts.is_empty(): lines.append("  "+", ".join(relation.pacts))
			if relation.truce_ticks>0: lines.append("  Ceasefire: %dh remaining" % ceili(relation.truce_ticks/4.0))
		factions.text="\n".join(lines)
	var history: Array[String]=[]
	for entry: Dictionary in R.chronicle(s): history.append(clock(int(entry.tick))+" / "+entry.text)
	if qa_life:
		for entry: Dictionary in s.life.events: history.push_front(clock(int(entry.tick))+" / "+entry.source+" / "+entry.text)
	journal.text="\n\n".join(history)
	if qa_life:
		if s.life.events.is_empty(): model_notice.text="The world is paused. Open World and wait a day to receive the first camp reports."
		else:
			var latest: Dictionary=s.life.events.back()
			model_notice.text=clock(int(latest.tick))+" / "+latest.source+" / "+latest.text
		life_panel.refresh(s)
		if s.life.sites.has(current):
			buttons.prepare.text="Prepare "+s.life.sites[current].name
			buttons.prepare.disabled=F.prepare_reason(s)!=""
			buttons.prepare.tooltip_text=F.prepare_reason(s)
		else: buttons.prepare.text="Prepare Old Mine expedition"
	_refresh_jobs(s);_refresh_company(s)
	footer.text=owner().last_feedback

func _refresh_model(s: Dictionary) -> void:
	var info := ModelFeedback.project(s)
	model_input.select(0 if s.strategist.mode=="classic" else 1)
	var counts := "Plans accepted: %d | Recent actions: %d applied, %d blocked" % [info.plans,info.applied,info.blocked]
	var last: String=(clock(info.last_tick)+" / " if info.last_tick>=0 else "")+info.last
	model_notice.text=info.mode+" | "+counts+" | Pending: %d\n" % info.pending+last+(" "+info.why if info.why!="" else "")
	var mode := "Authored local proposals. No live model." if s.strategist.mode=="recorded" else "Classic policy active. Choose Recorded examples to test proposals. No live model."
	model_status.text=mode+"\n"+counts+"\nPending: %d | Classic fallback: %d\nRecent actions cover up to 64 retained reviews.\n\n%s\n%s" % [info.pending,info.fallback,last,info.why]
	if info.fallback_reason!="": model_status.text+="\nLatest classic fallback: "+info.fallback_reason
	if info.due>=0: model_status.text+="\n\n"+info.due_label+": "+clock(info.due)
	model_status.text+="\nOffers and replies can apply without creating a new map unit. Confirmed world events appear in Chronicle."

func _refresh_jobs(s: Dictionary) -> void:
	for id: String in job_rows.keys():
		if not s.jobs.has(id): job_rows[id].panel.queue_free();job_rows.erase(id)
	for id: String in R.C.S.sorted_ids(s.jobs):
		var j: Dictionary=s.jobs[id]
		if not job_rows.has(id):
			var card := PanelContainer.new();card.add_theme_stylebox_override("panel",UI.box(UI.RAISED,UI.EDGE,20));jobs_box.add_child(card)
			var box := VBoxContainer.new();box.add_theme_constant_override("separation",6);card.add_child(box)
			var text := _label(box,"",19)
			var accept := _button(box,"accept_"+id,"Accept contract",func(): _act("accept_job",{"id":id}))
			var report := _button(box,"report_"+id,"Report / collect payment",func(): _act("report_job",{"id":id}))
			job_rows[id]={"panel":card,"text":text,"accept":accept,"report":report}
		var row: Dictionary=job_rows[id]
		row.text.text="%s / %s\n%s\nIssuer: %s\nObjective: %s\nReward: %dg / %dXP\n%s" % [j.kind.capitalize(),j.status.capitalize(),j.cause.context,s.region.sites[j.issuer_town].name,s.region.sites[j.target].name,j.gold,j.xp,"Carried food: %d/%d" % [s.company.supplies.food,j.party_food] if j.kind=="delivery" else "Return after completing the accepted objective."]
		for action: String in ["accept","report"]:
			var reason := R.job_reason(s,id,action=="report");row[action].disabled=reason!="";row[action].tooltip_text=reason if reason!="" else row[action].text

func _refresh_company(s: Dictionary) -> void:
	var lines: Array[String]=["Owned supplies"]
	for id: String in R.Legacy.PRICES: lines.append("%s: %d" % [R.Legacy.SUPPLY_NAMES[id],s.company.supplies[id]])
	lines.append("\nAvailable XP: %d" % owner().available_xp())
	for hero: Dictionary in R.Legacy.Party.default_party():
		lines.append("\n"+hero.display_name)
		for slot: String in R.Legacy.Gear.SLOTS:
			var item: Variant=s.company.equipment[hero.combat_unit_id][slot]
			if item!=null: lines.append(slot.replace("_"," ")+": "+R.Legacy.Gear.Items.item(item).get("name",item))
	company.text="\n".join(lines)
	var signature := JSON.stringify(s.company.items)
	if signature!=inventory_signature:
		var selected_item: Variant=_selected(item_input);item_input.clear();item_input.add_item("Empty slot");item_input.set_item_metadata(0,null)
		var seen := {}
		for item: String in s.company.items:
			if seen.has(item) or R.Legacy.Gear.Items.item(item).get("combat_profile",{}).is_empty(): continue
			seen[item]=true;item_input.add_item(R.Legacy.Gear.Items.item(item).get("name",item));item_input.set_item_metadata(item_input.item_count-1,item)
			if item==selected_item: item_input.select(item_input.item_count-1)
		inventory_signature=signature
	for id: String in ["purchase_item","sell_item","train"]: buttons[id].disabled=not R.at_town(s)
	buttons.equip.disabled=not s.company.active_run.is_empty()

func _act(action: String, payload: Dictionary={}) -> void:
	owner().order(action,payload);_refresh()
func _course(position: Vector2,id: String) -> void:
	if id!="": selected=id
	_act("course",{"position":R.G.Terrain.packed(position),"site":id})
func _actor(id: String) -> void:
	if qa_life and (owner().session.state.life.actors.has(id) or owner().session.state.life.regions.migrations.has(id)):
		tabs.current_tab=5;_refresh();return
	var world: Dictionary=owner().session.state.strategy_world
	var faction: String=world.core.parties[id].faction_id if world.forces.has(id) else world.trades[id].seller
	for index in range(faction_input.item_count):
		if faction_input.get_item_metadata(index)==faction: faction_input.select(index)
	tabs.current_tab=1;_refresh()
	if world.trades.has(id):
		var trade: Dictionary=world.trades[id]
		footer.text="%s convoy: %s to %s / %s" % [trade.resource.capitalize(),owner().session.state.region.sites[trade.source].name,owner().session.state.region.sites[trade.target].name,trade.status.capitalize()]
	else: footer.text="%s patrol / %d troops" % [world.core.factions[faction].name,world.core.parties[id].headcount]
func set_speed(value: int) -> void:
	if value>0 and (not owner().regional_active() or not owner().state.active_run.is_empty() or (tabs!=null and tabs.current_tab in [2,4])): value=0
	speed=value;accumulated=0
	if map!=null and value==0: map.snap()
	if heading!=null: _refresh()
func _process(delta: float) -> void:
	if owner().pump_strategy(): _refresh()
	if not owner().regional_active() or speed==0 or not owner().state.active_run.is_empty(): return
	accumulated+=minf(delta,.25)*speed
	while accumulated>=.6:
		accumulated-=.6
		if not owner().order("advance",{"ticks":1}): set_speed(0);break
		_refresh()
	map.set_phase(accumulated/.6)
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or get_viewport().gui_get_focus_owner() is LineEdit: return
	if event.keycode==KEY_SPACE: set_speed(1 if speed==0 else 0);get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_1,KEY_2,KEY_4]: set_speed({KEY_1:1,KEY_2:2,KEY_4:4}[event.keycode]);get_viewport().set_input_as_handled()
func _route(path: String) -> void:
	set_speed(0)
	if scene_requested.has_connections(): scene_requested.emit(path)
	else: get_tree().change_scene_to_file(path)
func _prepare() -> void:
	if buttons.prepare.disabled: return
	var run := get_node("/root/DungeonRunSession");run.clear();run.town_preparation=true;_route(run.DUNGEON_SCENE_PATH)
func _resume() -> void:
	var run := get_node("/root/DungeonRunSession")
	if run.restore_campaign(): _route(run.DUNGEON_SCENE_PATH)
func _open_seed() -> void:
	set_speed(0)
	if owner().call("open_life_seed" if qa_life else ("open_model_seed" if qa_model else "open_seed"),int(seed_input.value),str(_selected(preset_input)),qa_memory or DisplayServer.get_name()=="headless",int(_selected(world_size_input))):
		get_node("/root/DungeonRunSession").clear();_route(owner().world_return_scene())
	else: footer.text=owner().last_feedback
func _model_lab() -> void:
	set_speed(0)
	if owner().open_model_seed(int(seed_input.value),str(_selected(preset_input)),qa_memory or DisplayServer.get_name()=="headless",int(_selected(world_size_input))): _route(owner().world_return_scene())
	else: footer.text=owner().last_feedback
func _exit() -> void:
	set_speed(0);owner().deactivate();_route("res://scenes/world/RegionFoundry.tscn")

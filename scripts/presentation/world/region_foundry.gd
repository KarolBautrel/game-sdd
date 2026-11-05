extends Control
signal scene_requested(path: String)
const Gen:=preload("res://scripts/domain/region_generator.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Campaign:=preload("res://scripts/session/campaign_session.gd")
const Pilot:=preload("res://scripts/qa/living_world_pilot.gd")
const Map:=preload("res://scripts/presentation/world/living_map.gd")
const UI:=preload("res://scripts/presentation/world/campaign_skin.gd")
@export var qa_memory:=false
var buttons: Dictionary={}
var seed_input: SpinBox
var preset_input: OptionButton
var size_input: OptionButton
var overlay_button: CheckButton
var title: Label
var summary: Label
var status: Label
var map: Control
var map_host: PanelContainer
var geography: Dictionary={}
var preview_profile: Dictionary={}
var generation_token:=0
var busy:=false
func _campaign() -> Node: return get_node("/root/CampaignSession")
func _label(parent: Node,text: String,font_size: int=20,color: Color=UI.TEXT) -> Label:
	var label:=UI.label(parent,text,font_size,color);label.add_theme_font_size_override("font_size",font_size);label.autowrap_mode=TextServer.AUTOWRAP_OFF
	return label
func _button(parent: Node,id: String,text: String,callback: Callable) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=44;button.add_theme_font_size_override("font_size",19)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,UI.frame("frame_metal",8))
	button.pressed.connect(callback);parent.add_child(button);buttons[id]=button;return button
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=UI.theme()
	_build()
	var campaign:=_campaign()
	if campaign.living_active() and campaign.state.living_world.has("geography"):
		var previous: Dictionary=campaign.state.living_world.geography
		seed_input.value=int(previous.seed);preset_input.select(Gen.PRESETS.find(previous.preset))
		size_input.select(int(previous.version)-1)
	generate_region.call_deferred()
func _build() -> void:
	var background:=TextureRect.new();background.texture=load(UI.ART+"leather.png");background.stretch_mode=TextureRect.STRETCH_TILE;background.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;background.modulate=Color(.36,.34,.30);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,18)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",9);margin.add_child(column)
	var heading:=HBoxContainer.new();column.add_child(heading)
	title=_label(heading,"Uncharted lands",30,UI.GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(heading,"authored","Authored Marches",_authored)
	_button(heading,"back","Current company",_back)
	var toolbar:=HBoxContainer.new();toolbar.add_theme_constant_override("separation",8);column.add_child(toolbar)
	_label(toolbar,"Seed",19)
	seed_input=SpinBox.new();seed_input.min_value=1;seed_input.max_value=1000000000;seed_input.step=1;seed_input.value=2087;seed_input.custom_minimum_size.x=172;seed_input.add_theme_font_size_override("font_size",20);toolbar.add_child(seed_input)
	seed_input.value_changed.connect(func(_value: float) -> void: _selection_changed())
	_button(toolbar,"previous","<",func() -> void: _next(-1))
	_button(toolbar,"next",">",func() -> void: _next(1))
	preset_input=OptionButton.new();preset_input.add_theme_font_size_override("font_size",19);preset_input.custom_minimum_size.x=180
	for preset in ["Marches","Deep woodland","Highlands"]: preset_input.add_item(preset)
	preset_input.item_selected.connect(func(_index: int) -> void: _selection_changed());toolbar.add_child(preset_input)
	size_input=OptionButton.new();size_input.add_theme_font_size_override("font_size",19);size_input.custom_minimum_size.x=128
	size_input.add_item("Classic");size_input.add_item("Large");size_input.select(1);toolbar.add_child(size_input)
	size_input.item_selected.connect(func(_index: int) -> void: _selection_changed())
	_button(toolbar,"generate","Generate",generate_region)
	_button(toolbar,"play","Play / Resume",_play)
	overlay_button=CheckButton.new();overlay_button.text="Terrain overlay";overlay_button.add_theme_font_size_override("font_size",18);toolbar.add_child(overlay_button)
	overlay_button.toggled.connect(func(value: bool) -> void:
		if map!=null: map.semantic_overlay=value;map.queue_redraw())
	summary=_label(column,"",18,UI.MUTED);summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;summary.custom_minimum_size.y=24
	map_host=PanelContainer.new();map_host.add_theme_stylebox_override("panel",UI.frame("frame_dark",10));map_host.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(map_host)
	status=_label(column,"",19);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size.y=42
	buttons.play.disabled=true
func _selection_changed() -> void:
	if not buttons.has("play") or preset_input==null: return
	buttons.play.disabled=busy or geography.is_empty() or int(geography.seed)!=int(seed_input.value) or geography.preset!=Gen.PRESETS[preset_input.selected] or int(geography.version)!=size_input.selected+1
	if buttons.play.disabled and not busy: status.text="Choose Generate to chart this seed and preset. Existing company progress is preserved."
func _next(direction: int) -> void:
	seed_input.value=wrapi(int(seed_input.value)+direction,1,1000000001)
	generate_region()
func generate_region() -> void:
	generation_token+=1;var token:=generation_token
	busy=true;buttons.play.disabled=true;buttons.generate.disabled=true
	status.text="Charting terrain, rivers, crossings and accessible sites..."
	await get_tree().process_frame
	if token!=generation_token: return
	var candidate:=Gen.generate(int(seed_input.value),Gen.PRESETS[preset_input.selected],size_input.selected+1)
	busy=false;buttons.generate.disabled=false
	if candidate.is_empty(): status.text="Could not chart this region: "+Gen.last_error;_selection_changed();return
	geography=candidate
	preview_profile=Campaign.initial_profile();preview_profile.living_world=World.initial(int(geography.seed),0,geography)
	if map!=null: map.queue_free()
	map=Map.new();map.name="GeneratedRegionMap";map.region_state=preview_profile.living_world;map.preview_only=true;map.semantic_overlay=overlay_button.button_pressed;map.size_flags_vertical=Control.SIZE_EXPAND_FILL;map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map_host.add_child(map);map.update_state(preview_profile)
	map.course_requested.connect(_preview_route)
	title.text=str(geography.name)
	var coverage:=int(geography.diagnostics.connected_cells)*100/maxi(1,int(geography.diagnostics.land_cells))
	summary.text="Seed %d / %s / %s / %d crossings / %d%% connected / %dx%d terrain / v%d" % [int(geography.seed),str(geography.preset).capitalize(),"Large: 4x area" if int(geography.version)==2 else "Classic",geography.bridges.size(),coverage,int(geography.terrain.width),int(geography.terrain.height),int(geography.version)]
	status.text="Terrain, crossings and all six sites validated. Click a site to preview a real route; Play / Resume opens this seed's own company."
	_selection_changed()
func _preview_route(position: Vector2,id: String) -> void:
	if not World.course(preview_profile,position,id): status.text="No accessible route: water and high peaks are blocked.";return
	map.selected_site=id;map.update_state(preview_profile);map.snap()
	var cost: float=World.navigation(preview_profile.living_world).route_cost(World.point(preview_profile.living_world.party.position),preview_profile.living_world.party.path)*World.travel_scale(preview_profile.living_world)
	status.text="Safe route to %s / about %.1f campaign hours before fatigue. Preview does not move or charge the company." % [str(World.site(id,preview_profile.living_world).get("name","selected ground")),cost/.18]
func _play() -> void:
	if buttons.play.disabled or geography.is_empty(): return
	var campaign:=_campaign()
	if qa_memory and not campaign.loaded: campaign.load_profile("",true)
	if not Pilot.open_generated(campaign,int(geography.seed),str(geography.preset),int(geography.version)): status.text=campaign.last_feedback;return
	campaign.requested_campaign_tab="";get_node("/root/DungeonRunSession").clear();_go("res://scenes/world/LivingWorld.tscn")
func _authored() -> void:
	var campaign:=_campaign()
	if qa_memory or campaign.memory_only:
		campaign.load_profile("",true);campaign.enable_living_world()
	elif not Pilot.open(campaign): status.text=campaign.last_feedback;return
	get_node("/root/DungeonRunSession").clear();_go("res://scenes/world/LivingWorld.tscn")
func _back() -> void:
	_go("res://scenes/world/LivingWorld.tscn" if _campaign().living_active() else "res://scenes/app/App.tscn")
func _go(path: String) -> void:
	if scene_requested.get_connections().is_empty(): get_tree().change_scene_to_file(path)
	else: scene_requested.emit(path)

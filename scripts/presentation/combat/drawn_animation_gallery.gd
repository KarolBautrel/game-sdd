extends Control
## Native-scale review using the same imported textures and routing as combat.
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const Catalog := preload("res://scripts/presentation/combat/drawn_animation_catalog.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const ACTIONS := ["neutral_idle","combat_idle","neutral_walk","combat_walk","attack","hit","death","draw","sheathe","attack_alt","block","dodge"]
const TITLES := ["Spoczynek","Gotowość bojowa","Chód spokojny","Chód bojowy","Atak","Trafienie","Upadek","Rycerz: dobycie miecza","Rycerz: schowanie miecza","Rycerz: pchnięcie","Rycerz: parowanie","Rycerz: unik"]
var available_actions: Array[String]=[]
const DIRECTIONS := Catalog.DIRECTIONS
const VIEW_TITLES := {"south":"Przód","south_east":"Przód 3/4 z prawej","east":"Prawy profil","north_east":"Tył 3/4 z prawej","north":"Tył","north_west":"Tył 3/4 z lewej","west":"Lewy profil","south_west":"Przód 3/4 z lewej"}
var action := "neutral_walk"
var direction := "south_east"
var playing := true
var speed := 1.0
var cards: Array[Dictionary] = []
var art := Art.new()
var grid: GridContainer
var play_button: Button
var caption: Label
var ground := "woodland"
@export var embedded := false
var parent_input_enabled := false

func _ready() -> void:
	name="DrawnAnimationGallery"
	z_index=4090
	if embedded:
		parent_input_enabled=get_parent().is_processing_input();get_parent().set_process_input(false)
	theme=UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=Color("161e21")
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	caption=Label.new();caption.add_theme_font_size_override("font_size",24);column.add_child(caption)
	var bar:=HFlowContainer.new();bar.add_theme_constant_override("h_separation",12);bar.add_theme_constant_override("v_separation",8);column.add_child(bar)
	var motions:=OptionButton.new();motions.name="Motion"
	for i in range(ACTIONS.size()):
		for config: Dictionary in Art.PROCESSED_SHEET_VISUALS.values():
			if config.get("drawn",false) and config.frame_counts.has(ACTIONS[i]):
				available_actions.append(ACTIONS[i]);motions.add_item(TITLES[i]);break
	motions.select(available_actions.find(action));motions.item_selected.connect(func(i: int) -> void:select_action(available_actions[i]))
	bar.add_child(motions)
	var facings:=OptionButton.new();facings.name="Facing"
	for facing in DIRECTIONS:facings.add_item(VIEW_TITLES[facing]+(' · odbicie' if facing in ["south_west","west","north_west"] else ''))
	facings.select(DIRECTIONS.find(direction));facings.item_selected.connect(func(i: int) -> void:direction=DIRECTIONS[i];restart())
	bar.add_child(facings)
	for title in ["Pauza","Klatka −","Klatka +","Od początku","Zamknij"]:
		var button:=Button.new();button.text=title;bar.add_child(button)
		button.pressed.connect(_command.bind(title))
		if title=="Pauza":play_button=button
	var tempo:=OptionButton.new()
	for title in ["0,5×","1×","1,5×"]:tempo.add_item(title)
	tempo.select(1);tempo.item_selected.connect(func(i: int) -> void:speed=[0.5,1.0,1.5][i]);bar.add_child(tempo)
	var floors:=OptionButton.new()
	for title in ["Las","Ziemia","Jaskinia"]:floors.add_item(title)
	floors.item_selected.connect(func(i: int) -> void:ground=["woodland","earth","cave"][i];_refresh_ground());bar.add_child(floors)
	var note:=Label.new();note.text="Skala planszy 1× · pauza i klatkowanie przyciskami · odbicie odwraca strój i stronę broni."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(scroll);grid=GridContainer.new();grid.add_theme_constant_override("h_separation",20)
	grid.add_theme_constant_override("v_separation",12);scroll.add_child(grid)
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	for p: Dictionary in registry.profiles:
		if not art.is_drawn_character(p.id):continue
		var card:=VBoxContainer.new();grid.add_child(card)
		var title:=Label.new();title.text=p.label;title.add_theme_font_size_override("font_size",20);card.add_child(title)
		var stage:=Control.new();stage.custom_minimum_size=Vector2(384,320);card.add_child(stage)
		var floor_image:=TextureRect.new();floor_image.size=Vector2(384,320)
		floor_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;floor_image.stretch_mode=TextureRect.STRETCH_TILE
		stage.add_child(floor_image)
		var shadow:=TextureRect.new();shadow.texture=Assets.texture("res://assets/combat/environment/contact_shadow.png")
		shadow.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;shadow.position=Vector2(147,259);shadow.size=Vector2(90,26);stage.add_child(shadow)
		var sprite:=TextureRect.new();sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;sprite.size=Vector2(384,320);stage.add_child(sprite)
		var info:=Label.new();card.add_child(info)
		var unit: Dictionary={"id":"review_"+p.id,"team":"player","visual":{"character":p.id,"faction":"drawn"}}
		cards.append({"id":p.id,"unit":unit,"box":card,"sprite":sprite,"ground":floor_image,"info":info,"frame":0,"phase":0.0,"finished":false})
	resized.connect(_responsive);_responsive();_refresh_ground();restart()
	caption.text="Animacje · %s postaci · 8 kierunków (5 rysowanych + 3 odbite)" % cards.size()
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	play_button.grab_focus()

func _responsive() -> void:
	if grid!=null:grid.columns=maxi(1,mini(3,int((size.x-40)/404)))

func _refresh_ground() -> void:
	for card: Dictionary in cards:card.ground.texture=Assets.texture("res://assets/combat/environment/floors/"+ground+".png")

func select_action(value: String) -> void:
	assert(value in ACTIONS);action=value;restart()

func restart() -> void:
	playing=true
	for card: Dictionary in cards:
		card.frame=0;card.phase=0.0;card.finished=false;card.box.visible=_supports(card)
	_refresh();_sync()

func _process(delta: float) -> void:
	advance(delta*speed)

func advance(delta: float) -> void:
	if not playing:return
	for card: Dictionary in cards:
		if card.finished or not _supports(card):continue
		card.phase+=delta
		var count:=art.processed_sheet_frame_count(card.id,action)
		var guard:=0
		while card.phase>=art.frame_seconds(card.unit,action,0.1,card.frame) and guard<100:
			card.phase-=art.frame_seconds(card.unit,action,0.1,card.frame);guard+=1
			if card.frame<count-1:card.frame+=1
			elif action in ["neutral_idle","combat_idle","neutral_walk","combat_walk"]:card.frame=0
			else:card.finished=true;card.phase=0.0;break
	_refresh()

func step(delta: int) -> void:
	playing=false
	for card: Dictionary in cards:
		if not _supports(card):continue
		card.frame=posmod(card.frame+delta,art.processed_sheet_frame_count(card.id,action));card.phase=0.0;card.finished=false
	_refresh();_sync()

func _refresh() -> void:
	for card: Dictionary in cards:
		if not _supports(card):continue
		card.sprite.texture=Assets.texture(art.processed_sheet_texture_path(card.id,direction,"%s:%s" % [action,card.frame]))
		card.info.text="%s · klatka %s / %s" % [VIEW_TITLES[direction],card.frame+1,art.processed_sheet_frame_count(card.id,action)]

func _supports(card: Dictionary) -> bool:
	return Art.PROCESSED_SHEET_VISUALS[card.id].frame_counts.has(action)

func _sync() -> void:
	if play_button!=null:play_button.text="Pauza" if playing else "Odtwarzaj"

func _command(value: String) -> void:
	match value:
		"Pauza":playing=not playing;_sync()
		"Klatka −":step(-1)
		"Klatka +":step(1)
		"Od początku":restart()
		"Zamknij":
			if embedded:queue_free()
			else:get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:_command("Pauza")
			KEY_LEFT:step(-1)
			KEY_RIGHT:step(1)
			KEY_ESCAPE:_command("Zamknij")

func _exit_tree() -> void:
	if embedded and is_instance_valid(get_parent()):get_parent().set_process_input(parent_input_enabled)

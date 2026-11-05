extends SceneTree
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Catalog := preload("res://scripts/presentation/combat/drawn_animation_catalog.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const Timeline := preload("res://scripts/presentation/combat/drawn_combat_timeline.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void:_run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _run() -> void:
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	var art:=Art.new()
	check(registry.profiles.size()>0,"complete drawn profiles published")
	if OS.get_cmdline_user_args().has("--require-all"):check(registry.profiles.size()==6,"entire authorized six-profile subset")
	for p: Dictionary in registry.profiles:
		var unit: Dictionary={"id":"qa_"+p.id,"team":"player","position":{"x":1,"y":1},"visual":{"character":p.id,"faction":"drawn"}}
		check(art.is_drawn_unit(unit),p.id+" active drawn routing")
		check(art.sprite_size(unit,Vector2i(384,240))==Vector2i(384,320),p.id+" canvas")
		check(art.sprite_offset(unit,Vector2i(384,240))+Vector2(p.pivot[0],p.pivot[1])==Vector2(192,240),p.id+" board ground pivot")
		check(art.processed_sheet_texture_path(p.id,"east","pose:0")==art.processed_sheet_texture_path(p.id,"east","neutral_idle:0"),p.id+" neutral alias")
		check(art.processed_sheet_texture_path(p.id,"east","combat_idle:0")!=art.processed_sheet_texture_path(p.id,"east","pose:0"),p.id+" distinct ready stance")
		check(art.processed_sheet_corpse_visual_action(p.id)=="death:7",p.id+" last corpse frame")
		check(art.clip_seconds(unit,"combat",0.0)>art.impact_seconds(unit,0.0),p.id+" anticipation plus recovery")
		check(is_equal_approx(art.movement_seconds(unit,80.0,0.0),0.5/Art.LOCOMOTION_RATE),p.id+" half-stride at approved runtime pace")
		check(is_equal_approx(art.movement_seconds(unit,320.0,0.0),2.0/Art.LOCOMOTION_RATE),p.id+" 320px travel follows physical stride")
		for walking: String in ["neutral_walk","combat_walk"]:
			check(is_equal_approx(art.clip_seconds(unit,walking,0.0),1.0),p.id+walking+" one-second walking cycle")
		var actions: Array=Catalog.ACTIONS.duplicate()
		if p.id=="knight":
			for extra: String in Catalog.KNIGHT_EXTRAS:
				check(int(p.frame_counts.get(extra,0))>0,"knight additional clip "+extra)
				actions.append(extra)
		var hashes: Dictionary={};var mirrored:=0
		for facing: String in Catalog.DIRECTIONS:
			_idle_contact_test(art,p.id,facing)
			if p.view_sources[facing].kind=="mirror":mirrored+=1
			for action: String in actions:
				var count:=art.processed_sheet_frame_count(p.id,action)
				check(count==int(p.frame_counts[action]),p.id+action+" count")
				for frame in range(count):
					var path:=art.processed_sheet_texture_path(p.id,facing,"%s:%s" % [action,frame])
					check(ResourceLoader.exists(path,"Texture2D"),"imported frame "+path)
					check(is_equal_approx(art.frame_seconds(unit,action,0.0,frame),float(p.durations_ms[action][frame])/1000.0),"authored duration "+path)
					if frame==0 or frame==count-1:
						var image:=Assets.image_copy(path)
						check(image!=null and not image.is_empty(),"nonempty native frame "+path)
						if image!=null:
							var used:=image.get_used_rect()
							check(image.get_size()==Vector2i(384,320) and used.has_area() and used.position.x>0 and used.position.y>0 and used.end.x<384 and used.end.y<320,"native margins "+path)
							if action=="neutral_idle" and frame==0:hashes[image.get_data().hex_encode().sha256_text()]=true
				Assets.clear_texture_cache()
		check(hashes.size()==8 and mirrored==3,p.id+" eight distinct views with disclosed three mirrors")
		if p.id=="archer_1":
			check(is_equal_approx(art.clip_seconds(unit,"attack",0.0),1.8),"bow deliberate1800ms aim and shot")
			check(is_equal_approx(art.impact_seconds(unit,0.0),1.26),"bow release at1260ms after aiming")
		var enemy: Dictionary={"id":"opponent","team":"enemy","position":{"x":2,"y":1},"resources":{"hp":10}}
		check(art.default_visual_action(unit,{"units":[unit,enemy]})=="combat_idle",p.id+" nearby guard")
		var texture:=art.icon(unit,{"units":[unit,enemy]},{unit.id:"east"},{unit.id:"walk:0"},Vector2i(384,240))
		check(texture==Assets.texture(art.processed_sheet_texture_path(p.id,"south_east","combat_walk:0")),p.id+" tactical three-quarter combat-ready walk routing")
		Assets.clear_texture_cache()
	_timeline_test(art)
	await _gallery_test(registry.profiles.size())
	await _battle_test()
	for message in failures:push_error(message)
	print("Drawn animation: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _idle_contact_test(art: Art,character: String,facing: String) -> void:
	for action: String in ["neutral_idle","combat_idle"]:
		var anchor: PackedByteArray;var upper: Dictionary={}
		for frame in range(4):
			var path:=art.processed_sheet_texture_path(character,facing,"%s:%s" % [action,frame])
			var image:=Assets.image_copy(path)
			var foot_image:=image.get_region(Rect2i(0,232,384,88))
			foot_image.convert(Image.FORMAT_RGBA8)
			var feet:=foot_image.get_data()
			# Godot's alpha-border import fills invisible RGB from nearby upper-body
			# colors. Compare all visible RGBA and alpha, ignoring only alpha-zero RGB.
			for i in range(0,feet.size(),4):
				if feet[i+3]==0:feet[i]=0;feet[i+1]=0;feet[i+2]=0
			if frame==0:anchor=feet
			else:check(feet==anchor,"stationary idle foot pixels "+path)
			upper[image.get_region(Rect2i(0,0,384,232)).get_data().hex_encode().sha256_text()]=true
			Assets.clear_texture_cache()
		check(upper.size()>1,"upper-body idle motion retained "+character+facing+action)
func _gallery_test(expected: int) -> void:
	var gallery: Control=load("res://scenes/combat/DrawnAnimationGallery.tscn").instantiate()
	var viewport:=SubViewport.new();viewport.size=Vector2i(1920,1080);root.add_child(viewport)
	viewport.add_child(gallery)
	await process_frame;gallery.set_process(false)
	check(gallery.cards.size()==expected,"gallery includes every complete profile")
	for facing: String in Catalog.DIRECTIONS:
		gallery.direction=facing;gallery.restart()
		for card: Dictionary in gallery.cards:check(card.sprite.texture!=null,"gallery texture "+card.id+facing)
	gallery.select_action("death");gallery.advance(4.0)
	for card: Dictionary in gallery.cards:check(card.frame==7 and card.finished,"gallery finite death "+card.id)
	gallery.advance(8.0)
	for card: Dictionary in gallery.cards:check(card.frame==7,"gallery terminal hold "+card.id)
	gallery.select_action("attack");gallery.advance(2.0)
	for card: Dictionary in gallery.cards:check(card.frame==7 and card.finished,"gallery complete attack "+card.id)
	gallery.step(-1)
	check(not gallery.playing and gallery.cards[0].frame==6,"gallery pause and step")
	gallery._command("Pauza");gallery.advance(2.0)
	check(gallery.cards[0].frame==7 and gallery.cards[0].finished,"gallery resumes a stepped completed action")
	gallery.restart();check(gallery.playing and gallery.cards[0].frame==0,"gallery restart")
	for action: String in Catalog.KNIGHT_EXTRAS:
		check(action in gallery.available_actions,"gallery discovers knight "+action)
		for facing: String in Catalog.DIRECTIONS:
			gallery.direction=facing;gallery.select_action(action);gallery.advance(5.0)
			for card: Dictionary in gallery.cards:
				check(card.box.visible==(card.id=="knight"),"gallery filters unsupported "+card.id+action)
				if card.id=="knight":
					check(card.finished and card.frame==int(Art.PROCESSED_SHEET_VISUALS.knight.frame_counts[action])-1,"gallery completes "+action+facing)
					check(card.sprite.texture==Assets.texture(gallery.art.processed_sheet_texture_path("knight",facing,"%s:%s" % [action,card.frame])),"gallery extra view routing "+action+facing)
	gallery.select_action("neutral_walk")
	for card: Dictionary in gallery.cards:check(card.box.visible,"gallery restores complete roster "+card.id)
	viewport.queue_free();await process_frame

func _timeline_test(art: Art) -> void:
	var units: Dictionary={"a":{"id":"a","visual":{"character":"knight","faction":"drawn"}},"b":{"id":"b","visual":{"character":"knight","faction":"drawn"}}}
	var events: Array=[{"type":"hit_roll_resolved","actor_id":"a","target_unit_id":"b","outcome":"hit"},
		{"type":"damage_applied","actor_id":"a","target_unit_id":"b","hp_after":0},
		{"type":"status_applied","target_unit_id":"b"}]
	var plan:=Timeline.build(events,units,art)
	check(plan.actors.size()==1 and plan.impacts.size()==1,"roll and damage coalesce into one attack")
	check(plan.impacts[0].reactions.b=="death","later status cannot replace death")
	check(is_equal_approx(plan.impacts[0].at,0.45),"reaction waits for authored impact cue")
	check(plan.duration>1.9,"complete fall plus final hold before unlock")
	var miss:=Timeline.build([events[0]],units,art)
	check(miss.impacts[0].reactions.is_empty() and is_equal_approx(miss.duration,0.97),"miss retains complete attack without victim recoil")
	var dot:=Timeline.build([{"type":"damage_applied","source_status_id":"bleeding","target_unit_id":"b","hp_after":0}],units,art)
	check(dot.actors.is_empty() and dot.impacts[0].at==0.0,"damage over time does not invent an attacker")
	check(not Timeline.uses_drawn([{"type":"status_applied","actor_id":"a","target_unit_id":"a"}],units,art),"status-only command retains immediate lifecycle")
	units.a.visual.character="archer_1"
	var bow:=Timeline.build([events[0]],units,art)
	check(is_equal_approx(bow.impacts[0].at,1.26),"bow timeline waits for completed draw and aim")
	check(is_equal_approx(bow.duration,1.8),"bow timeline retains release and follow-through")

func _battle_fixture(hud: Control, wounded: bool = false) -> void:
	hud.state=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/debug_full_combat_showcase.json"))
	var hero: Dictionary=hud.state.units[0].duplicate(true)
	var enemy: Dictionary=hud.state.units[1].duplicate(true)
	hero.position={"x":0,"y":0};enemy.position={"x":1,"y":0}
	hero.visual={"character":"knight","faction":"heroes"};enemy.visual={"character":"knight","faction":"villains"}
	if wounded:enemy.resources.hp=1
	hud.state.units=[hero,enemy];hud.state.turn_state.turn_order=[hero.id,enemy.id]
	hud.state.turn_state.active_unit_id=hero.id
	hud.state.event_log=[];hud.unit_visual_action.clear();hud.idle_elapsed.clear()
	hud._prepare_presentation_cache();hud._render()

func _battle_test() -> void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(1920,1080);root.add_child(viewport)
	var hud: Control=load("res://scenes/combat/CombatDebug.tscn").instantiate();viewport.add_child(hud)
	await process_frame
	_battle_fixture(hud)
	var unchanged: Dictionary=hud.state.duplicate(true)
	var gallery: Control=load("res://scenes/combat/DrawnAnimationGallery.tscn").instantiate()
	gallery.embedded=true;hud.add_child(gallery);await process_frame
	check(not hud.is_processing_input(),"embedded gallery suppresses battle shortcuts")
	gallery._command("Zamknij");await process_frame
	check(hud.is_processing_input() and hud.state==unchanged,"gallery close restores game without leaving battle")
	hud._advance_original_idle()
	check(str(hud.unit_visual_action.get("unit_player_001","")).begins_with("combat_idle"),"periodic idle preserves guard")
	var before: int=hud._unit_by_id("unit_enemy_001").resources.hp
	hud._run_command(hud._build_command("basic_attack",{"type":"unit","unit_id":"unit_enemy_001"}))
	check(hud.animation_locked,"resolver attack starts presentation lock")
	await create_timer(0.20).timeout
	check(int(hud._display_resources(hud._unit_by_id("unit_enemy_001")).hp)==before,"HP display waits through anticipation")
	check(not str(hud.unit_visual_action.get("unit_enemy_001","")).begins_with("hit"),"victim does not recoil before impact")
	var seen: Dictionary={};var start:=Time.get_ticks_msec()
	while hud.animation_locked and Time.get_ticks_msec()-start<4000:
		seen[str(hud.unit_visual_action.get("unit_player_001",""))]=true
		seen[str(hud.unit_visual_action.get("unit_enemy_001",""))]=true
		await process_frame
	check(not hud.animation_locked and seen.has("combat:7") and seen.has("hit:3"),"complete attack and hit before unlock")
	check(int(hud._unit_by_id("unit_enemy_001").resources.hp)<before,"resolver HP result committed")
	_battle_fixture(hud,true)
	hud._run_command(hud._build_command("basic_attack",{"type":"unit","unit_id":"unit_enemy_001"}))
	seen.clear();start=Time.get_ticks_msec()
	while hud.animation_locked and Time.get_ticks_msec()-start<4000:
		seen[str(hud.unit_visual_action.get("unit_enemy_001",""))]=true
		await process_frame
	check(not hud.animation_locked and seen.has("death:7"),"wounded resolver fixture reaches complete fall")
	check(hud._unit_by_id("unit_enemy_001").resources.hp==0,"resolver death remains terminal")
	_battle_fixture(hud)
	hud._run_command(hud._build_command("basic_attack",{"type":"unit","unit_id":"unit_enemy_001"}))
	await create_timer(0.1).timeout
	hud._reset_debug_encounter()
	var reset_state: Dictionary=hud.state.duplicate(true)
	await create_timer(1.1).timeout
	check(hud.state==reset_state and not hud.animation_locked,"generation reset cancels pending damage/commit")
	viewport.queue_free();await process_frame

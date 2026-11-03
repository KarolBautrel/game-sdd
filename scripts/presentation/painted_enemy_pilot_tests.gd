extends SceneTree
## New actors' actual textures, complete playback and legal battle outcomes.
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const Actions := preload("res://scripts/presentation/combat/combat_action_model.gd")
const Catalog := preload("res://scripts/presentation/combat/tactical_actor_catalog.gd")
const Timeline := preload("res://scripts/presentation/combat/drawn_combat_timeline.gd")
const Text := preload("res://scripts/presentation/combat/combat_text.gd")
const PATH := "res://resources/data/combat_encounters/painted_enemy_pilot.json"
var checks := 0
var failures: Array[String] = []
var sessions: Array[Dictionary] = []
var battles: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func fixture() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	var art := Art.new()
	check(data.profiles.size() == 3, "all three source-complete roles enabled")
	var named := fixture()
	var names: Dictionary = {}
	for unit: Dictionary in named.units:names[Text.unit_display_name(named, unit.id)] = true
	check(names.size() == 7, "all seven review actors have distinct readable names")
	for p: Dictionary in data.profiles:
		check(p.facings == Art.TACTICAL_DIRECTIONS and p.source_roundtrip, p.id + " honest two-view contract")
		var unit := {"id":"sample", "team":"enemy", "position":{"x":1,"y":1}, "visual":{"faction":"villains", "character":p.id}, "resources":{"hp":10}}
		check(art.is_drawn_unit(unit), p.id + " active drawn timeline")
		check(is_equal_approx(art.movement_seconds(unit, 160.0, 0.0), 1.0), p.id + " calm one-second160px stride")
		check(art.processed_sheet_texture_path(p.id, "north", "pose:0").is_empty(), p.id + " no invented north drawing")
		for side: String in p.facings:
			for action: String in p.frame_counts:
				var contacts: Dictionary = {}
				var first_contact: PackedByteArray
				for n in range(int(p.frame_counts[action])):
					var image := Assets.image_copy(art.processed_sheet_texture_path(p.id, side, "%s:%s" % [action,n]))
					check(image != null and image.get_size() == Vector2i(384,320), p.id + side + action + str(n) + " native image")
					if image == null: continue
					var used := image.get_used_rect()
					check(used.has_area() and used.position.x >= 3 and used.position.y >= 3 and used.end.x < 382 and used.end.y < 318, p.id + side + action + str(n) + " alpha/margins")
					var lower := image.get_region(Rect2i(0,int(p.idle_lock_y),384,320-int(p.idle_lock_y)))
					var lower_data := _visible_data(lower)
					var hash := lower_data.hex_encode().sha256_text()
					contacts[hash] = true
					if n == 0:
						first_contact = lower_data
					elif action in ["neutral_idle","combat_idle"]:
						check(lower_data == first_contact, p.id + side + action + " planted visible RGBA contact")
					if action == "neutral_idle" and n == 0:
						check(used.size.y >= 80 and used.size.y <= 105 if p.id == "painted_wolf" else used.size.y >= 165 and used.size.y <= 180, p.id + " species-appropriate body scale")
				if action in ["neutral_walk","combat_walk"]:
					check(contacts.size() >= 4, p.id + side + action + " moving articulated feet/paws")
		check(art.impact_seconds(unit, 0.0) < art.clip_seconds(unit,"combat",0.0), p.id + " anticipation and recovery")
	check(art.unit_visual_config({"id":"archer","archetype_id":"raider_archer"}).character == "painted_bandit_archer", "normal campaign archer role remaps")
	check(art.unit_visual_config({"id":"guard","archetype_id":"raider_shieldman","visual":{"character":"bandit_spearman"}}).character == "painted_bandit_guard", "shield role uses sword/shield appearance")
	check(art.unit_visual_config({"id":"brute","visual":{"character":"bandit_brute"}}).character == "bandit_brute", "ordinary cleaver brute not given an unrelated shield")
	check(art.unit_visual_config({"id":"wolf","visual":{"character":"wolf_atlas"}}).character == "painted_wolf", "existing wolf appearance remaps")
	for id: String in ["bandit_archer","bandit_brute","wolf_atlas"]:
		check(ResourceLoader.exists(art.processed_sheet_texture_path(id,"north","pose:0")), id + " original eight-view archive retained")
	_simulate(false)
	_simulate(true)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	root.add_child(viewport)
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	await process_frame
	for p: Dictionary in data.profiles:
		for side: String in p.facings:
			var id := _pair(hud, p.id, side, false)
			hud._run_command(hud._build_command("move", {"type":"tile","position":{"x":5,"y":6}}))
			var seen: Dictionary = await _watch(hud,id)
			check(hud._unit_by_id(id).position == {"x":5,"y":6} and seen.has(id+"/walk:7"), p.id + side + " complete north walk and commit")
			id = _pair(hud,p.id,side,false)
			var action := "ranged_attack" if p.id == "painted_bandit_archer" else "basic_attack"
			hud._run_command(hud._build_command(action,{"type":"unit","unit_id":"enemy_pilot_target"}))
			seen = await _watch(hud,id)
			check(seen.has(id+"/combat:7") and seen.has("enemy_pilot_target/hit:3"), p.id + side + " full attack and recoil")
			check(hud._unit_by_id("enemy_pilot_target").resources.hp < 40, p.id + side + " resolver damage committed")
			id = _pair(hud,p.id,side,true)
			hud._run_command(hud._build_command(action,{"type":"unit","unit_id":"enemy_pilot_target"}))
			seen = await _watch(hud,id)
			check(seen.has("enemy_pilot_target/death:7") and hud._combat_result() == "victory", p.id + side + " complete death and legal victory")
			var sprite: TextureRect = hud.unit_layer.get_node("enemy_pilot_target/Sprite")
			check(sprite.texture.resource_path.ends_with("_death_007.png"), p.id + side + " corpse holds final frame")
			if p.id == "painted_bandit_guard":
				id = _pair(hud,p.id,side,false)
				var units := {id:hud._unit_by_id(id)}
				check(Timeline.uses_drawn([{"type":"status_applied","target_unit_id":id}],units,art), "authored shield brace uses complete timeline")
				hud._run_command(hud._build_command("shield_wall",{"type":"unit","unit_id":id}))
				seen = await _watch(hud,id)
				check(seen.has(id+"/status_reaction:3") and seen.has("block_texture"), side + " full shield brace visible")
			sessions.append({"role":p.id,"side":side,"walk_attack_hit_death":true,"visual_acceptance":"NOT_RUN"})
	hud.queue_free();viewport.queue_free()
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://artifacts/tactical-batch")
	var out := FileAccess.open("res://artifacts/tactical-batch/runtime.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"role_sessions":sessions,"legal_battles":battles,"physical_gameplay":"NOT_RUN","desktop_input":false},"\t"));out.close()
	for failure in failures: push_error(failure)
	print("Painted enemy pilot: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _visible_data(image: Image) -> PackedByteArray:
	# Godot import may fill RGB beyond alpha0 edges. Visible RGBA stays exact.
	var data := image.get_data()
	for n in range(3,data.size(),4):
		if data[n] == 0:
			data[n-3] = 0;data[n-2] = 0;data[n-1] = 0
	return data


func _pair(hud: Control, role: String, side: String, lethal: bool) -> String:
	var state := fixture();state.seed = 2001
	var actor: Dictionary = {}
	for unit: Dictionary in state.units:
		if hud.unit_art.unit_visual_config(unit).character == role:
			actor = unit.duplicate(true);break
	actor.team = "player";actor.position = {"x":5,"y":8}
	actor.resources.ap = 2;actor.stats.max_ap = 2;actor.stats.accuracy = 100
	var target := actor.duplicate(true)
	target.id = "enemy_pilot_target";target.team = "enemy"
	target.position = {"x":4 if side == "south_west" else 6,"y":8}
	target.resources.hp = 1 if lethal else 40;target.stats.max_hp = 40
	state.units = [actor,target]
	state.turn_state = {"active_unit_id":actor.id,"round":1,"turn_order":[actor.id,target.id]}
	for tile: Dictionary in state.grid.tiles:
		if int(tile.x) in [4,5,6] and int(tile.y) in [6,7,8]:tile.type = "floor"
	hud.authoring_draft = state;hud._reset_debug_encounter()
	return actor.id


func _watch(hud: Control, id: String) -> Dictionary:
	var seen: Dictionary = {};var until := Time.get_ticks_msec()+6000
	while hud.animation_locked and Time.get_ticks_msec()<until:
		for unit_id: String in [id,"enemy_pilot_target"]:
			var action := str(hud.unit_visual_action.get(unit_id,""))
			var key := unit_id+"/"+action
			if not seen.has(key):
				var sprite: TextureRect = hud.unit_layer.get_node(NodePath(unit_id+"/Sprite"))
				check(sprite.texture != null and (sprite.texture.resource_path.contains("_south_east_") or sprite.texture.resource_path.contains("_south_west_")), "actual two-view playback "+key)
				if sprite.texture.resource_path.contains("/block/"):seen.block_texture = true
				seen[key] = true
		await process_frame
	check(not hud.animation_locked,"new actor animation unlocks")
	return seen


func _simulate(passive: bool) -> void:
	var state: Dictionary = Resolver.simulate(fixture(),[]).state
	var outcome: Dictionary = {};var count := 0
	for n in range(800):
		var actor: Dictionary = Actions.unit_by_id(state,state.turn_state.active_unit_id)
		var policy := state.duplicate(true)
		if actor.team == "player":
			for row: Dictionary in policy.units:row.team = "enemy" if row.team == "player" else "player"
		var command: Dictionary = Resolver.choose_enemy_command(policy,"painted_enemy_%s" % n)
		if passive and actor.team == "player":command.action_id = "end_turn";command.target = {"type":"none"}
		outcome = Resolver.simulate(state,[command]);state = outcome.state;count += 1
		for event: Dictionary in state.event_log:check(event.type != "command_rejected","legal full pilot command%s" % n)
		if outcome.result != "in_progress":break
	check(outcome.get("result") == ("defeat" if passive else "victory"), "ordinary full pilot reaches expected result")
	battles.append({"policy":"passive_players" if passive else "both_teams_existing_ai","result":outcome.get("result"),"commands":count,"debug_win":false})

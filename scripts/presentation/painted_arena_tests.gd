extends SceneTree
## Normal deterministic resolver battles on canonical authored maps.
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const Actions := preload("res://scripts/presentation/combat/combat_action_model.gd")
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const EnvironmentArt := preload("res://scripts/presentation/combat/environment_art.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const Text := preload("res://scripts/presentation/combat/combat_text.gd")
const ARENAS := ["painted_forest_ambush", "painted_mine_breach"]
var checks := 0
var failures: Array[String] = []
var battles: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func _run() -> void:
	var art := Art.new()
	for id: String in ARENAS:
		var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/"+id+".json"))
		var loaded: Dictionary = Resolver.simulate(fixture, []).state
		check(loaded.grid.width == 14 and loaded.grid.height == 11, id+" materializes canonical map")
		check(loaded.units.size() == 7, id+" seven preserved actors")
		var names: Dictionary={}
		for unit: Dictionary in loaded.units:
			names[Text.unit_display_name(loaded,unit.id)]=true
			check(art.is_drawn_unit(unit), id+" accepted painted actor "+unit.id)
			check(is_equal_approx(art.movement_seconds(unit,160.0,0.0),1.0/Art.LOCOMOTION_RATE), id+" consistent runtime gait "+unit.id)
		check(names.size()==7,id+" seven distinct unit captions")
		var theme: String=loaded.terrain_theme
		var floor_image:=EnvironmentArt.board(loaded,Vector2i(128,128),theme).get_image()
		var expected:=Assets.image_copy(EnvironmentArt.data().floors.woodland if theme=="nature" else EnvironmentArt.data().floors.flagstone)
		check(floor_image.get_pixel(17,23).is_equal_approx(expected.get_pixel(17,23)),id+" correct floor material")
		# A plain safe first step and a blocked target exercise real terrain legality.
		var cmd := {"id":"arena_move", "type":"perform_action", "actor_id":"unit_knight_pilot", "action_id":"move", "target":{"type":"tile", "position":{"x":3,"y":7}}}
		var moved: Dictionary = Resolver.simulate(loaded,[cmd]).state
		check(Actions.unit_by_id(moved,"unit_knight_pilot").position == {"x":3,"y":7}, id+" legal first step")
		check(Actions.unit_by_id(moved,"unit_knight_pilot").resources.mp == 3, id+" one floor step costs1MP")
		for tile: Dictionary in loaded.grid.tiles:
			if tile.type == "blocked":
				cmd.target.position = {"x":tile.x,"y":tile.y}
				var blocked: Dictionary = Resolver.simulate(loaded,[cmd]).state
				check(Actions.unit_by_id(blocked,"unit_knight_pilot").position == Actions.unit_by_id(loaded,"unit_knight_pilot").position, id+" blocked destination cannot move actor")
				check(Actions.unit_by_id(blocked,"unit_knight_pilot").resources.mp == 4, id+" blocked destination spends noMP")
				break
		_simulate(fixture,false)
		_simulate(fixture,true)
	DirAccess.make_dir_recursive_absolute("res://artifacts/painted-arenas")
	var out := FileAccess.open("res://artifacts/painted-arenas/battles.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"battles":battles,"physical_gameplay":"NOT_RUN"},"\t"));out.close()
	for failure in failures: push_error(failure)
	print("Painted arenas: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _simulate(fixture: Dictionary, passive: bool) -> void:
	var state: Dictionary = Resolver.simulate(fixture,[]).state
	var outcome: Dictionary = {};var count := 0
	for n in range(800):
		var actor: Dictionary = Actions.unit_by_id(state,state.turn_state.active_unit_id)
		var policy := state.duplicate(true)
		if actor.team == "player":
			for row: Dictionary in policy.units:row.team = "enemy" if row.team == "player" else "player"
		var command: Dictionary = Resolver.choose_enemy_command(policy,"arena_%s" % n)
		if passive and actor.team == "player":command.action_id = "end_turn";command.target = {"type":"none"}
		outcome = Resolver.simulate(state,[command]);state = outcome.state;count += 1
		for event: Dictionary in state.event_log:check(event.type != "command_rejected",fixture.id+" legal command%s" % n)
		if outcome.result != "in_progress":break
	check(outcome.get("result") == ("defeat" if passive else "victory"),fixture.id+" expected normal outcome")
	battles.append({"arena":fixture.id,"policy":"passive_players" if passive else "both_teams_existing_ai","result":outcome.get("result"),"commands":count,"debug_win":false})

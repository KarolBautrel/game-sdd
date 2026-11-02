extends SceneTree

const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Quality := preload("res://scripts/domain/dungeon_graph_quality.gd")


func _init() -> void:
	var failures: Array[String] = []
	var templates: Array = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/dungeon_templates/generated_old_mine_templates.json")).templates
	var accepted: Dictionary = templates[0].duplicate(true)
	var candidate := accepted.duplicate(true)
	candidate["acceptance_state"] = "candidate"
	candidate["id"] = "unreviewed_candidate"
	var unknown := accepted.duplicate(true)
	unknown.erase("acceptance_state")
	for seed in range(1, 101):
		_check(failures, Model.select_accepted_template(seed, 1, "short_mine", [candidate, accepted, unknown]).id == accepted.id, "candidate selection")
	_check(failures, Model.select_accepted_template(1, 1, "short_mine", [candidate, unknown]).is_empty(), "candidate-only pool fails closed")
	_check(failures, Model.select_accepted_template(1, 1, "absent_profile", templates).is_empty(), "missing profile fails closed")
	var empty_hud: Node = load("res://scripts/presentation/dungeon_debug.gd").new()
	empty_hud._start_expedition_with_loadout()
	_check(failures, not empty_hud.expedition_started, "empty layout cannot start expedition")
	empty_hud.free()
	for mutation in ["duplicate", "position", "disconnect", "edge", "entrance", "exit", "combat"]:
		var broken := accepted.duplicate(true)
		match mutation:
			"duplicate": broken.rooms.append(broken.rooms[0].duplicate(true))
			"position": broken.rooms[1].position = broken.rooms[0].position.duplicate()
			"disconnect": broken.corridors.clear()
			"edge": broken.corridors[0].to = "missing"
			"entrance": broken.rooms[0].kind = "empty"
			"exit": broken.rooms[-1].kind = "empty"
			"combat":
				for room: Dictionary in broken.rooms:
					room.content = [{"type": "empty"}]
		_check(failures, not Quality.errors(broken).is_empty(), "reject broken " + mutation)
	var records: Array[Dictionary] = []
	var coverage: Dictionary = {}
	for profile: String in ["short_mine", "medium_mine", "deep_mine"]:
		coverage[profile] = []
		for seed in range(1, 101):
			var config := {"seed": seed, "profile_id": profile}
			var dungeon := Model.procedural_dungeon_draft(config)
			var seed_errors := Quality.errors(dungeon, profile == "deep_mine")
			if dungeon != Model.procedural_dungeon_draft(config): seed_errors.append("nondeterministic")
			for room: Dictionary in dungeon.get("rooms", []):
				for content: Dictionary in room.get("content", []):
					if content.get("type") in ["combat", "guarded_treasure"] and not FileAccess.file_exists(str(content.get("combat_encounter_path", ""))):
						seed_errors.append("missing encounter path")
					if content.get("type") == "room_event" and Model._materialize_room_event(str(room.id), content).is_empty():
						seed_errors.append("unresolved room event")
			for corridor: Dictionary in dungeon.get("corridors", []):
				for ref: Dictionary in corridor.get("hazard_pool_refs", []):
					if Model._materialize_hazard_pool_ref(corridor, ref).is_empty(): seed_errors.append("unresolved hazard")
			var id := str(dungeon.get("template_id", ""))
			if not coverage[profile].has(id): coverage[profile].append(id)
			records.append({"profile": profile, "seed": seed, "template_id": id, "errors": seed_errors})
			for failure in seed_errors: failures.append("%s seed%s: %s" % [profile, seed, failure])
		_check(failures, coverage[profile].size() >= 3, "template diversity " + profile)
	var report := {"schema": "sdd.generation-sweep-v1", "seeds_per_profile": 100, "coverage": coverage, "records": records, "failures": failures, "status": "PASS" if failures.is_empty() else "FAIL"}
	DirAccess.make_dir_recursive_absolute("res://artifacts/qa-runs")
	var file := FileAccess.open("res://artifacts/qa-runs/generation-seed-sweep.json", FileAccess.WRITE)
	if file == null:
		failures.append("Cannot save seed sweep evidence")
	else:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("Generation quality: 300 deterministic seeds PASS; ", JSON.stringify(coverage))
	quit(0 if failures.is_empty() else 1)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	if not condition: failures.append(label)

extends SceneTree
## Reproducible authored offline fixtures, not captured external-model inference.
const M := preload("res://scripts/domain/strategist_campaign.gd")
const Recorded := preload("res://scripts/domain/recorded_strategist.gd")
func write(path: String, value: Variant) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)+"\n");file.close();return true
func _initialize() -> void:
	var state := M.initial()
	for cmd: Array in [["model_mode",{"mode":"recorded"}],["advance",{"ticks":192}],["advance",{"ticks":72}]]:
		var result := M.apply(state,M.command(state,cmd[0],cmd[1]))
		if not result.ok: push_error(result.reason);quit(1);return
		state=result.state
	var q: Dictionary=state.strategist.pending.values()[0].request
	for cmd: Array in [["model_dispatch",{"request_id":q.request_id}],["model_reply",{"request_id":q.request_id,"raw":Recorded.reply(q)}]]:
		var result := M.apply(state,M.command(state,cmd[0],cmd[1]))
		if not result.ok: push_error(result.reason);quit(1);return
		state=result.state
	var commands := [M.command(state,"advance",{"ticks":24})]
	var replay := M.replay(state,commands)
	var ok: bool=replay.ok and write("res://resources/data/strategist_campaigns/reference_2087.json",state) and write("res://resources/data/strategist_requests/cinder_2087.json",q) and write("res://resources/data/strategist_replies/cinder_2087.json",JSON.parse_string(Recorded.reply(q))) and write("res://resources/data/strategist_replays/mine_region_2087.json",{"schema":"sdd.strategist-replay","version":1,"checkpoint":"res://resources/data/strategist_campaigns/reference_2087.json","commands":commands,"expected_digest":M.A.P.digest(replay.state)})
	print("strategist_fixture_export: ",ok);quit(0 if ok else 1)

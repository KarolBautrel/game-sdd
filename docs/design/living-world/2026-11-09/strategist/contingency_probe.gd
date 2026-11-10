extends SceneTree
## Supplementary runtime evidence on alternate recorded replies; not live inference.
const M := preload("res://scripts/domain/strategist_campaign.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func _initialize() -> void:
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategist_campaigns/reference_2087.json"))
	var actor: String=saved.strategist.pending.keys()[0]
	var original: Dictionary=saved.strategist.pending[actor].reply
	# Reply queueing has no world effects: undo only that last command to obtain
	# the exact pre-reply checkpoint, then submit each alternative through authority.
	var before := saved.duplicate(true);before.request_seq-=1;before.request_receipts.pop_back()
	before.strategist.pending[actor].status="sent";before.strategist.pending[actor].reply={}
	check(M.valid(before),"actual pre-reply checkpoint")
	var cases: Array=[]
	for predicate: String in ["food_below_target","at_war"]:
		var reply := original.duplicate(true);reply.intent_ids=[]
		reply.contingencies=[{"predicate":predicate,"intent_id":original.intent_ids[0]}]
		var queued := M.apply(before,M.command(before,"model_reply",{"request_id":reply.request_id,"raw":M.A.P.encoded(reply)}))
		check(queued.ok,"conditional reply is structurally legal")
		var applied := M.apply(queued.state,M.command(queued.state,"advance",{"ticks":24}))
		check(applied.ok and applied.state.strategist.totals.accepted==1,"conditional proposal accepted at normal boundary")
		if not applied.ok: continue
		var count: int=applied.state.strategist.journal[0].executions.size()
		check(count==(1 if predicate=="food_below_target" else 0),"only an actual true predicate attempts the candidate")
		check(M.A.C.S.reconciles(applied.state.strategy_world),"conditional operators preserve actual accounting")
		cases.append({"predicate":predicate,"attempted_intents":count})
	var file := FileAccess.open("res://docs/design/living-world/2026-11-09/strategist/contingencies.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"headless":true},"\t",true,true)+"\n");file.close()
	for failure: String in failures: push_error(failure)
	print("contingency_probe: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)

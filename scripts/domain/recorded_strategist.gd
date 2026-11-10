extends RefCounted
## Authored local examples, deliberately not presented as external-model output.
const P := preload("res://scripts/domain/strategist_protocol.gd")
static func reply(q: Dictionary) -> String:
	if not P.request_valid(q): return ""
	var examples: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategists/recorded_examples_v1.json"))
	var preferred: String=examples.preferred_goals.get(q.faction_id,examples.default_goal)
	var selected := ""
	for id: String in P.C.S.sorted_ids(q.capabilities.goals):
		if q.capabilities.goals[id].goal==preferred:
			selected=id
			if q.capabilities.goals[id].resource=="food": break
	if selected=="":
		for id: String in q.capabilities.goals:
			if q.capabilities.goals[id].goal=="hold": selected=id;break
	var result := {"schema":"sdd.strategist-reply","version":1,"decision_id":"decision_%08d" % int(q.number),"goal_id":selected,"intent_ids":[],"supporting":["trade","guard"],"contingencies":[],"reason_code":"reserve_deficit" if preferred=="supplies" else ("profitable_exports" if preferred=="commerce" else "rebuild_reserves"),"cited_events":[],"public_summary":"Authored offline example: maintain reserves and honour lawful trade."}
	for field: String in ["policy_version","request_id","faction_id","generation","observation_tick","apply_by_tick","requested_review_tick","horizon_tick","observation_hash"]: result[field]=q[field]
	for id: String in P.C.S.sorted_ids(q.capabilities.intents):
		if q.capabilities.intents[id].action in ["propose_trade","accept_trade","reject_trade","propose_pact","accept_pact","reject_pact","accept_peace","reject_peace","propose_peace","protect_route"]: result.intent_ids.append(id)
		if result.intent_ids.size()==2: break
	return P.encoded(result)

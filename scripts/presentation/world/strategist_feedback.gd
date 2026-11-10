extends RefCounted
## Read-only UI projection. A recorded plan is distinct from a committed action.
const FALLBACK := {"missing":"No reply arrived.","timeout":"The reply timed out.","interrupted":"The request was interrupted.","budget":"The request limit was reached.","stale":"World conditions changed.","committed_plan":"The current plan is still committed."}
static func blocked_reason(code: String) -> String:
	if code in ["mobilization_unfunded","trade_unfunded","insufficient_manpower"]: return "Current resources did not allow execution."
	if code in ["trade_route_closed","unreachable_border","hostile_escort_route"]: return "A suitable route was unavailable."
	if code=="force_not_ready": return "A force was not ready."
	if code in ["trade_not_pending","peace_not_pending","not_recipient"]: return "The offer was no longer available."
	return "Current world conditions blocked execution."
static func project(s: Dictionary) -> Dictionary:
	var a: Dictionary=s.strategist
	var result := {"mode":"Recorded examples (offline)" if a.mode=="recorded" else "Classic policy","plans":int(a.totals.accepted),"pending":a.pending.size(),"fallback":int(a.totals.fallback),"fallback_reason":"","applied":0,"blocked":0,"last_tick":-1,"last":"No recorded review yet.","due":-1,"due_label":"Next review starts","why":""}
	for record: Dictionary in a.journal:
		if record.outcome=="fallback": result.fallback_reason=FALLBACK.get(record.reason,"The reply could not be used.")
		for action: Dictionary in record.executions:
			if action.reason=="": result.applied+=1
			else: result.blocked+=1
	if a.mode=="recorded":
		result.due=int(a.next_review.values().min())
		if not a.pending.is_empty():
			result.due=-1;result.due_label="Next result due"
			for pending: Dictionary in a.pending.values():
				var tick := int(pending.request.apply_by_tick)
				if result.due<0 or tick<result.due: result.due=tick
	if a.journal.is_empty(): return result
	var latest: Dictionary=a.journal.back();var applied := 0;var blocked := 0
	result.last_tick=int(latest.tick)
	var faction: String=s.strategy_world.core.factions[latest.faction_id].name
	for action: Dictionary in latest.executions:
		if action.reason=="": applied+=1
		else: blocked+=1;result.why=blocked_reason(action.reason)
	if latest.outcome=="accepted":
		result.last="%s: plan accepted. Actions applied: %d; blocked: %d." % [faction,applied,blocked]
		if latest.executions.is_empty(): result.why="This review selected no immediate action."
	elif latest.outcome=="fallback": result.last=faction+": classic policy used. "+FALLBACK.get(latest.reason,"The reply could not be used.")
	else: result.last=faction+": pending review cancelled by a mode change."
	return result

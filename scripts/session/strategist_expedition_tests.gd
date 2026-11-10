extends "res://scripts/session/regional_expedition_tests.gd"
## Same genuine managed chain on the distinct v4 owner, with a queued proposal.
func _create_session(session: RefCounted, file: String) -> bool:
	if not session.create_model(2087,file,false): return false
	check(session.regional("model_mode",{"mode":"recorded"}),"enable authored adapter before managed journey")
	check(session.regional("advance",{"ticks":192}),"ordinary strategic time before expedition")
	check(session.regional("advance",{"ticks":72}),"first bounded request before expedition")
	check(session.pump_model(),"queue authored reply without time advancement")
	return true
func _world_scene() -> String: return "res://scenes/world/StrategistWorld.tscn"
func _output() -> String: return "res://artifacts/qa-runs/strategist-expedition"
func _suite() -> String: return "strategist_expedition_tests"

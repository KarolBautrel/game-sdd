extends "res://scripts/session/regional_expedition_tests.gd"
## The existing ordinary managed mine chain on its own new Vast-size profile.
func _create_session(session: RefCounted, file: String) -> bool: return session.create_model(2087,file,false,"marches",3)
func _world_scene() -> String: return "res://scenes/world/StrategistVastWorld.tscn"
func _output() -> String: return "res://artifacts/qa-runs/vast-expedition"
func _suite() -> String: return "vast_expedition_tests"

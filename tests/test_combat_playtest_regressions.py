"""Regressions observed in ordinary desktop Painted Six play (combat104/105)."""
from copy import deepcopy
import json
from pathlib import Path
import unittest

from tools.combat.simulate_combat import choose_enemy_command, simulate

ROOT = Path(__file__).resolve().parents[1]


def fixture(name):
    return json.loads((ROOT / f"resources/data/combat_encounters/{name}.json").read_text())


def command(actor, action, target):
    return {"id": "cmd_regression", "type": "perform_action", "actor_id": actor,
            "action_id": action, "target": target}


def bow(fallback=False):
    state = fixture("slice_63_aimed_shot_from_bow")
    if fallback:
        state.pop("item_profiles")
        state["units"][0].pop("loadout")
        state["units"][0]["available_actions"] += ["ranged_attack", "aimed_shot"]
    return state


def tile(state, x, y, kind):
    next(t for t in state["grid"]["tiles"] if (t["x"], t["y"]) == (x, y))["type"] = kind


class CombatPlaytestRegressions(unittest.TestCase):
    def test_ai_fallback_obeys_weighted_terrain_budget(self):
        for mp, terrain in [(1, "highground"), (2, "highground"), (1, "floor"), (None, "highground")]:
            with self.subTest(mp=mp, terrain=terrain):
                state = fixture("slice_62_enemy_ai_move_then_attack")
                enemy = state["units"][1]
                if mp is None:
                    enemy["resources"].pop("mp")
                else:
                    enemy["resources"]["mp"] = mp
                for entry in state["grid"]["tiles"]:
                    if entry["x"] == 2:
                        entry["type"] = terrain
                before = deepcopy(state)
                chosen = choose_enemy_command(state)
                expected = "end_turn" if mp == 1 and terrain == "highground" else "move"
                self.assertEqual(chosen["action_id"], expected)
                self.assertEqual(choose_enemy_command(state), chosen)
                self.assertEqual(state, before)
                resolved = simulate(state, [chosen]).state
                self.assertNotIn("command_rejected", [e["type"] for e in resolved["event_log"]])
                after = resolved["units"][1]
                if expected == "end_turn":
                    self.assertEqual(after, enemy)
                    self.assertNotEqual(resolved["turn_state"]["active_unit_id"], enemy["id"])
                else:
                    self.assertEqual(after["position"]["x"], 2)
                    self.assertEqual(after["resources"]["ap"], 0 if mp is None else 1)
                    if mp is not None:
                        self.assertEqual(after["resources"]["mp"], 0)

    def test_blocked_aimed_and_basic_shots_are_atomic(self):
        for fallback in [False, True]:
            for x in [2, 3]:
                for action in ["ranged_attack", "aimed_shot"]:
                    with self.subTest(fallback=fallback, x=x, action=action):
                        state = bow(fallback)
                        tile(state, x, 1, "blocked")
                        before = deepcopy(state)
                        result = simulate(state, [command("unit_player_001", action,
                                                          {"type": "unit", "unit_id": "unit_enemy_001"})])
                        self.assertEqual(state, before)
                        self.assertEqual(result.state["units"], before["units"])
                        self.assertEqual(result.state["turn_state"], before["turn_state"])
                        self.assertEqual(result.state["seed"], before["seed"])
                        self.assertEqual([e["type"] for e in result.state["event_log"]],
                                         ["combat_started", "turn_started", "command_rejected"])
                        self.assertEqual(result.state["event_log"][-1]["reason"], "target_not_visible")

    def test_clear_lines_and_endpoints_remain_legal(self):
        for x, kind in [(2, "floor"), (2, "highground"), (2, "cover_low"),
                        (1, "blocked"), (4, "blocked")]:
            for action in ["ranged_attack", "aimed_shot"]:
                with self.subTest(x=x, kind=kind, action=action):
                    state = bow()
                    tile(state, x, 1, kind)
                    result = simulate(state, [command("unit_player_001", action,
                                                      {"type": "unit", "unit_id": "unit_enemy_001"})])
                    self.assertNotIn("command_rejected", [e["type"] for e in result.state["event_log"]])
                    self.assertEqual(result.state["units"][0]["resources"]["ap"], 0 if action == "aimed_shot" else 1)

    def test_range_rejection_keeps_precedence(self):
        state = bow()
        state["item_profiles"]["hunting_bow"]["action_profiles"]["aimed_shot"]["range"] = 2
        tile(state, 2, 1, "blocked")
        result = simulate(state, [command("unit_player_001", "aimed_shot",
                                          {"type": "unit", "unit_id": "unit_enemy_001"})])
        self.assertEqual(result.state["event_log"][-1]["reason"], "target_out_of_range")

    def test_exhausted_ai_passes_with_mp_for_each_role_and_target_layout(self):
        for ranged in [False, True]:
            for adjacent in [False, True]:
                for mixed in [False, True]:
                    with self.subTest(ranged=ranged, adjacent=adjacent, mixed=mixed):
                        state = fixture("slice_62_enemy_ai_move_then_attack")
                        enemy = state["units"][1]
                        enemy["resources"]["ap"] = 0
                        if ranged:
                            enemy["available_actions"] += ["ranged_attack"]
                        if adjacent:
                            state["units"][0]["position"] = {"x": 2, "y": 1}
                        if mixed:
                            extra = deepcopy(state["units"][0])
                            extra["id"], extra["position"] = "unit_player_002", {"x": 0, "y": 2}
                            state["units"].append(extra)
                            state["turn_state"]["turn_order"].append(extra["id"])
                        before = deepcopy(state)
                        chosen = choose_enemy_command(state)
                        self.assertEqual(chosen["action_id"], "end_turn")
                        self.assertEqual(choose_enemy_command(state), chosen)
                        self.assertEqual(state, before)
                        result = simulate(state, [chosen])
                        self.assertEqual(result.state["units"][1], enemy)
                        self.assertNotEqual(result.state["turn_state"]["active_unit_id"], enemy["id"])
                        self.assertEqual([e["type"] for e in result.state["event_log"]],
                                         ["combat_started", "turn_started", "action_performed", "turn_ended", "turn_started"])

    def test_normal_ai_approach_attack_then_pass(self):
        state = fixture("slice_62_enemy_ai_move_then_attack")
        chosen = choose_enemy_command(state)
        self.assertEqual(chosen["action_id"], "move")
        self.assertEqual(chosen["target"]["position"], {"x": 3, "y": 1})
        state = simulate(state, [chosen]).state
        chosen = choose_enemy_command(state)
        self.assertEqual(chosen["action_id"], "basic_attack")
        state = simulate(state, [chosen]).state
        self.assertEqual(state["units"][0]["resources"]["hp"], 8)
        self.assertEqual(state["units"][1]["resources"], {"hp": 6, "ap": 0, "mp": 1})
        self.assertEqual(choose_enemy_command(state)["action_id"], "end_turn")

    def test_manual_zero_ap_player_movement_still_uses_mp(self):
        state = fixture("slice_62_enemy_ai_move_then_attack")
        state["turn_state"]["active_unit_id"] = "unit_player_001"
        state["units"][0]["resources"]["ap"] = 0
        result = simulate(state, [command("unit_player_001", "move", {"type": "tile", "position": {"x": 3, "y": 1}})])
        self.assertEqual(result.state["units"][0]["resources"], {"hp": 10, "ap": 0, "mp": 2})
        self.assertEqual(result.state["units"][0]["position"], {"x": 3, "y": 1})


if __name__ == "__main__":
    unittest.main()

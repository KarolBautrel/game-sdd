import copy
import json
from pathlib import Path
import unittest

from tools.validators.strategy_world import pair_key, reference_errors

ROOT = Path(__file__).resolve().parents[1]


class StrategyFoundation(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT / "resources/data/strategy_worlds/four_factions_foundation_v1.json").read_text())

    def receipt(self, action, target, actor="river_league"):
        self.data["command_seq"] += 1
        sequence = self.data["command_seq"]
        self.data["receipts"].append(dict(id=f"order_{sequence:08d}", sequence=sequence,
                                         actor_id=actor, action=action, target_id=target, tick=0))

    def accepted(self):
        self.data["pact_offers"]["peace_one"] = dict(id="peace_one", proposer="river_league", recipient="iron_march",
            kind="nonaggression", status="accepted", signed_by=["iron_march", "river_league"],
            duration_ticks=672, created_tick=0, expires_tick=96, accepted_tick=0)
        pair = self.data["diplomacy"][pair_key("river_league", "iron_march")]
        pair["treaties"].append(dict(id="peace_one", kind="nonaggression", start_tick=0, end_tick=672))
        self.receipt("propose_pact", "peace_one")
        self.receipt("accept_pact", "peace_one", "iron_march")
        return pair

    def test_reference_and_canonical_pairs(self):
        self.assertEqual(reference_errors(self.data), [])
        self.assertEqual((len(self.data["factions"]), len(self.data["settlements"]), len(self.data["diplomacy"])), (4, 6, 6))
        key = pair_key("river_league", "iron_march")
        self.assertEqual(key, pair_key("iron_march", "river_league"))
        del self.data["diplomacy"][key]
        self.assertIn("diplomacy must contain every canonical pair exactly once", reference_errors(self.data))

    def test_godot_integral_json_number_watermark(self):
        self.data["command_seq"] = 0.0
        self.assertEqual(reference_errors(self.data), [])

    def test_bad_shapes_versions_and_numeric_counts(self):
        for key, value in (("version", 2), ("version", True), ("planner_mode", "ai_strategy"),
                           ("seed", 1.5), ("seed", float("nan")), ("tick", -1), ("extra", 0),
                           ("factions", []), ("receipts", None)):
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.data)
                data[key] = value
                self.assertTrue(reference_errors(data))
        self.data["settlements"]["saltwatch"]["x"] = float("nan")
        self.assertIn("nonfinite settlement coordinate", reference_errors(self.data))

    def test_references_connectivity_manpower_and_reputation(self):
        self.data["settlements"]["saltwatch"]["owner_id"] = "missing"
        self.data["parties"]["league_patrol"]["headcount"] = 46
        self.data["company_reputation"]["missing"] = self.data["company_reputation"].pop("river_league")
        del self.data["routes"]["river_road"]
        del self.data["routes"]["market_road"]
        errors = reference_errors(self.data)
        for expected in ("unknown settlement owner", "party commitments exceed manpower",
                         "company reputation must match faction registry", "disconnected strategy graph"):
            self.assertIn(expected, errors)

    def test_duplicate_unknown_and_self_routes(self):
        for mutate in (lambda d: d["routes"].update(duplicate=copy.deepcopy(d["routes"]["river_road"])),
                       lambda d: d["routes"]["river_road"].update(a="missing"),
                       lambda d: d["routes"]["river_road"].update(a=d["routes"]["river_road"]["b"])):
            data = copy.deepcopy(self.data)
            mutate(data)
            self.assertIn("unknown/self/duplicate route endpoint", reference_errors(data))

    def test_consent_terms_and_war_contradictions(self):
        pair = self.accepted()
        self.assertEqual(reference_errors(self.data), [])
        base = copy.deepcopy(self.data)
        self.data["pact_offers"]["peace_one"]["signed_by"] = ["river_league"]
        self.assertTrue(reference_errors(self.data))
        self.data = copy.deepcopy(base)
        self.data["pact_offers"]["peace_one"]["duration_ticks"] = 96
        self.assertIn("accepted offer and treaty terms differ", reference_errors(self.data))
        self.data = copy.deepcopy(base)
        self.data["diplomacy"][pair_key(pair["a"], pair["b"])]["stance"] = "war"
        self.assertIn("conflicting active treaty", reference_errors(self.data))

    def test_stock_reservations_and_receipt_watermark(self):
        self.data["reservations"]["goal_one"] = dict(id="goal_one", faction_id="river_league", resource="coin",
            amount=120, purpose="trade", status="reserved", created_seq=1, closed_seq=None)
        self.receipt("reserve_budget", "goal_one")
        self.assertEqual(reference_errors(self.data), [])
        self.data["reservations"]["goal_one"]["amount"] = 121
        self.assertIn("reserved budget exceeds stock", reference_errors(self.data))
        self.data["reservations"]["goal_one"].update(amount=120, status="released", closed_seq=None)
        self.assertIn("released reservation has invalid closing sequence", reference_errors(self.data))
        self.data["receipts"][0]["sequence"] = 4
        self.assertIn("invalid receipt tail identity/reference/sequence/tick", reference_errors(self.data))

    def test_registry_order_independent(self):
        self.accepted()
        for key, value in list(self.data.items()):
            if isinstance(value, dict):
                self.data[key] = dict(reversed(list(value.items())))
        self.assertEqual(reference_errors(self.data), [])

    def test_duplicate_pending_terms_and_unilateral_treaties(self):
        self.accepted()
        offer = self.data["pact_offers"]["peace_one"]
        offer.update(status="pending", signed_by=["river_league"], accepted_tick=None)
        self.assertIn("unaccepted proposal cannot grant a treaty", reference_errors(self.data))
        self.data["diplomacy"][pair_key("river_league", "iron_march")]["treaties"].clear()
        self.assertEqual(reference_errors(self.data), [])
        self.data["pact_offers"]["peace_two"] = dict(offer, id="peace_two")
        self.assertIn("duplicate/conflicting pending pact", reference_errors(self.data))

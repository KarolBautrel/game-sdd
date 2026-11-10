import copy
import json
from pathlib import Path
import unittest
from tools.validators.classic_strategy import configuration_errors, reference_errors

ROOT = Path(__file__).resolve().parents[1]


class ClassicStrategy(unittest.TestCase):
    def setUp(self):
        self.rules = json.loads((ROOT / "resources/data/strategy_simulations/classic_rules_v1.json").read_text())
        self.state = json.loads((ROOT / "resources/data/strategy_snapshots/classic_opening_2088.json").read_text())

    def test_runtime_export_and_configuration_match(self):
        self.assertEqual(configuration_errors(self.rules), [])
        self.assertEqual(reference_errors(self.state), [])
        self.assertEqual(self.rules, self.state["rules"])

    def test_wrong_versions_shapes_and_numeric_values(self):
        for key, value in (("version", 2), ("version", True), ("core", {}), ("entity_seq", -1),
                           ("sequence", 1.5), ("events", None), ("extra", 1)):
            with self.subTest(key=key):
                broken = copy.deepcopy(self.state)
                broken[key] = value
                self.assertTrue(reference_errors(broken))

    def test_bad_rule_references_and_duplicate_premises(self):
        self.rules["policies"]["iron_march"]["home"] = "ashmere"
        self.rules["policies"]["river_league"]["claim_route"] = "missing"
        self.rules["premises"].append(copy.deepcopy(self.rules["premises"][0]))
        errors = configuration_errors(self.rules)
        for expected in ("classic home must be owned by faction", "unknown classic claim route", "duplicate opening premise"):
            self.assertIn(expected, errors)

    def test_accounting_and_position_corruption(self):
        self.state["core"]["factions"]["river_league"]["stocks"]["coin"] += 1
        self.state["forces"]["league_patrol"]["at"] = "saltwatch"
        errors = reference_errors(self.state)
        self.assertIn("classic resource ledger does not reconcile", errors)
        self.assertIn("core party and force position differ", errors)

    def test_invalid_war_and_reputation_registry(self):
        key = "iron_march~river_league"
        self.state["core"]["diplomacy"][key]["stance"] = "war"
        self.state["relations"]["river_league"]["missing"] = self.state["relations"]["river_league"].pop("iron_march")
        errors = reference_errors(self.state)
        self.assertIn("invalid active war metadata", errors)
        self.assertIn("directional relation endpoints mismatch", errors)

    def test_watermark_cannot_be_reset_independently(self):
        self.state["sequence"] = 1
        self.assertIn("history tail does not match watermark", reference_errors(self.state))

    def test_false_casualty_total_fails_accounting(self):
        self.state["metrics"]["casualties"] = 1
        self.assertIn("classic manpower/casualties do not reconcile", reference_errors(self.state))

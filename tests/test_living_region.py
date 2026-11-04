import copy
import json
from pathlib import Path
import unittest

from tools.validators.living_region import reference_errors

ROOT = Path(__file__).resolve().parents[1]


class LivingRegionReferences(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT / "resources/data/world_simulations/living_marches_v1.json").read_text())
        self.ids = {node["id"] for node in json.loads((ROOT / "resources/data/world_regions/region_001.json").read_text())["nodes"]}

    def test_current_configuration_and_dangling_contract(self):
        self.assertEqual(reference_errors(self.data, self.ids, ROOT), [])
        self.data["contracts"][0]["issuer"] = "missing_town"
        self.assertTrue(any("issuer/target" in error for error in reference_errors(self.data, self.ids, ROOT)))

    def test_duplicate_site_and_unknown_objective_fail(self):
        self.data["sites"].append(copy.deepcopy(self.data["sites"][0]))
        self.data["contracts"][0]["kind"] = "unknown_objective"
        errors = reference_errors(self.data, self.ids, ROOT)
        self.assertIn("duplicate living site ids", errors)
        self.assertTrue(any("unknown objective" in error for error in errors))

    def test_optional_save_schema_matches_standalone_contract(self):
        standalone = json.loads((ROOT / "resources/schemas/living_world_state.schema.json").read_text())
        standalone.pop("$schema")
        profile = json.loads((ROOT / "resources/schemas/campaign_profile.schema.json").read_text())
        self.assertNotIn("living_world", profile["required"])
        self.assertEqual(profile["properties"]["living_world"], standalone)

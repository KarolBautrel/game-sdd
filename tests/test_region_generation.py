import copy
import hashlib
import json
from pathlib import Path
import struct
import unittest

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


class GeneratedRegionContracts(unittest.TestCase):
    def setUp(self):
        self.schema = read("resources/schemas/generated_region.schema.json")
        self.validator = Draft202012Validator(self.schema)
        self.reference = read("resources/data/generated_regions/marches_2087.json")

    def test_three_real_generator_snapshots_and_profile(self):
        examples = sorted((ROOT / "resources/data/generated_regions").glob("*.json"))
        self.assertEqual(len(examples), 3)
        for example in examples:
            self.validator.validate(json.loads(example.read_text()))
        profile = read("tests/data/generated_profiles/marches_2087.json")
        Draft202012Validator(read("resources/schemas/campaign_profile.schema.json")).validate(profile)
        self.assertEqual(profile["living_world"]["geography"], self.reference)

    def test_inline_snapshot_contract_matches_standalone(self):
        inline = copy.deepcopy(self.schema)
        inline.pop("$schema")
        living = read("resources/schemas/living_world_state.schema.json")
        self.assertEqual(living["properties"]["geography"], inline)
        self.assertIn("terrain_signature", living["dependentRequired"]["geography"])

    def test_larger_versioned_examples_and_owned_profile(self):
        examples = sorted((ROOT / "resources/data/large_regions").glob("*.json"))
        self.assertEqual(len(examples), 3)
        for example in examples:
            snapshot = json.loads(example.read_text())
            self.validator.validate(snapshot)
            self.assertEqual((snapshot["terrain"]["width"], snapshot["terrain"]["height"]), (384, 216))
            broken = copy.deepcopy(snapshot)
            broken["version"] = 1
            self.assertTrue(list(self.validator.iter_errors(broken)))
            broken = copy.deepcopy(snapshot)
            broken.pop("climates")
            self.assertTrue(list(self.validator.iter_errors(broken)))
        profile = read("tests/data/generated_profiles/large_marches_2087.json")
        Draft202012Validator(read("resources/schemas/campaign_profile.schema.json")).validate(profile)
        self.assertEqual(profile["world"]["seed"], profile["living_world"]["geography"]["seed"])
        self.assertEqual((profile["gold"], profile["supplies"]["food"]), (80, 16))

    def test_unsupported_and_malformed_snapshots_fail(self):
        for key, value in [("version", 99), ("seed", 0), ("preset", "missing"), ("checksum", "bad")]:
            broken = copy.deepcopy(self.reference)
            broken[key] = value
            self.assertTrue(list(self.validator.iter_errors(broken)), key)
        broken = copy.deepcopy(self.reference)
        broken["terrain"]["rows"][0] = "?"
        self.assertTrue(list(self.validator.iter_errors(broken)))
        broken = copy.deepcopy(self.reference)
        broken["sites"][0]["owner"] = "unknown"
        self.assertTrue(list(self.validator.iter_errors(broken)))

    def test_artifact_provenance_hashes_and_runtime_dimensions(self):
        manifest = read("assets_src/region_symbols/2026-11-04/manifest.json")
        for item in manifest["files"]:
            self.assertEqual(hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest(), item["sha256"], item["path"])
        for name, dimensions in [("region_symbols.png", (1536, 1536)), ("ground_wash.png", (1672, 941))]:
            data = (ROOT / "assets/ui/world" / name).read_bytes()
            self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
            self.assertEqual(struct.unpack(">II", data[16:24]), dimensions)


if __name__ == "__main__":
    unittest.main()

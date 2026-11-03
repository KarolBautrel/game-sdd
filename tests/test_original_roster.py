"""Gate the complete authored delivery, including retained design references."""
import json
import unittest
from tools.qa.check_roster import ROOT, inspect_roster


class OriginalRosterTests(unittest.TestCase):
    def test_complete_delivery_matches_hashed_source_manifest(self):
        actual=inspect_roster()
        expected=json.loads((ROOT/"assets_src/characters/roster/manifest.json").read_text())
        self.assertEqual(actual,expected,"Rebuild affected source/sprites and refresh the complete delivery manifest")
        self.assertEqual(sum(row["frames"] for row in actual["models"]),6912)
        self.assertEqual(sum(row["editable_sources"] for row in actual["models"]),1107)

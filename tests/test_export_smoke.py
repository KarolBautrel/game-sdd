import unittest
from tools.qa.export_smoke import probe_complete, ENCOUNTER_TOKEN, CAMPAIGN_TOKEN, TRADE_TOKEN, INTERFACE_TOKEN, POLISH_TOKEN
from tools.qa.verify_project import SCENES


class ExportProbeTests(unittest.TestCase):
    def test_ignored_argument_cannot_pass(self):
        self.assertFalse(probe_complete("Godot Engine v4.7\n"))

    def test_partial_execution_cannot_pass(self):
        for omitted in SCENES:
            text = "SDD_EXPORT_SMOKE_PASS\n" + ENCOUNTER_TOKEN + "\n" + CAMPAIGN_TOKEN + "\n" + TRADE_TOKEN + "\n" + INTERFACE_TOKEN + "\n" + POLISH_TOKEN + "\n" + "\n".join(
                f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES if scene != omitted)
            self.assertFalse(probe_complete(text), omitted)

    def test_complete_execution_required(self):
        scene_text = "\n".join(f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES)
        self.assertFalse(probe_complete(scene_text))
        self.assertTrue(probe_complete(scene_text + "\n" + ENCOUNTER_TOKEN + "\n" + CAMPAIGN_TOKEN + "\n" + TRADE_TOKEN + "\n" + INTERFACE_TOKEN + "\n" + POLISH_TOKEN + "\nSDD_EXPORT_SMOKE_PASS"))

    def test_authored_encounter_token_required(self):
        scene_text = "\n".join(f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES)
        self.assertFalse(probe_complete(scene_text + "\n" + CAMPAIGN_TOKEN + "\n" + TRADE_TOKEN + "\n" + INTERFACE_TOKEN + "\n" + POLISH_TOKEN + "\nSDD_EXPORT_SMOKE_PASS"))

    def test_campaign_token_required(self):
        scene_text = "\n".join(f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES)
        self.assertFalse(probe_complete(scene_text + "\n" + ENCOUNTER_TOKEN + "\n" + TRADE_TOKEN + "\n" + INTERFACE_TOKEN + "\n" + POLISH_TOKEN + "\nSDD_EXPORT_SMOKE_PASS"))

    def test_trade_token_required(self):
        scene_text = "\n".join(f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES)
        self.assertFalse(probe_complete(scene_text + "\n" + ENCOUNTER_TOKEN + "\n" + CAMPAIGN_TOKEN + "\n" + INTERFACE_TOKEN + "\n" + POLISH_TOKEN + "\nSDD_EXPORT_SMOKE_PASS"))

    def test_interface_token_required(self):
        scene_text = "\n".join(f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES)
        self.assertFalse(probe_complete(scene_text + "\n" + ENCOUNTER_TOKEN + "\n" + CAMPAIGN_TOKEN + "\n" + TRADE_TOKEN + "\n" + POLISH_TOKEN + "\nSDD_EXPORT_SMOKE_PASS"))

    def test_polish_token_required(self):
        scene_text = "\n".join(f"SDD_EXPORT_SCENE_PASS res://{scene}" for scene in SCENES)
        self.assertFalse(probe_complete(scene_text + "\n" + ENCOUNTER_TOKEN + "\n" + CAMPAIGN_TOKEN + "\n" + TRADE_TOKEN + "\n" + INTERFACE_TOKEN + "\nSDD_EXPORT_SMOKE_PASS"))

import copy
import json
import unittest
from tools.validators.validate_all import ROOT, validate_campaign_items


class CampaignItemTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT / 'resources/data/items/catalogue.json').read_text(encoding='utf-8'))

    def test_canonical(self):
        self.assertEqual(validate_campaign_items(self.data), [])

    def test_duplicate(self):
        self.data['items'].append(copy.deepcopy(self.data['items'][0]))
        self.assertTrue(validate_campaign_items(self.data))

    def test_invalid_combat_profile(self):
        row = next(r for r in self.data['items'] if r['id'] == 'patched_leather')
        row['combat_profile']['armor_reduction'] = -1
        self.assertTrue(validate_campaign_items(self.data))

    def test_unknown_or_mismatched_action(self):
        row = next(r for r in self.data['items'] if r['id'] == 'hero_sword')
        row['combat_profile']['grants_actions'].append('invented_action')
        row['combat_profile']['action_profiles']['basic_attack']['action_id'] = 'ranged_attack'
        self.assertGreaterEqual(len(validate_campaign_items(self.data)), 2)

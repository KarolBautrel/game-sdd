import copy
import json
import unittest
from tools.validators.validate_all import ROOT, validate_town_trade


class TownTradeDataTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT / 'resources/data/town_trade/ravenford.json').read_text())

    def test_canonical(self):
        self.assertEqual(validate_town_trade(self.data), [])

    def test_duplicate_offer(self):
        self.data['offers'].append(copy.deepcopy(self.data['offers'][0]))
        self.assertTrue(validate_town_trade(self.data))

    def test_untradeable_or_unknown_offer(self):
        for item_id in ['rusty_key', 'legacy_relic', 'missing']:
            with self.subTest(item_id=item_id):
                data = copy.deepcopy(self.data)
                data['offers'][0]['item_id'] = item_id
                self.assertTrue(validate_town_trade(data))

    def test_bad_prices(self):
        for price in [-1, 0, 1.5, True, 1_000_000_001, 5]:
            with self.subTest(price=price):
                data = copy.deepcopy(self.data)
                data['offers'][0]['buy_price'] = price
                self.assertTrue(validate_town_trade(data))

    def test_wrong_town_or_shape(self):
        for field, value in [('town_id', 'missing'), ('offers', []), ('schema', 'unknown')]:
            with self.subTest(field=field):
                data = copy.deepcopy(self.data)
                data[field] = value
                self.assertTrue(validate_town_trade(data))

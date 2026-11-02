import copy
import json
import unittest
from tools.validators.dungeon_quality import ROOT, template_errors


class DungeonQualityTests(unittest.TestCase):
    def setUp(self):
        self.template=json.loads((ROOT/'resources/data/dungeon_templates/generated_old_mine_templates.json').read_text())['templates'][0]

    def test_valid_template(self):
        self.assertEqual(template_errors(self.template), [])

    def test_broken_graphs(self):
        mutations = [
            lambda t: t['rooms'].append(copy.deepcopy(t['rooms'][0])),
            lambda t: t['rooms'][1].update(position=t['rooms'][0]['position']),
            lambda t: t['corridors'].clear(),
            lambda t: t['corridors'][0].update(to='missing'),
            lambda t: t['corridors'].append(copy.deepcopy(t['corridors'][0])),
            lambda t: t['rooms'][0].update(kind='empty'),
            lambda t: t['rooms'][-1].update(kind='empty'),
            lambda t: t['pacing'].update(combat_count=99),
            lambda t: t.pop('acceptance_state'),
        ]
        for index, mutate in enumerate(mutations):
            with self.subTest(index=index):
                t=copy.deepcopy(self.template); mutate(t)
                self.assertTrue(template_errors(t))


if __name__=='__main__': unittest.main()

import copy
import json
from pathlib import Path
import unittest
from tools.validators.terrain import terrain_errors

ROOT = Path(__file__).resolve().parents[1]


class TerrainReferences(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT/'resources/data/world_terrain/living_marches_v1.json').read_text())
        region = json.loads((ROOT/'resources/data/world_simulations/living_marches_v1.json').read_text())
        self.anchors = region['sites']

    def test_real_geography_and_required_sites(self):
        self.assertEqual([], terrain_errors(self.data,self.anchors))
        self.assertEqual(set('RPFHMWXB'),set(''.join(self.data['rows'])))
        for crossing in self.data['crossings']:
            x = int(crossing['position']['x']*self.data['width'])
            y = int(crossing['position']['y']*self.data['height'])
            self.assertEqual('B',self.data['rows'][y][x])

    def test_bad_rows_codes_and_disconnected_site(self):
        bad = copy.deepcopy(self.data)
        bad['rows'][0]='?'
        self.assertIn('invalid terrain rows',terrain_errors(bad))
        bad['rows'][0]='?'*int(bad['width'])
        self.assertIn('unknown terrain codes',terrain_errors(bad))
        small = {'version':1,'revision':1,'region':'living_marches_v1','width':4,'height':4,
                 'rows':['PPWP','PPWP','WWWW','PPPP']}
        anchors = [{'id':'start','position':{'x':.1,'y':.1}}, {'id':'end','position':{'x':.9,'y':.9}}]
        self.assertIn('end is disconnected',terrain_errors(small,anchors))

    def test_recovery_archive_remains_byte_identical(self):
        import hashlib
        path = ROOT/'assets_src/ui_review_baselines/2026-11-04-world-atlas-approved/world-atlas-stage76.zip'
        self.assertEqual('d208ceb651294cc56318d4aa32bee7a5caa44a7cf9c7ec76d8f54bbf9280e777',hashlib.sha256(path.read_bytes()).hexdigest())

    def test_godot_integral_metadata_and_invalid_dimensions(self):
        self.data.update(width=192.0,height=108.0,revision=9.0)
        self.assertEqual([],terrain_errors(self.data,self.anchors))
        for invalid in (192.5,float('nan'),float('inf'),True,None):
            self.data['width']=invalid
            self.assertIn('invalid terrain dimensions',terrain_errors(self.data))

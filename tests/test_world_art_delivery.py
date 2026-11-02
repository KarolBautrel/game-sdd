import hashlib,json,struct,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

class WorldArtDeliveryTests(unittest.TestCase):
    def test_original_sources_exports_and_all_authored_routes(self):
        data=json.loads((ROOT/'resources/data/presentation/world_art.json').read_text())
        manifest=json.loads((ROOT/'assets_src/environment/manifest.json').read_text())
        fbx=json.loads((ROOT/'assets_src/environment/fbx-check.json').read_text())
        self.assertEqual({row['id'] for row in fbx['props']},set(data['assets']))
        for row in fbx['props']:self.assertEqual(hashlib.sha256((ROOT/'assets_src/environment/props'/row['id']/(row['id']+'.fbx')).read_bytes()).hexdigest(),row['sha256'])
        self.assertEqual(len(data['assets']),28)
        for row in manifest['files']:
            self.assertEqual(hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest(),row['sha256'],row['path'])
        for ident,row in data['assets'].items():
            folder=ROOT/'assets_src/environment/props'/ident
            for suffix in ['.blend','.fbx','_albedo.png']:self.assertTrue((folder/(ident+suffix)).is_file())
            self.assertTrue(json.loads((folder/'model.json').read_text())['uv'])
            self.assertEqual(struct.unpack('>II',(ROOT/row['path'].removeprefix('res://')).read_bytes()[16:24]),tuple(row['size']))
            self.assertTrue((ROOT/'assets_src/aseprite/environment'/('props_'+ident+'.aseprite')).is_file())
        for file in (ROOT/'resources/data/combat_encounters').glob('*.json'):
            encounter=json.loads(file.read_text())
            for decoration in encounter.get('terrain_decorations',[]):
                path=decoration['path']
                self.assertTrue(path in data['legacy_routes'] or path in data['floor_routes'],(file,path))
        for target in data['legacy_routes'].values():self.assertIn(target,data['assets'])
        for target in data['floor_routes'].values():self.assertIn(target,data['floors'])

import copy
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest.mock import patch

from tools.maps import tiled_to_map_json as converter
from tools.combat.simulate_combat import _apply_map_reference


class TiledMapsTests(unittest.TestCase):
    def setUp(self):
        self.source = converter.ROOT / 'resources/tiled/maps/combat_test_clearing.tmx'
        self.root = ET.parse(self.source).getroot()

    def converted(self, root=None):
        # Keep relative TSX references valid without touching the source TMX.
        with tempfile.NamedTemporaryFile(suffix='.tmx', dir=self.source.parent, delete=False) as handle:
            path = Path(handle.name)
        try:
            ET.ElementTree(root if root is not None else self.root).write(path)
            return converter.convert_tmx(path)
        finally:
            path.unlink()

    def test_deterministic_metadata_and_runtime_precedence(self):
        first = converter.convert_tmx(self.source)
        self.assertEqual(first, converter.convert_tmx(self.source))
        self.assertEqual(first['schema_version'], 2)
        self.assertEqual(first['terrain_decorations'][0]['x'], 1)
        state = {'map_path': 'res://resources/data/maps/combat_test_clearing.json', 'terrain_theme': 'dungeon'}
        _apply_map_reference(state)
        self.assertEqual(state['terrain_theme'], 'dungeon')
        self.assertEqual(state['terrain_decorations'], first['terrain_decorations'])

    def test_invalid_dimensions(self):
        for attr, value in [('width', '0'), ('tilewidth', '0'), ('tileheight', '75'), ('infinite', '1'), ('orientation', 'isometric')]:
            with self.subTest(attr=attr):
                root = copy.deepcopy(self.root); root.set(attr, value)
                with self.assertRaises(ValueError): self.converted(root)

    def test_unknown_and_flipped_gids(self):
        for gid in ('999', '2147483649'):
            root = copy.deepcopy(self.root)
            data = root.find('layer/data'); data.text = data.text.replace('1,1,1,1', gid+',1,1,1', 1)
            with self.assertRaises(ValueError): self.converted(root)

    def test_spawn_origins_bounds_and_tile_objects(self):
        for attr, value in [('x', '77'), ('x', '-76'), ('x', '912'), ('y', '760'), ('gid', '1'), ('rotation', '90')]:
            with self.subTest(attr=attr, value=value):
                root = copy.deepcopy(self.root); root.find('objectgroup/object').set(attr, value)
                with self.assertRaises(ValueError): self.converted(root)

    def test_blocked_and_overlapping_spawns(self):
        root = copy.deepcopy(self.root)
        obj = root.find('objectgroup/object'); obj.set('x', '76'); obj.set('y', '152')
        with self.assertRaisesRegex(ValueError, 'Blocked'): self.converted(root)
        root = copy.deepcopy(self.root); group=root.find('objectgroup'); group.append(copy.deepcopy(group[0]))
        with self.assertRaisesRegex(ValueError, 'Duplicate'): self.converted(root)

    def test_missing_decoration_asset(self):
        self.root.find("objectgroup[@name='decorations']/object/properties/property").set('value', 'res://assets/combat/terrain/processed/missing.png')
        with self.assertRaisesRegex(ValueError, 'asset'): self.converted()


if __name__ == '__main__': unittest.main()

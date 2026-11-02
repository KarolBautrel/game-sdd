import json
from pathlib import Path
import struct
import tempfile
import unittest

from tools.assets.build_catalogue import CATALOGUE, build_catalogue, catalogue_errors


class CatalogueTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "assets").mkdir()
        # Header sufficient for catalogue metadata; decoding is tested in Godot.
        self.asset = self.root / "assets/test.png"
        self.asset.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\0\0\0\rIHDR" + struct.pack(">II", 2, 3))
        (self.root / CATALOGUE).parent.mkdir(parents=True)
        (self.root / CATALOGUE).write_text(json.dumps(build_catalogue(self.root)))

    def test_deterministic_and_relative(self):
        self.assertEqual(build_catalogue(self.root), build_catalogue(self.root))
        self.assertEqual(catalogue_errors(self.root), [])
        self.assertEqual(build_catalogue(self.root)["textures"][0]["path"], "res://assets/test.png")

    def test_changed_removed_added_rejected_without_write(self):
        original = (self.root / CATALOGUE).read_bytes()
        data = self.asset.read_bytes()
        for mutation in ("change", "remove", "add"):
            self.asset.write_bytes(data)
            extra = self.root / "assets/extra.png"
            extra.unlink(missing_ok=True)
            if mutation == "change":
                self.asset.write_bytes(data + b"changed")
            elif mutation == "remove":
                self.asset.unlink()
            else:
                extra.write_bytes(data)
            self.assertTrue(catalogue_errors(self.root), mutation)
            self.assertEqual((self.root / CATALOGUE).read_bytes(), original)

    def test_corrupt_and_missing_catalogue(self):
        target = self.root / CATALOGUE
        target.write_text("broken JSON")
        self.assertTrue(catalogue_errors(self.root))
        target.unlink()
        self.assertTrue(catalogue_errors(self.root))

    def test_invalid_png(self):
        self.asset.write_bytes(b"broken PNG")
        self.assertTrue(catalogue_errors(self.root))


if __name__ == "__main__":
    unittest.main()

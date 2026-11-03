"""Prepare a verified local UI release's window profile and complete notices."""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MARKER = "; sdd QA launcher local profile"

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release_dir", type=Path)
    args = parser.parse_args()
    directory = args.release_dir.resolve()
    if not directory.is_relative_to(ROOT / "artifacts/export-smoke"):
        parser.error("Expected a local export-smoke release directory")
    report = json.loads((directory / "report.json").read_text(encoding="utf-8"))
    if report["status"] != "PASS":
        parser.error("Export must pass before preparing its launch profile")
    for name, record in report["artifacts"].items():
        if hashlib.sha256((directory / name).read_bytes()).hexdigest() != record["sha256"]:
            parser.error("Build hash changed: " + name)
    source = (ROOT / "override.cfg").read_text(encoding="utf-8-sig")
    target = directory / "override.cfg"
    if not source.startswith(MARKER):
        parser.error("Source window profile is unmanaged")
    if target.exists() and not target.read_text(encoding="utf-8-sig").startswith(MARKER):
        parser.error("Existing release profile is unmanaged")
    release_profile = re.sub(r'(?m)^run/main_scene="[^"]+"$', 'run/main_scene="res://scenes/app/App.tscn"', source)
    if 'run/main_scene="res://scenes/app/App.tscn"' not in release_profile:
        parser.error("Owned source profile has no main scene")
    target.write_text(release_profile, encoding="utf-8")
    licenses = sorted((ROOT / "resources/licenses").glob("*.txt"))
    licenses.extend(sorted((ROOT / "assets/ui/fonts").glob("*-OFL.txt")))
    notices = "\n\n".join(path.name + "\n" + "=" * len(path.name) + "\n" + path.read_text(encoding="utf-8-sig") for path in licenses)
    (directory / "THIRD_PARTY_NOTICES.txt").write_text(notices, encoding="utf-8")
    (directory / "URUCHOMIENIE.txt").write_text(
        "Uruchom sdd-game.exe, pozostawiajac obok pliki PCK i override.cfg.\n"
        "Start: mapa kampanii; zakladki miasta, ekwipunku, handlu i treningu.\n"
        "Okno1920x1080 na wiekszym lewym DISPLAY1 (Godot ekran0).\n"
        "Nie usuwaj zapisu gracza. Testy fizyczna mysza/klawiatura i normalna\n"
        "walka nadal czekaja na wspolna sesje; lista: docs/qa/live-test-scenarios.md.\n"
        "Pakiet ma nowy ekwipunek dark fantasy, mape na pergaminie, interfejs\n"
        "lochow/walki oraz27 oryginalnych modeli postaci i stworzen.\n"
        "Przywrocone modele i animowane sprite'y sprzed zmian chwytow broni.\n"
        "Nowe portrety, spojne podlogi i28 rekwizytow pozostaja.\n"
        "W Trading Post kupisz buty, helm i zbroje; Stash & gear pokazuje\n"
        "pieciopolowy ekwipunek i osobny ilustrowany portret.\n"
        "W walce: Tools -> Character gallery pokazuje caly zestaw animacji.\n", encoding="utf-8")
    metadata = {"source_profile_sha256": hashlib.sha256((ROOT / "override.cfg").read_bytes()).hexdigest(),
                "release_profile_sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
                "scene": "res://scenes/app/App.tscn", "mode": "windowed", "godot_screen": 0,
                "source_profile_changed": False, "physical_acceptance": "NOT_RUN"}
    (directory / "launch-profile.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print("Prepared verified UI release: " + str(directory))

if __name__ == "__main__":
    main()

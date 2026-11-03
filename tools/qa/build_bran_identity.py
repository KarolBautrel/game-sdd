"""Create a separate native-pixel identity variant; never edit accepted six roles."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets_src/characters/hero_identity/bran'
ASEPRITE = Path('C:/Program Files/Aseprite/Aseprite.exe')
ACTIONS = ['neutral_idle', 'combat_idle', 'neutral_walk', 'combat_walk', 'attack', 'hit', 'death']
VIEWS = ['south_east', 'south', 'east', 'north_east', 'north', 'south_west', 'west', 'north_west']


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def main():
    registry = json.loads((ROOT/'resources/data/presentation/drawn_roster.json').read_text(encoding='utf-8'))
    original = ROOT/'assets/combat/characters/drawn'
    before = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in original.rglob('*.png')}
    SOURCE.mkdir(parents=True, exist_ok=True)
    (ROOT/'assets_src/aseprite/ui/items').mkdir(parents=True, exist_ok=True)
    # Landmarks are recorded data, not a heuristic run during export.
    assert (SOURCE/'head_landmarks.json').exists(), 'Author/review the native head landmarks first'
    knight = next(p for p in registry['profiles'] if p['id'] == 'knight')
    variant = copy.deepcopy(knight)
    variant.update(id='bran_greatsword', label='Bran - greatsword',
                   root='res://assets/combat/characters/identity/bran_greatsword',
                   source_roundtrip=True)
    for key in ['frame_counts', 'durations_ms']:
        variant[key] = {k: v for k, v in variant[key].items() if k in ACTIONS}
    for view, entry in variant['view_sources'].items():
        entry['source'] = (SOURCE/'greatsword'/view).relative_to(ROOT).as_posix()
        entry['method'] = 'native Bran head composition / retained compatible rear' if not entry.get('mirror_of') else 'disclosed reflection of '+entry['mirror_of']
    for view in VIEWS:
        (ROOT/'assets_src/aseprite/characters/hero_identity/bran_greatsword'/view).mkdir(parents=True, exist_ok=True)
        for action in ACTIONS:
            (SOURCE/'greatsword'/view/'frames'/action).mkdir(parents=True, exist_ok=True)
            (ROOT/'assets/combat/characters/identity/bran_greatsword'/action).mkdir(parents=True, exist_ok=True)
    config = {'schema': 'sdd.hero-identity-source-v1', 'identity': 'hero_bran', 'actions': ACTIONS,
              'views': VIEWS, 'profile': variant,
              'provenance': 'Accepted warrior head pixels and knight body/weapon poses; native Aseprite composition. Rear heads retain the compatible brown-haired rear drawings. Five drawn views, three reflections.'}
    write(SOURCE/'build.json', config)
    p = subprocess.run([str(ASEPRITE), '-b', '--script-param', 'root='+ROOT.as_posix(),
                        '--script', str(ROOT/'tools/aseprite/bran_identity.lua')],
                       cwd=ROOT, capture_output=True, text=True,
                       creationflags=subprocess.CREATE_NO_WINDOW, timeout=180)
    print(p.stdout, p.stderr)
    assert p.returncode == 0 and 'BRAN_IDENTITY_SOURCE_PASS' in p.stdout
    proof = json.loads((SOURCE/'source_proof.json').read_text())
    assert proof['status'] == 'PASS' and len(proof['clips']) == 56
    assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest() == h for p, h in before.items())
    assert len(before) == 2304
    write(SOURCE/'accepted_roster_hashes.json', before)
    write(ROOT/'resources/data/presentation/hero_identity_animations.json',
          {'schema': 'sdd.drawn-roster-v1', 'profiles': [variant]})
    print('BRAN_IDENTITY_BUILD_PASS 56 sources / 352 frames; accepted2304 PNGs unchanged')


if __name__ == '__main__':
    main()

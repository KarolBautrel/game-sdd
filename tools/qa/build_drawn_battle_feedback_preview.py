"""Native/enlarged before-after samples for brisk walking and the north warrior."""
import json
import os
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/battle_feedback'
BEFORE = OUT / 'before'
cases = []


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def add(folder, role_label, action, topic):
    old = BEFORE / folder.relative_to(ROOT)
    current = next(c for c in read(folder / 'manifest.json')['clips'] if c['id'] == action)
    previous = next(c for c in read(old / 'manifest.json')['clips'] if c['id'] == action)
    entry = {'topic': topic, 'label': role_label + ' / ' + current['title'],
             'note': 'Chód jest dwa razy szybszy: cykl 0,40 s zamiast 0,80 s, z taką samą długością kroku.'
             if topic == 'walk' else 'Tylko widok od tyłu: szersza postawa i miecz zasłonięty tułowiem. Wnętrze tarczy zachowane.'}
    for name, home, clip in [('old', old, previous), ('new', folder, current)]:
        image = home / clip['atlas']
        assert struct.unpack('>II', image.read_bytes()[16:24]) == (384 * clip['frames'], 320)
        entry[name] = {'atlas': os.path.relpath(image, OUT).replace('\\', '/'),
                       'frames': clip['frames'], 'durations': clip['durations'], 'loop': clip['loop']}
    cases.append(entry)


for profile in read(ROOT / 'resources/data/presentation/drawn_roster.json')['profiles']:
    for action in ('neutral_walk', 'combat_walk'):
        add(BASE / profile['id'], profile['label'], action, 'walk')
for action in ('neutral_idle', 'combat_idle', 'neutral_walk', 'combat_walk', 'attack', 'hit'):
    add(BASE / 'warrior/directions/north', 'Bran / tył', action, 'rear')
data = {'cases': cases, 'topics': [['walk', 'Szybszy chód'], ['rear', 'Rycerz od tyłu']],
        'initial_topic': 'walk',
        'floor': os.path.relpath(ROOT / 'assets/combat/environment/floors/woodland.png', OUT).replace('\\', '/'),
        'shadow': os.path.relpath(ROOT / 'assets/combat/environment/contact_shadow.png', OUT).replace('\\', '/')}
for key in ('floor', 'shadow'):
    assert (OUT / data[key]).is_file()
template = (ROOT / 'tools/qa/drawn_refinement_player.html').read_text(encoding='utf-8')
(OUT / 'preview.html').write_text(template.replace('__REFINEMENT_DATA__', json.dumps(data, ensure_ascii=False)), encoding='utf-8')
(OUT / 'player_data.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
p = subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe', '-b', '--script-param',
                    'root=' + ROOT.as_posix(), '--script', str(ROOT / 'tools/aseprite/drawn_battle_feedback_samples.lua')],
                   cwd=ROOT, capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
assert p.returncode == 0 and 'DRAWN_BATTLE_FEEDBACK_STILLS_PASS' in p.stdout, p.stdout + p.stderr
print('DRAWN_BATTLE_FEEDBACK_PREVIEW_PASS', len(cases), 'before/after samples')

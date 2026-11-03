"""Stage58 comparison: identical root travel, natural cadence, and knight stances."""
import json
import os
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/motion_balance'
BEFORE = OUT / 'before'
cases = []


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def add(folder, label, action, topic, view):
    previous = BEFORE / folder.relative_to(ROOT)
    before = read(previous / 'manifest.json')
    after = read(folder / 'manifest.json')
    item = {'topic': topic, 'label': label + ' / ' + view + ' / ' + action,
            'note': 'Ta sama prędkość przemieszczania, dwa razy spokojniejszy rytm nóg. Podłoże pokazuje przebyty dystans.'
            if topic == 'gait' else 'Szersza wykroczna postawa bojowa; neutralnie miecz jest opuszczony i trzymany w dłoni.'}
    for key, home, manifest in [('old', previous, before), ('new', folder, after)]:
        clip = next(c for c in manifest['clips'] if c['id'] == action)
        image = home / clip['atlas']
        assert struct.unpack('>II', image.read_bytes()[16:24]) == (384 * clip['frames'], 320)
        entry = {'atlas': os.path.relpath(image, OUT).replace('\\', '/'), 'frames': clip['frames'],
                 'durations': clip['durations'], 'loop': clip['loop']}
        if 'walk' in action:
            entry.update(stride_pixels=manifest.get('walk_stride_pixels', 80), direction=view)
        item[key] = entry
    if 'walk' in action:
        assert item['old']['stride_pixels'] / sum(item['old']['durations']) == item['new']['stride_pixels'] / sum(item['new']['durations'])
    cases.append(item)


registry = read(ROOT / 'resources/data/presentation/drawn_roster.json')
for profile in registry['profiles']:
    for action in ('neutral_walk', 'combat_walk'):
        add(BASE / profile['id'], profile['label'], action, 'gait', 'south_east')
for view in registry['profiles'][0]['facings']:
    folder = BASE / 'knight' if view == 'south_east' else BASE / 'knight/directions' / view
    for action in ('combat_idle', 'neutral_idle', 'neutral_walk'):
        add(folder, 'Szermierz', action, 'knight', view)
data = {'cases': cases, 'initial_topic': 'gait',
        'topics': [['gait', 'Naturalniejszy chód'], ['knight', 'Szermierz: postawy i miecz']],
        'floor': os.path.relpath(ROOT / 'assets/combat/environment/floors/woodland.png', OUT).replace('\\', '/'),
        'shadow': os.path.relpath(ROOT / 'assets/combat/environment/contact_shadow.png', OUT).replace('\\', '/')}
template = (ROOT / 'tools/qa/drawn_refinement_player.html').read_text(encoding='utf-8')
(OUT / 'preview.html').write_text(template.replace('__REFINEMENT_DATA__', json.dumps(data, ensure_ascii=False)), encoding='utf-8')
(OUT / 'player_data.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
process = subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe', '-b', '--script-param', 'root=' + ROOT.as_posix(),
                          '--script', str(ROOT / 'tools/aseprite/drawn_motion_balance_samples.lua')], cwd=ROOT,
                         capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
assert process.returncode == 0 and 'DRAWN_MOTION_STILLS_PASS' in process.stdout, process.stdout + process.stderr
print('DRAWN_MOTION_PREVIEW_PASS', len(cases), 'native/2x before-after samples')

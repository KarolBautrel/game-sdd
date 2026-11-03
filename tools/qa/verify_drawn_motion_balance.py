"""Verify stage58 scope and cadence calibration without claiming visual acceptance."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/motion_balance'
BEFORE = OUT / 'before'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


identities = read(BEFORE / 'identities.json')
for name, digest in identities.items():
    assert sha(BEFORE / name) == digest, name
walk = read(OUT / 'walk_timing_report.json')
assert walk['status'] == 'PASS' and walk['duration_ms'] == 100 and walk['stride_pixels'] == 160
assert len(walk['clips']) == 96 and all(c['source_roundtrip'] == 'PASS' for c in walk['clips'])
views = 0
for main in BASE.glob('*/manifest.json'):
    for path in [main, *sorted((main.parent / 'directions').glob('*/manifest.json'))]:
        old = read(BEFORE / path.relative_to(ROOT))
        new = read(path)
        assert new['walk_stride_pixels'] == 160
        previous = {c['id']: c for c in old['clips']}
        for clip in new['clips']:
            assert clip['frames'] == previous[clip['id']]['frames']
            if clip['id'] in ('neutral_walk', 'combat_walk'):
                assert previous[clip['id']]['durations'] == [50] * 8
                assert clip['durations'] == [100] * 8
                assert 160 / sum(clip['durations']) == 80 / sum(previous[clip['id']]['durations'])
            else:
                assert clip['durations'] == previous[clip['id']]['durations']
        report = read(path.parent / 'export_report.json')
        assert report['saved_source_roundtrip'] == 'PASS' and not report['clipping']
        assert {c['id'] for c in new['clips']} <= set(report['clips']), path
        views += 1
assert views == 48
registry = read(ROOT / 'resources/data/presentation/drawn_roster.json')
assert all(p['walk_stride_pixels'] == 160 and p['durations_ms']['neutral_walk'] == [100] * 8 and
           p['durations_ms']['combat_walk'] == [100] * 8 for p in registry['profiles'])
before_pixels = read(BEFORE / 'runtime_pixels.json')
changed = [name for name, digest in before_pixels.items() if sha(ROOT / name) != digest]
assert len(changed) == 128, len(changed)
assert all('/knight/' in name and any('/' + action + '/' in name for action in
           ('neutral_idle', 'combat_idle', 'neutral_walk')) for name in changed)
stance = read(OUT / 'stance_report.json')
assert stance['status'] == 'PASS' and len(stance['combat_feet']) == 5
for view in ('south_east', 'south', 'east', 'north_east', 'north'):
    idle = read(OUT / ('idle_' + view + '.json'))
    assert idle['status'] == 'PASS' and len(idle['views']) == 1
samples = read(OUT / 'player_data.json')
assert len(samples['cases']) == 36
proof = {'status': 'SOURCE_AND_SCOPE_PASS', 'baseline_files_preserved': len(identities),
         'walk_clips': 96, 'frames_per_cycle': 8, 'gait_cycle_before_ms': 400, 'gait_cycle_after_ms': 800,
         'stride_before_pixels': 80, 'stride_after_pixels': 160, 'root_pixels_per_second': 200,
         'changed_runtime_pngs': changed, 'unchanged_runtime_pngs': len(before_pixels) - len(changed),
         'changed_art_scope': 'knight only: neutral_idle/combat_idle/neutral_walk in eight views',
         'other_action_timings': 'UNCHANGED', 'source_roundtrip': 'PASS',
         'combat_base': stance['combat_feet'], 'before_after_samples': 36,
         'visual_retest': 'NOT_RUN', 'desktop_input_used': False}
(OUT / 'verification.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('DRAWN_MOTION_BALANCE_VERIFY_PASS: 96 natural-cadence clips, 128 knight-only art edits, same 200px/s travel')

"""Prove the correction's source timing, narrow pixel scope and retained baseline."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/battle_feedback'
BEFORE = OUT / 'before'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


baseline = read(BEFORE / 'identities.json')
for relative, digest in baseline.items():
    assert sha(BEFORE / relative) == digest, relative
walks = read(OUT / 'walk_timing_report.json')
assert walks['status'] == 'PASS' and len(walks['clips']) == 96
assert all(c['source_roundtrip'] == 'PASS' and c['pixels_unchanged'] and c['cycle_ms'] == 400 for c in walks['clips'])
clips = 0
for home in BASE.glob('*/manifest.json'):
    for path in [home, *sorted((home.parent / 'directions').glob('*/manifest.json'))]:
        old = read(BEFORE / path.relative_to(ROOT))
        current = read(path)
        old_clips = {c['id']: c for c in old['clips']}
        for clip in current['clips']:
            previous = old_clips[clip['id']]
            assert clip['frames'] == previous['frames'], path
            if clip['id'] in ('neutral_walk', 'combat_walk'):
                assert clip['durations'] == [50] * 8, path
                assert previous['durations'] == [100] * 8, path
                clips += 1
            else:
                assert clip['durations'] == previous['durations'], path
        export = read(path.parent / 'export_report.json')
        assert not export['clipping'] and export['saved_source_roundtrip'] == 'PASS', path
assert clips == 96
registry = read(ROOT / 'resources/data/presentation/drawn_roster.json')
for profile in registry['profiles']:
    for action in ('neutral_walk', 'combat_walk'):
        assert profile['durations_ms'][action] == [50] * 8
    assert profile['walk_stride_pixels'] == 80
pixels = read(BEFORE / 'runtime_pixels.json')
changed = [name for name, digest in pixels.items() if sha(ROOT / name) != digest]
assert len(changed) == 36, len(changed)
assert all('/warrior/' in name and '/warrior_north_' in name and '/death/' not in name for name in changed)
for name, digest in baseline.items():
    if '/warrior/directions/north/' in name and ('/frames/death/' in name or name.endswith('/death.png') or name.endswith('/death.aseprite')):
        assert sha(ROOT / name) == digest, name
idles = read(OUT / 'idle_contact_report.json')
assert idles['status'] == 'PASS' and len(idles['views']) == 1
pose = read(OUT / 'rear_pose_report.json')
assert pose['status'] == 'PASS'
result = {'status': 'SOURCE_AND_SCOPE_PASS', 'baseline_files_preserved': len(baseline),
          'walk_clips_retimed': clips, 'walk_cycle_before_ms': 800, 'walk_cycle_after_ms': 400,
          'walk_stride_pixels': 80, 'non_walk_durations': 'UNCHANGED_ALL_48_VIEWS',
          'changed_runtime_pngs': changed, 'other_runtime_pngs_unchanged': len(pixels) - len(changed),
          'north_warrior_death': 'BYTE_IDENTICAL_SOURCE_AND_EXPORTS',
          'rear_pose_metrics': pose['views'], 'source_roundtrip': 'PASS',
          'visual_retest': 'NOT_RUN', 'desktop_input_used': False}
(OUT / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('DRAWN_BATTLE_FEEDBACK_VERIFY_PASS: 96 walk clips, 36 scoped PNG edits, retained non-walk timings/death')

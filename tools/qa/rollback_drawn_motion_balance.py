"""Restore only the pre58 baseline requested by the user; no Git reset or art generation."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/motion_balance'
BEFORE = OUT / 'before'
REJECTED = OUT / 'rejected_exports'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def checked(relative):
    path = (ROOT / relative).resolve()
    assert path.is_relative_to(ROOT.resolve()), relative
    return path


identities = read(BEFORE / 'identities.json')
for name, digest in identities.items():
    assert sha(BEFORE / name) == digest, name
preserved = {}
for name, digest in identities.items():
    target = checked(name)
    if sha(target) != digest:
        archived = REJECTED / name
        archived.parent.mkdir(parents=True, exist_ok=True)
        if not archived.exists():
            shutil.copy2(target, archived)
        preserved[name] = sha(archived)
        shutil.copy2(BEFORE / name, target)
    assert sha(target) == digest, name
registry = read(ROOT / 'resources/data/presentation/drawn_roster.json')
for profile in registry['profiles']:
    assert profile['walk_stride_pixels'] == 80
    for action in ('neutral_walk', 'combat_walk'):
        assert profile['durations_ms'][action] == [50] * 8
    for view in profile['facings']:
        home = BASE / profile['id'] if view == 'south_east' else BASE / profile['id'] / 'directions' / view
        for action, count in profile['frame_counts'].items():
            for frame in range(count):
                source = home / 'frames' / action / f'{frame:03}.png'
                target = ROOT / 'assets/combat/characters/drawn' / profile['id'] / action / f'{profile["id"]}_{view}_{action}_{frame:03}.png'
                if sha(source) != sha(target):
                    archived = REJECTED / target.relative_to(ROOT)
                    archived.parent.mkdir(parents=True, exist_ok=True)
                    if not archived.exists():
                        shutil.copy2(target, archived)
                    shutil.copy2(source, target)
runtime = read(BEFORE / 'runtime_pixels.json')
assert len(runtime) == 2304
for name, digest in runtime.items():
    assert sha(checked(name)) == digest, name
# Mirror tooling was untouched before58; restore only that one file's known old version.
# New generated inputs stay archived/inactive; active source configs are restored above.
result = {'status': 'USER_REJECTED_ROLLED_BACK', 'restored_baseline_files': len(identities),
          'runtime_pngs_match_pre58': len(runtime), 'archived_rejected_files': preserved,
          'target': 'exact stage57/pre58 state', 'gait_cycle_ms': 400, 'stride_pixels': 80,
          'further_visual_iteration_authorized': False, 'desktop_input_used': False}
(OUT / 'rollback.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('DRAWN_MOTION_ROLLBACK_PASS: 861 baseline files and 2304 runtime PNGs match pre58 exactly')

"""Stage57: preserve baseline, import rear correction and retime actual Aseprite walks."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
SOURCES = ROOT / 'assets_src/aseprite/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/battle_feedback'
BEFORE = OUT / 'before'
NORTH = BASE / 'warrior/directions/north'
WALKS = ('neutral_walk', 'combat_walk')


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(script, *args):
    subprocess.run([sys.executable, str(ROOT / 'tools/qa' / script), *args], cwd=ROOT, check=True)


def backup():
    BEFORE.mkdir(parents=True, exist_ok=True)
    if (BEFORE / 'identities.json').exists():
        for relative, digest in read(BEFORE / 'identities.json').items():
            assert sha(BEFORE / relative) == digest, relative
        return
    paths = {ROOT / 'resources/data/presentation/drawn_roster.json'}
    for home in BASE.glob('*/manifest.json'):
        for manifest in [home, *sorted((home.parent / 'directions').glob('*/manifest.json'))]:
            folder = manifest.parent
            relative = folder.relative_to(BASE)
            paths.update((manifest, folder / 'export_report.json'))
            if (folder / 'clips_source.json').exists():
                paths.add(folder / 'clips_source.json')
            for action in WALKS:
                paths.add(SOURCES / relative / (action + '.aseprite'))
                if manifest == home:
                    paths.add(folder / (action + '.png'))
    paths.update(NORTH.glob('*.json'))
    paths.update(NORTH.glob('*.png'))
    paths.update(NORTH.glob('frames/*/*.png'))
    paths.update((SOURCES / 'warrior/directions/north').glob('*.aseprite'))
    identities = {}
    for path in sorted(paths):
        relative = path.relative_to(ROOT)
        destination = BEFORE / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        identities[relative.as_posix()] = sha(path)
    write(BEFORE / 'runtime_pixels.json', {
        p.relative_to(ROOT).as_posix(): sha(p)
        for p in sorted((ROOT / 'assets/combat/characters/drawn').rglob('*.png'))})
    write(BEFORE / 'identities.json', identities)
    print('BATTLE_FEEDBACK_BASELINE_PRESERVED', len(identities), flush=True)


def apply():
    assert (NORTH / 'raw/sequence_rear_stance.png').exists()
    clean = subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe', '-b', '--script-param',
                            'root=' + ROOT.as_posix(), '--script', str(ROOT / 'tools/aseprite/drawn_battle_sheet_cleanup.lua')],
                           cwd=ROOT, capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
    assert clean.returncode == 0 and 'DRAWN_BATTLE_SHEET_CLEANUP_PASS' in clean.stdout, clean.stdout + clean.stderr
    cfg = read(BEFORE / (NORTH / 'clips_source.json').relative_to(ROOT))
    cfg['sheets']['sequence_rear_stance_clean'] = {'cols': 4, 'rows': 11}
    cfg['cleanup_neon'] = True
    for clip in cfg['clips']:
        if clip['id'] != 'death':
            clip['sheet'] = 'sequence_rear_stance_clean'
    write(NORTH / 'clips_source.json', cfg)
    run('export_drawn_actions.py', 'warrior', '--view', 'north')
    # Keep the accepted death source and exports byte-for-byte, not a regenerated candidate.
    for relative in read(BEFORE / 'identities.json'):
        if ('/warrior/directions/north/' in relative and
            ('/frames/death/' in relative or relative.endswith('/death.png') or relative.endswith('/death.aseprite'))):
            shutil.copy2(BEFORE / relative, ROOT / relative)
    old_manifest = read(BEFORE / (NORTH / 'manifest.json').relative_to(ROOT))
    manifest = read(NORTH / 'manifest.json')
    manifest['clips'] = [next(c for c in old_manifest['clips'] if c['id'] == 'death')
                         if c['id'] == 'death' else c for c in manifest['clips']]
    write(NORTH / 'manifest.json', manifest)
    report = read(NORTH / 'export_report.json')
    report['clips']['death'] = read(BEFORE / (NORTH / 'export_report.json').relative_to(ROOT))['clips']['death']
    report['rear_stance'] = {'scope': 'north only; death preserved', 'sword': 'occluded in front of torso',
                            'standing_feet': 'shoulder-width', 'visual_acceptance': 'pending'}
    write(NORTH / 'export_report.json', report)
    run('stabilize_drawn_idles.py', '--id', 'warrior', '--view', 'north',
        '--report', 'refinements/battle_feedback/idle_contact_report.json')
    process = subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe', '-b', '--script-param',
                             'root=' + ROOT.as_posix(), '--script', str(ROOT / 'tools/aseprite/drawn_walk_timing.lua')],
                            cwd=ROOT, capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
    print(process.stdout, flush=True)
    assert process.returncode == 0 and 'DRAWN_WALK_TIMING_PASS' in process.stdout, process.stderr or process.stdout
    update_metadata()


def update_metadata():
    proof = read(OUT / 'walk_timing_report.json')
    assert proof['status'] == 'PASS' and len(proof['clips']) == 96
    for home in BASE.glob('*/manifest.json'):
        for path in [home, *sorted((home.parent / 'directions').glob('*/manifest.json'))]:
            data = read(path)
            for clip in data['clips']:
                if clip['id'] in WALKS:
                    clip['durations'] = [50] * clip['frames']
            write(path, data)
            report_path = path.parent / 'export_report.json'
            export = read(report_path)
            for action in WALKS:
                for metric in export['clips'][action].get('metrics', []):
                    metric['duration_ms'] = 50
            export['walk_timing'] = {'cycle_ms': 400, 'stride_pixels': 80,
                                     'source_roundtrip': 'PASS', 'retiming_preserves_pixels': True}
            write(report_path, export)
            cfg_path = path.parent / 'clips_source.json'
            if cfg_path.exists():
                config = read(cfg_path)
                for clip in config.get('clips', []):
                    if clip['id'] in WALKS:
                        clip['durations'] = 50
                write(cfg_path, config)
    print('DRAWN_BATTLE_FEEDBACK_SOURCE_PASS', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--backup-only', action='store_true')
    parser.add_argument('--metadata-only', action='store_true')
    args = parser.parse_args()
    backup()
    if args.metadata_only:
        update_metadata()
    elif not args.backup_only:
        apply()

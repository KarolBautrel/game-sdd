"""Stage58: isolate knight pose edits and calibrate cadence/stride, with Aseprite sources."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
ASE = ROOT / 'assets_src/aseprite/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/motion_balance'
BEFORE = OUT / 'before'
VIEWS = ('south_east', 'south', 'east', 'north_east', 'north')
SELECTED = ('neutral_idle', 'combat_idle', 'neutral_walk')


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def home(role, view):
    return BASE / role if view == 'south_east' else BASE / role / 'directions' / view


def ase(script, **params):
    command = ['C:/Program Files/Aseprite/Aseprite.exe', '-b', '--script-param', 'root=' + ROOT.as_posix()]
    for key, value in params.items():
        command += ['--script-param', key + '=' + str(value)]
    process = subprocess.run(command + ['--script', str(ROOT / 'tools/aseprite' / script)], cwd=ROOT,
                             capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW, timeout=300)
    print(process.stdout, flush=True)
    assert process.returncode == 0 and '_PASS' in process.stdout, process.stdout + process.stderr


def backup():
    BEFORE.mkdir(parents=True, exist_ok=True)
    index = BEFORE / 'identities.json'
    if index.exists():
        for relative, digest in read(index).items():
            assert sha(BEFORE / relative) == digest, relative
        return
    paths = {ROOT / 'resources/data/presentation/drawn_roster.json'}
    for main in BASE.glob('*/manifest.json'):
        for manifest in [main, *sorted((main.parent / 'directions').glob('*/manifest.json'))]:
            folder = manifest.parent
            relative = folder.relative_to(BASE)
            paths.update((manifest, folder / 'export_report.json'))
            for name in ('clips_source.json', 'mirror_recipe.json'):
                if (folder / name).exists():
                    paths.add(folder / name)
            actions = SELECTED if main.parent.name == 'knight' else ('neutral_walk', 'combat_walk')
            for action in set(actions) | {'neutral_walk', 'combat_walk'}:
                paths.add(ASE / relative / (action + '.aseprite'))
                if main.parent.name == 'knight' or manifest == main:
                    paths.add(folder / (action + '.png'))
            if main.parent.name == 'knight':
                paths.update(folder.glob('frames/*/*.png'))
    identities = {}
    for path in sorted(paths):
        relative = path.relative_to(ROOT)
        destination = BEFORE / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        identities[relative.as_posix()] = sha(path)
    write(index, identities)
    write(BEFORE / 'runtime_pixels.json', {p.relative_to(ROOT).as_posix(): sha(p)
          for p in sorted((ROOT / 'assets/combat/characters/drawn').rglob('*.png'))})
    print('DRAWN_MOTION_BASELINE_PASS', len(identities), flush=True)


def knight():
    for index, view in enumerate(VIEWS):
        candidate = OUT / 'candidates' / view
        (candidate / 'raw').mkdir(parents=True, exist_ok=True)
        for name in ('stances58', 'neutral_carry58'):
            shutil.copy2(OUT / 'raw' / (name + '.png'), candidate / 'raw' / (name + '.png'))
        clips = []
        for action, column in (('neutral_idle', 1), ('combat_idle', 3)):
            first = index * 4 + column
            clips.append({'id': action, 'title': 'Spoczynek' if column == 1 else 'Gotowość bojowa A',
                          'mode': 'neutral' if column == 1 else 'combat', 'sheet': 'stances58',
                          'start': first, 'indices': [first, first, first + 1, first + 1],
                          'reference_index': index * 4 + 1, 'count': 4, 'durations': 250, 'loop': True, 'resample': 'nearest'})
        clips.append({'id': 'neutral_walk', 'title': 'Chód spokojny', 'mode': 'neutral',
                      'sheet': 'neutral_carry58', 'start': index * 8 + 1, 'count': 8,
                      'durations': 100, 'loop': True, 'align_head': True, 'resample': 'nearest'})
        cfg = {'title': 'Rycerz · miecz dwuręczny', 'body_scale': True, 'cleanup_neon': True,
               'walk_stride_pixels': 160,
               'sheets': {'stances58': {'cols': 4, 'rows': 5},
                          'neutral_carry58': {'cols': 4, 'rows': 10, 'alpha_floor': 96}}, 'clips': clips}
        write(candidate / 'clips_source.json', cfg)
        output_ase = ROOT / 'artifacts/drawn-motion-candidates' / view
        ase('drawn_action_sheets.lua', id='knight', view=view, base=candidate.as_posix(), source=output_ase.as_posix())
        target = home('knight', view)
        original_manifest = read(target / 'manifest.json')
        incoming = read(candidate / 'manifest.json')
        incoming_clips = {c['id']: c for c in incoming['clips']}
        original_manifest['clips'] = [incoming_clips.get(c['id'], c) for c in original_manifest['clips']]
        original_manifest['walk_stride_pixels'] = 160
        original_report = read(target / 'export_report.json')
        for action in SELECTED:
            for source in (candidate / 'frames' / action).glob('*.png'):
                shutil.copy2(source, target / 'frames' / action / source.name)
            shutil.copy2(candidate / (action + '.png'), target / (action + '.png'))
            shutil.copy2(output_ase / (action + '.aseprite'), ASE / target.relative_to(BASE) / (action + '.aseprite'))
            original_report['clips'][action] = read(candidate / 'export_report.json')['clips'][action]
        original_report['knight_stance58'] = {'combat': 'wide/staggered guard A', 'neutral': 'lowered held sword', 'source_roundtrip': 'PASS'}
        active_cfg = read(target / 'clips_source.json')
        active_cfg['sheets'].update(cfg['sheets'])
        active_cfg['cleanup_neon'] = True
        active_cfg['walk_stride_pixels'] = 160
        for name in cfg['sheets']:
            shutil.copy2(candidate / 'raw' / (name + '.png'), target / 'raw' / (name + '.png'))
        for i, clip in enumerate(active_cfg['clips']):
            replacement = next((c for c in clips if c['id'] == clip['id']), None)
            if replacement:
                active_cfg['clips'][i] = replacement
        write(target / 'clips_source.json', active_cfg)
        write(target / 'manifest.json', original_manifest)
        write(target / 'export_report.json', original_report)
        subprocess.run([sys.executable, str(ROOT / 'tools/qa/stabilize_drawn_idles.py'), '--id', 'knight',
                        '--view', view, '--report', 'refinements/motion_balance/idle_' + view + '.json'], cwd=ROOT, check=True)
    mirrors()


def mirrors():
    for source, target in (('south_east', 'south_west'), ('east', 'west'), ('north_east', 'north_west')):
        ase('mirror_drawn_actions.lua', id='knight', **{'from': source, 'to': target}, actions=','.join(SELECTED))
    repair_mirror_reports()


def repair_mirror_reports():
    for view in ('south_west', 'west', 'north_west'):
        path = home('knight', view) / 'export_report.json'
        current = read(path)
        previous = read(BEFORE / path.relative_to(ROOT))
        previous['clips'].update(current['clips'])
        current['clips'] = previous['clips']
        write(path, current)


def timing():
    ase('drawn_walk_timing.lua', duration_ms=100, stride_pixels=160,
        report='refinements/motion_balance/walk_timing_report.json')
    metadata()


def metadata():
    proof = read(OUT / 'walk_timing_report.json')
    assert proof['status'] == 'PASS' and proof['duration_ms'] == 100 and len(proof['clips']) == 96
    repair_mirror_reports()
    for main in BASE.glob('*/manifest.json'):
        for path in [main, *sorted((main.parent / 'directions').glob('*/manifest.json'))]:
            data = read(path)
            data['walk_stride_pixels'] = 160
            for clip in data['clips']:
                if clip['id'] in ('neutral_walk', 'combat_walk'):
                    clip['durations'] = [100] * 8
            write(path, data)
            report_path = path.parent / 'export_report.json'
            report = read(report_path)
            for action in ('neutral_walk', 'combat_walk'):
                for metric in report['clips'][action].get('metrics', []):
                    metric['duration_ms'] = 100
            report['walk_timing'] = {'cycle_ms': 800, 'stride_pixels': 160,
                                     'source_roundtrip': 'PASS', 'retiming_preserves_pixels': True}
            write(report_path, report)
            cfg_path = path.parent / 'clips_source.json'
            if cfg_path.exists():
                cfg = read(cfg_path)
                cfg['walk_stride_pixels'] = 160
                for clip in cfg.get('clips', []):
                    if clip['id'] in ('neutral_walk', 'combat_walk'):
                        clip['durations'] = 100
                write(cfg_path, cfg)
    print('DRAWN_MOTION_METADATA_PASS', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--step', choices=['backup', 'knight', 'mirrors', 'timing', 'metadata', 'all'], default='all')
    args = parser.parse_args()
    if (OUT / 'rollback.json').exists():
        parser.error('Stage58 was explicitly rejected and rolled back. This archived recipe must not be reapplied.')
    backup()
    if args.step in ('knight', 'all'):
        knight()
    if args.step in ('timing', 'all'):
        timing()
    if args.step == 'mirrors':
        mirrors()
    if args.step == 'metadata':
        metadata()

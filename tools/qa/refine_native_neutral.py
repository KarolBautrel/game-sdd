"""New authorized stage60; native pose reuse and a calmer measured walk, not rejected58."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'assets_src/characters/drawn_animation/2026-11-03'
ASE = ROOT / 'assets_src/aseprite/characters/drawn_animation/2026-11-03'
OUT = BASE / 'refinements/native_neutral'
BEFORE = OUT / 'before'


def read(p):
    return json.loads(p.read_text(encoding='utf-8'))


def write(p, value):
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def ase(script, **params):
    args = ['C:/Program Files/Aseprite/Aseprite.exe', '-b', '--script-param', 'root=' + ROOT.as_posix()]
    for key, value in params.items():
        args += ['--script-param', key + '=' + str(value)]
    p = subprocess.run(args + ['--script', str(ROOT / 'tools/aseprite' / script)], capture_output=True,
                       text=True, cwd=ROOT, creationflags=subprocess.CREATE_NO_WINDOW, timeout=300)
    print(p.stdout, flush=True)
    assert p.returncode == 0 and '_PASS' in p.stdout, p.stdout + p.stderr


def backup():
    BEFORE.mkdir(parents=True, exist_ok=True)
    if (BEFORE / 'identities.json').exists():
        for name, digest in read(BEFORE / 'identities.json').items():
            assert sha(BEFORE / name) == digest, name
        return
    paths = {ROOT / 'resources/data/presentation/drawn_roster.json'}
    for main in BASE.glob('*/manifest.json'):
        for path in [main, *sorted((main.parent / 'directions').glob('*/manifest.json'))]:
            folder = path.parent
            relative = folder.relative_to(BASE)
            paths.update((path, folder / 'export_report.json'))
            if (folder / 'clips_source.json').exists():paths.add(folder / 'clips_source.json')
            for action in ('neutral_walk', 'combat_walk'):
                paths.add(ASE / relative / (action + '.aseprite'))
                if path == main:paths.add(folder / (action + '.png'))
            if main.parent.name == 'knight':
                paths.add(ASE / relative / 'neutral_idle.aseprite')
                paths.update(folder.glob('frames/neutral_idle/*.png'))
                paths.add(folder / 'neutral_idle.png')
    identities = {}
    for path in sorted(paths):
        name = path.relative_to(ROOT)
        target = BEFORE / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        identities[name.as_posix()] = sha(path)
    write(BEFORE / 'identities.json', identities)
    write(BEFORE / 'runtime_pixels.json', {p.relative_to(ROOT).as_posix():sha(p)
          for p in sorted((ROOT / 'assets/combat/characters/drawn').rglob('*.png'))})
    print('NATIVE_NEUTRAL_BASELINE_PASS', len(identities), flush=True)


def neutral():
    ase('knight_neutral_native.lua')
    proof = read(OUT / 'neutral_report.json')
    for view in proof['views']:
        folder = BASE / 'knight' if view['view'] == 'south_east' else BASE / 'knight/directions' / view['view']
        report = read(folder / 'export_report.json')
        if 'frames' in view:
            report['clips']['neutral_idle']['metrics'] = view['frames']
        report['native_neutral'] = {'source_roundtrip':'PASS','reference':'warrior neutral stance',
                                    'no_body_resampling':True,'head_boots':'native original pixels'}
        write(folder / 'export_report.json', report)
        manifest = read(folder / 'manifest.json')
        clip = next(c for c in manifest['clips'] if c['id'] == 'neutral_idle')
        clip['frame_source'] = 'native Aseprite pose composition'
        clip['native_postprocess'] = 'tools/aseprite/knight_neutral_native.lua'
        write(folder / 'manifest.json', manifest)
        cfg_path=folder/'clips_source.json'
        if cfg_path.exists():
            cfg=read(cfg_path)
            next(c for c in cfg['clips'] if c['id']=='neutral_idle')['native_postprocess']='tools/aseprite/knight_neutral_native.lua'
            write(cfg_path,cfg)


def timing():
    ase('drawn_walk_timing.lua',duration_ms=125,stride_pixels=160,
        report='refinements/native_neutral/walk_timing_report.json')
    for main in BASE.glob('*/manifest.json'):
        for path in [main, *sorted((main.parent / 'directions').glob('*/manifest.json'))]:
            data = read(path)
            data['walk_stride_pixels'] = 160
            for clip in data['clips']:
                if clip['id'] in ('neutral_walk','combat_walk'):clip['durations'] = [125]*8
            write(path,data)
            report = read(path.parent/'export_report.json')
            for action in ('neutral_walk','combat_walk'):
                for metric in report['clips'][action].get('metrics',[]):metric['duration_ms'] = 125
            report['walk_timing'] = {'cycle_ms':1000,'stride_pixels':160,'source_roundtrip':'PASS','retiming_preserves_pixels':True}
            write(path.parent/'export_report.json',report)
            cfg_path = path.parent/'clips_source.json'
            if cfg_path.exists():
                cfg = read(cfg_path);cfg['walk_stride_pixels'] = 160
                for clip in cfg.get('clips',[]):
                    if clip['id'] in ('neutral_walk','combat_walk'):clip['durations']=125
                write(cfg_path,cfg)
    print('NATIVE_GAIT_TIMING_PASS 1000ms / 160px',flush=True)


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--step',choices=['backup','neutral','timing','all'],default='all')
    args=parser.parse_args();backup()
    if args.step in ('neutral','all'):neutral()
    if args.step in ('timing','all'):timing()

"""Headless checks with retained logs, an explicit success marker and no windows."""
import argparse
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]
GODOT=ROOT.parents[1]/'installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--import-assets',action='store_true')
    parser.add_argument('--require-all',action='store_true')
    parser.add_argument('--regression',action='store_true')
    parser.add_argument('--only',nargs='+',choices=['runtime','original_roster','lifecycle','equipment','combat','feedback'])
    args=parser.parse_args()
    logs=ROOT/'artifacts/drawn-animation';logs.mkdir(parents=True,exist_ok=True)
    jobs=[]
    if args.import_assets:jobs.append(('import',['--editor','--import','--quit'],None))
    extra=['--','--require-all'] if args.require_all else []
    jobs.append(('runtime',['--script','res://scripts/presentation/drawn_animation_tests.gd']+extra,'Drawn animation:'))
    if args.regression or args.only:
        for name,script,marker in [
            ('original_roster','res://scripts/presentation/original_roster_tests.gd','Original roster:'),
            ('lifecycle','res://scripts/presentation/combat_animation_lifecycle_tests.gd','combat_animation_lifecycle_tests: OK'),
            ('equipment','res://scripts/session/equipment_appearance_tests.gd','Equipment appearance:'),
            ('combat','res://scripts/domain/combat_slice_tests.gd','Godot combat slice validation passed.'),
            ('feedback','res://scripts/presentation/combat_feedback_polish_tests.gd','combat_feedback_polish_tests:'),
        ]:jobs.append((name,['--script',script],marker))
    if args.only:jobs=[j for j in jobs if j[0] in args.only or j[0]=='import']
    for name,tail,marker in jobs:
        p=subprocess.run([str(GODOT),'--headless','--path',str(ROOT)]+tail,cwd=ROOT,
            capture_output=True,text=True,encoding='utf-8',errors='replace',
            creationflags=subprocess.CREATE_NO_WINDOW,timeout=180)
        output=p.stdout+'\n'+p.stderr;(logs/(name+'.log')).write_text(output,encoding='utf-8')
        errors=[line for line in output.splitlines() if 'SCRIPT ERROR:' in line or 'ERROR:' in line or 'WARNING:' in line]
        assert p.returncode==0 and not errors and (marker is None or marker in output),(name,p.returncode,'\n'.join(errors),output[-2000:])
        print('DRAWN_GODOT_'+name.upper()+'_PASS')
        if marker:print(next(line for line in output.splitlines() if marker in line))
    (logs/('result-selected.json' if args.only else 'result.json')).write_text(json.dumps({'status':'PASS','require_all':args.require_all,
        'suites':[j[0] for j in jobs],
        'regression':args.regression,'continuous_motion_reviewed':False,'desktop_input_used':False},indent=2)+'\n')

if __name__=='__main__':main()

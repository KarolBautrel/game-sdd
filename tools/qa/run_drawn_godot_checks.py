"""Headless checks with retained logs, an explicit success marker and no windows."""
import argparse
from datetime import datetime, timezone
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
    parser.add_argument('--only',nargs='+',choices=['runtime','battle','tactical','enemy_pilot','original_roster','lifecycle','equipment','combat','feedback'])
    args=parser.parse_args()
    logs=ROOT/'artifacts/drawn-animation';logs.mkdir(parents=True,exist_ok=True)
    jobs=[]
    if args.import_assets:jobs.append(('import',['--editor','--import','--quit'],None))
    extra=['--','--require-all'] if args.require_all else []
    jobs.append(('runtime',['--script','res://scripts/presentation/drawn_animation_tests.gd']+extra,'Drawn animation:'))
    if args.regression or args.only:
        for name,script,marker in [
            ('battle','res://scripts/presentation/drawn_battle_review_tests.gd','Drawn battle review:'),
            ('tactical','res://scripts/presentation/tactical_facing_tests.gd','Tactical facing:'),
            ('enemy_pilot','res://scripts/presentation/painted_enemy_pilot_tests.gd','Painted enemy pilot:'),
            ('original_roster','res://scripts/presentation/original_roster_tests.gd','Original roster:'),
            ('lifecycle','res://scripts/presentation/combat_animation_lifecycle_tests.gd','combat_animation_lifecycle_tests: OK'),
            ('equipment','res://scripts/session/equipment_appearance_tests.gd','Equipment appearance:'),
            ('combat','res://scripts/domain/combat_slice_tests.gd','Godot combat slice validation passed.'),
            ('feedback','res://scripts/presentation/combat_feedback_polish_tests.gd','combat_feedback_polish_tests:'),
        ]:jobs.append((name,['--script',script],marker))
    if args.only:jobs=[j for j in jobs if j[0] in args.only or j[0]=='import']
    result_path=logs/('result-selected.json' if args.only else 'result.json')
    result={'status':'RUNNING','started_utc':datetime.now(timezone.utc).isoformat(),
        'require_all':args.require_all,'suites':[j[0] for j in jobs],'completed_suites':[],
        'regression':args.regression,'continuous_motion_reviewed':False,'desktop_input_used':False}
    def save_result():result_path.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    save_result()
    try:
        for name,tail,marker in jobs:
            result['current_suite']=name;save_result()
            p=subprocess.run([str(GODOT),'--headless','--path',str(ROOT)]+tail,cwd=ROOT,
                capture_output=True,text=True,encoding='utf-8',errors='replace',
                creationflags=subprocess.CREATE_NO_WINDOW,timeout=180)
            output=p.stdout+'\n'+p.stderr;(logs/(name+'.log')).write_text(output,encoding='utf-8')
            errors=[line for line in output.splitlines() if 'SCRIPT ERROR:' in line or 'ERROR:' in line or 'WARNING:' in line]
            assert p.returncode==0 and not errors and (marker is None or marker in output),(name,p.returncode,'\n'.join(errors),output[-2000:])
            result['completed_suites'].append(name);save_result()
            print('DRAWN_GODOT_'+name.upper()+'_PASS',flush=True)
            if marker:print(next(line for line in output.splitlines() if marker in line),flush=True)
    except Exception as exc:
        result.update(status='FAIL',error=str(exc));save_result()
        raise
    result.update(status='PASS',finished_utc=datetime.now(timezone.utc).isoformat());save_result()

if __name__=='__main__':main()

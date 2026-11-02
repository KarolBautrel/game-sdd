"""Render the real campaign in a minimized no-focus native GPU test project.

No OS input, no desktop activation and no player save. Source mode uses local
junctions and its own .godot metadata. Release mode copies an EXE/PCK pair.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
GODOT=ROOT.parents[1]/'installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'

def literal(path: Path) -> str:
    return "'"+str(path).replace("'","''")+"'"

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id',required=True)
    parser.add_argument('--views',default='stash')
    parser.add_argument('--sizes',default='1920x1080')
    parser.add_argument('--exercise',action='store_true')
    parser.add_argument('--exe',type=Path)
    parser.add_argument('--suite',choices=['campaign','play'],default='campaign')
    args=parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9_-]+',args.run_id): parser.error('Invalid run id')
    out=ROOT/'artifacts/qa-runs'/args.run_id
    if out.exists(): parser.error('Run already exists; use a fresh id')
    project=out/'project'
    project.mkdir(parents=True)
    if args.exe:
        executable=project/'sdd-game.exe'
        shutil.copy2(args.exe,executable)
        shutil.copy2(args.exe.with_suffix('.pck'),executable.with_suffix('.pck'))
    else:
        executable=GODOT
        shutil.copy2(ROOT/'project.godot',project/'project.godot')
        for name in ('icon.svg','icon.svg.import'):
            if (ROOT/name).exists(): shutil.copy2(ROOT/name,project/name)
        for folder in ('scripts','scenes','resources','assets','addons','tools'):
            command='New-Item -ItemType Junction -Path '+literal(project/folder)+' -Target '+literal(ROOT/folder)+' | Out-Null'
            subprocess.run(['powershell','-NoProfile','-Command',command],check=True,capture_output=True)
        cache=project/'.godot'
        cache.mkdir()
        subprocess.run(['powershell','-NoProfile','-Command','New-Item -ItemType Junction -Path '+literal(cache/'imported')+' -Target '+literal(ROOT/'.godot/imported')+' | Out-Null'],check=True,capture_output=True)
        for name in ('global_script_class_cache.cfg','uid_cache.bin'):
            source=ROOT/'.godot'/name
            if source.exists(): shutil.copy2(source,cache/name)
    (project/'override.cfg').write_text('''; isolated no-focus GPU fixture only
[application]
config/name="SDD isolated campaign UI review"
run/main_scene="res://scenes/app/App.tscn"
config/use_custom_user_dir=true
config/custom_user_dir_name="sdd-campaign-ui-qa"
[display]
window/size/no_focus=true
window/size/mode=1
window/size/initial_position_type=3
window/size/initial_screen=0
window/size/window_width_override=64
window/size/window_height_override=64
window/size/viewport_width=64
window/size/viewport_height=64
window/stretch/mode="disabled"
''',encoding='utf-8')
    command=[str(executable)]
    if not args.exe: command.extend(['--path',str(project)])
    command.extend(['--audio-driver','Dummy','--max-fps','30','--','--qa-'+('play' if args.suite=='play' else 'campaign')+'-review','--review-output='+out.as_posix(),'--review-views='+args.views,'--review-sizes='+args.sizes])
    if args.exercise: command.append('--review-exercise')
    with (out/'stdout.log').open('w',encoding='utf-8') as stdout,(out/'stderr.log').open('w',encoding='utf-8') as stderr:
        try:
            result=subprocess.run(command,cwd=project,stdout=stdout,stderr=stderr,timeout=180)
        except subprocess.TimeoutExpired:
            print('Native render timed out; its process was stopped')
            return 1
    diagnostics=(out/'stdout.log').read_text(encoding='utf-8')+'\n'+(out/'stderr.log').read_text(encoding='utf-8')
    report_path=out/'native-review.json'
    report=json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else {'status':'FAIL','reason':'No native report'}
    report['command']=command
    report['exit_code']=result.returncode
    report['errors']=len(re.findall(r'^\s*(?:SCRIPT ERROR:|ERROR:)',diagnostics,re.M))
    report['warnings']=len(re.findall(r'^\s*WARNING:',diagnostics,re.M))
    if result.returncode or report['errors']: report['status']='FAIL'
    report['physical_desktop_acceptance']='NOT_RUN'
    report['packaged_build']=bool(args.exe)
    if args.exe:
        report['exe_sha256']=hashlib.sha256(executable.read_bytes()).hexdigest()
        report['pck_sha256']=hashlib.sha256(executable.with_suffix('.pck').read_bytes()).hexdigest()
    report_path.write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({key:report.get(key) for key in ('status','engine_clicks','errors','warnings','failures','physical_desktop_acceptance')},indent=2))
    print('Native evidence: '+str(report_path))
    if report['status']!='PASS': print(diagnostics[-7000:])
    return 0 if report['status']=='PASS' else 1

if __name__=='__main__': raise SystemExit(main())

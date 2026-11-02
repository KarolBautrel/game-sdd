"""Read-only protocol/version smoke for the locally installed Godot MCP."""
from __future__ import annotations
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
server = Path.home() / '.codex/tools/godot-mcp/build/index.js'
godot = ROOT.parents[1] / 'installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
requests = [
    {'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-03-26','capabilities':{},'clientInfo':{'name':'sdd-qa','version':'1.0'}}},
    {'jsonrpc':'2.0','method':'notifications/initialized'},
    {'jsonrpc':'2.0','id':2,'method':'tools/list','params':{}},
    {'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'get_godot_version','arguments':{}}},
]
env = {**os.environ,'GODOT_PATH':str(godot)}
process = subprocess.Popen(['node',str(server)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,encoding='utf-8',env=env)
try:
    stdout, stderr = process.communicate('\n'.join(json.dumps(r) for r in requests)+'\n',timeout=12)
except subprocess.TimeoutExpired:
    process.kill()
    stdout, stderr = process.communicate()
responses = {}
for line in stdout.splitlines():
    try:
        message = json.loads(line)
    except ValueError:
        continue
    if 'id' in message:
        responses[message['id']] = message
tools = responses.get(2,{}).get('result',{}).get('tools',[])
names = {t['name'] for t in tools}
version = json.dumps(responses.get(3,{}))
required = {'get_godot_version','run_interactive','game_screenshot','send_mouse_click','send_key_sequence'}
ok = required <= names and '4.7.stable' in version and not any('error' in r for r in responses.values())
report = {'status':'PASS' if ok else 'FAIL','tool_count':len(tools),'required_tools':sorted(required),'version_response':responses.get(3,{}),'stderr':stderr,'changes_project':False}
out = ROOT / 'artifacts/qa-runs/stage23-tools-20261102'
out.mkdir(parents=True,exist_ok=True)
(out/'mcp-protocol.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(0 if ok else 1)

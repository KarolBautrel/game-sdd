"""Fail-closed headless campaign proofs; no visible windows or player save writes."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT.parents[1]/'installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
OUT = ROOT/'artifacts/bran-identity'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--only', nargs='+', choices=['catalogue', 'drawn_regression', 'identity', 'campaign_gear', 'campaign', 'trade', 'validation'])
    selected = parser.parse_args().only
    OUT.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'completed': [], 'desktop_input': False, 'physical_acceptance': 'NOT_RUN'}
    def save():
        (OUT/('checks-selected.json' if selected else 'checks.json')).write_text(json.dumps(result, indent=2)+'\n')
    save()
    jobs = [('catalogue', [sys.executable, 'tools/assets/build_catalogue.py'], 'Catalogued'),
            ('drawn_regression', [sys.executable, 'tools/qa/run_drawn_godot_checks.py', '--import-assets', '--require-all', '--regression'], 'DRAWN_GODOT_FEEDBACK_PASS')]
    for name, script, marker in [
        ('identity', 'hero_equipment_identity_tests', 'Hero equipment identity:'),
        ('campaign_gear', 'campaign_equipment_tests', 'campaign_equipment_tests:'),
        ('campaign', 'campaign_session_tests', 'Campaign session tests passed'),
        ('trade', 'town_trade_tests', 'town_trade_tests:')]:
        jobs.append((name, [str(GODOT), '--headless', '--path', str(ROOT), '--script', f'res://scripts/session/{script}.gd'], marker))
    jobs.append(('validation', [sys.executable, 'tools/validators/validate_all.py'], 'Validation passed.'))
    if selected:
        jobs = [j for j in jobs if j[0] in selected]
    try:
        for name, args, marker in jobs:
            result['current'] = name;save()
            p = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace',
                               creationflags=subprocess.CREATE_NO_WINDOW, timeout=480)
            log = p.stdout+'\n'+p.stderr
            (OUT/(name+'.log')).write_text(log, encoding='utf-8')
            diagnostics = [x for x in log.splitlines() if any(s in x for s in ['SCRIPT ERROR:', 'ERROR:', 'WARNING:'])]
            assert p.returncode == 0 and not diagnostics and marker.lower() in log.lower(), (name, p.returncode, log[-6000:])
            result['completed'].append(name);save()
            print('HERO_EQUIPMENT_'+name.upper()+'_PASS', flush=True)
    except Exception as e:
        result.update(status='FAIL', error=str(e));save();raise
    result['status'] = 'PASS';save()


if __name__ == '__main__':
    main()

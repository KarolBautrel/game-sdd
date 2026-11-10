"""Portable strict shapes/references/accounting; Godot owns exact navigation and runs."""
from __future__ import annotations
import copy
import json
from pathlib import Path
from jsonschema import Draft202012Validator
from tools.validators.strategic_region import reference_errors as regional_errors
from tools.validators.terrain import terrain_errors

ROOT = Path(__file__).resolve().parents[2]

def reference_errors(s):
    schema = json.loads((ROOT / 'resources/schemas/autonomous_campaign.schema.json').read_text())
    errors = [f'autonomous shape: {e.message}' for e in Draft202012Validator(schema).iter_errors(s)]
    if errors:
        return errors
    life, world = s['life'], s['strategy_world']
    extra = dict(life['sites'], **life['politics']['outposts'])
    base = copy.deepcopy(s)
    base.pop('life'); base['version'] = 3
    errors.extend(regional_errors(base, extra))
    errors.extend(terrain_errors(s['region']['base']['terrain'], extra.values()))
    stats = life['stats']; actors = life['actors']; politics = life['politics']
    if sum(a['strength'] for a in actors.values()) + stats['casualties'] + stats['transferred'] != life['initial_strength'] + stats['recruited']:
        errors.append('independent actor strength created/lost without accounting')
    if sum(a['wallet'] for a in actors.values()) + 2 * stats['recruited'] != 8 * len(actors) + stats['fees']:
        errors.append('independent actor wallet differs from actual paid fees')
    if sum(p['garrison'] for p in politics['outposts'].values()) + politics['casualties'] != politics['initial_guards'] + politics['recruited'] + stats['transferred']:
        errors.append('garrison strength created/lost without accounting')
    if sum(politics['reserve'].values()) + politics['recruited'] != 72:
        errors.append('local reserve recruitment differs')
    for family, reserve in life['regions']['reserve'].items():
        if reserve + sum(m['strength'] for m in life['regions']['migrations'].values() if m['family'] == family) != 24:
            errors.append('migration reserve is not finite/conserved')
    for identifier, site in life['sites'].items():
        if identifier != site['id'] or site['episode'] not in life['episodes'] or site['patron'] not in world['core']['factions'] or site['home'] not in s['region']['sites']:
            errors.append('unknown site episode/patron/home')
        if (site['status'] == 'cleared') != (site['strength'] == 0):
            errors.append('contradictory site occupation')
        if len(set(site['history'])) != len(site['history']) or any(h not in life['episodes'] for h in site['history']):
            errors.append('duplicate/unknown site history')
    for identifier, e in life['episodes'].items():
        if e['id'] != identifier or e['site'] not in life['sites'] or (e['actor'] and e['actor'] not in actors):
            errors.append('unknown episode site/actor'); continue
        c = e['contract']
        if c and c['status'] in ('offered','npc','company','objective'):
            hold = world['core']['reservations'].get(c['hold'], {})
            if hold.get('status') != 'reserved' or hold.get('amount') != c['gold'] or hold.get('faction_id') != c['issuer'] or hold.get('purpose') != identifier:
                errors.append('commission lacks its reserved payment')
        if c and c['status'] == 'objective' and e['result'] != 'company':
            errors.append('unearned company reward')
    return errors

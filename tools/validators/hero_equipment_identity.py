"""Validate authored identity/kit references before runtime selection."""
import json
from pathlib import Path
from jsonschema import Draft202012Validator


def errors(root: Path, data=None):
    def read(rel):
        return json.loads((root/rel).read_text(encoding='utf-8'))
    data = read('resources/data/presentation/hero_equipment_identity.json') if data is None else data
    result = [e.message for e in Draft202012Validator(read('resources/schemas/hero_equipment_identity.schema.json')).iter_errors(data)]
    if result:
        return result
    profiles = {}
    for rel in ['drawn_roster.json', 'hero_identity_animations.json']:
        for p in read('resources/data/presentation/'+rel)['profiles']:
            if p['id'] in profiles:
                result.append('Duplicate animation identity '+p['id'])
            profiles[p['id']] = p
    known = {'hero_bran': 'unit_player_001', 'hero_torin': 'unit_player_002'}
    for hero, identity in data['heroes'].items():
        if known.get(hero) != identity['combat_unit_id']:
            result.append('Unknown/mismatched hero identity '+hero)
        seen = set()
        for kit in identity['kits']:
            pair = (kit['weapon'], kit['offhand'])
            if pair in seen or pair == ('greatsword', 'shield'):
                result.append('Ambiguous or impossible hero kit '+hero)
            seen.add(pair)
            character = kit['visual']['character']
            p = profiles.get(character)
            if not p or not p.get('enabled') or not p.get('source_roundtrip'):
                result.append('Missing/disabled authored kit '+character)
                continue
            for action in ['neutral_idle', 'combat_idle', 'neutral_walk', 'combat_walk', 'attack', 'hit', 'death']:
                count = p['frame_counts'].get(action, 0)
                if count < 1 or len(p['durations_ms'].get(action, [])) != count:
                    result.append('Incomplete authored clip '+character+'/'+action)
                for view in p['facings']:
                    for n in range(count):
                        path = root/p['root'].removeprefix('res://')/action/f'{character}_{view}_{action}_{n:03}.png'
                        if not path.is_file():
                            result.append('Missing authored frame '+path.as_posix())
    return result

"""Structural acceptance gates for authored template catalogues."""
import json
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def template_errors(template: dict) -> list[str]:
    errors = []
    rooms = template.get('rooms', [])
    ids = [room['id'] for room in rooms]
    if len(set(ids)) != len(ids): errors.append('duplicate room ids')
    positions = [(r['position']['x'], r['position']['y']) for r in rooms]
    if len(set(positions)) != len(positions): errors.append('overlapping room positions')
    starts = [r['id'] for r in rooms if r['kind'] == 'entrance']
    if len(starts) != 1 or not any(r['kind'] == 'exit' for r in rooms): errors.append('entrance/exit required')
    adjacency = {id: [] for id in ids}; edges = set(); edge_ids = set()
    for edge in template.get('corridors', []):
        a, b = edge['from'], edge['to']; pair = tuple(sorted((a, b)))
        if a == b or a not in adjacency or b not in adjacency or pair in edges or edge['id'] in edge_ids:
            errors.append('invalid/duplicate corridor'); continue
        edges.add(pair); edge_ids.add(edge['id']); adjacency[a].append(b); adjacency[b].append(a)
    visited = set(); queue = deque(starts)
    while queue:
        id = queue.popleft()
        if id in visited: continue
        visited.add(id); queue.extend(adjacency[id])
    if len(visited) != len(ids): errors.append('disconnected rooms')
    counts = {kind: sum(c['type'] in types for r in rooms for c in r['content']) for kind, types in {
        'combat_count': ('combat', 'guarded_treasure'), 'treasure_count': ('treasure', 'guarded_treasure')}.items()}
    counts['corridor_hazard_candidates'] = sum(e.get('hazard_profile') == 'planned' for e in template.get('corridors', []))
    for key, value in counts.items():
        if template.get('pacing', {}).get(key) != value: errors.append(f'pacing {key} mismatch')
    if counts['combat_count'] < (3 if 'deep_mine' in template.get('profile_ids', []) else 1) or counts['treasure_count'] < 1:
        errors.append('combat/treasure minimum')
    if template.get('acceptance_state') not in ('candidate', 'accepted'): errors.append('explicit acceptance_state required')
    return errors


def catalogue_errors() -> list[str]:
    errors = []; accepted = set(); seen = set()
    for path in sorted((ROOT / 'resources/data/dungeon_templates').glob('*.json')):
        for template in json.loads(path.read_text())['templates']:
            id = template['id']
            if id in seen: errors.append(f'duplicate template id {id}')
            seen.add(id)
            # Candidates may be unfinished but must stay outside gameplay selection.
            if template.get('acceptance_state') != 'accepted': continue
            errors.extend(f'{id}: {e}' for e in template_errors(template))
            accepted.update(template['profile_ids'])
    if accepted != {'short_mine', 'medium_mine', 'deep_mine'}: errors.append('accepted templates required for all profiles')
    return errors

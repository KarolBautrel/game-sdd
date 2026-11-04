"""Cross-reference and route safety for small isolated town spaces."""
import json
from collections import deque
from jsonschema import Draft202012Validator


def errors(root, data=None):
    def read(path):
        return json.loads((root/path).read_text(encoding='utf-8'))
    data=read('resources/data/town_spaces/ravenford_courtyard.json') if data is None else data
    failures=[e.message for e in Draft202012Validator(read('resources/schemas/town_space.schema.json')).iter_errors(data)]
    if failures:return failures
    path=root/data['map_path'].removeprefix('res://')
    if not path.is_file():return ['Town space map is missing']
    mapped=json.loads(path.read_text(encoding='utf-8'))
    spawns={r['id']:(r['x'],r['y']) for r in mapped['test_spawns']}
    requested=[data['entry_spawn']]+[n['spawn_id'] for n in data['npcs']]
    if len(set(requested))!=len(requested):failures.append('Town spawns overlap roles')
    if len({n['id'] for n in data['npcs']})!=len(data['npcs']):failures.append('Duplicate town NPC id')
    profiles={r['id']:r for r in read('resources/data/presentation/drawn_roster.json')['profiles']}
    for npc in data['npcs']:
        profile=profiles.get(npc['profile'],{})
        if not profile.get('enabled') or len(profile.get('facings',[]))!=8:failures.append('Town NPC needs complete eight-facing profile')
    walkable={(t['x'],t['y']) for t in mapped['tiles'] if t['type']!='blocked'}
    if any(s not in spawns or spawns[s] not in walkable for s in requested):return failures+['Unknown/blocked town spawn']
    seen=set();queue=deque([spawns[data['entry_spawn']]])
    while queue:
        x,y=queue.popleft()
        if (x,y) in seen:continue
        seen.add((x,y))
        queue.extend(n for n in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)) if n in walkable and n not in seen)
    if any(spawns[s] not in seen for s in requested):failures.append('Town NPC approach is disconnected')
    return failures

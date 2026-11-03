"""Complete two-view sources, runtime copies and safe tactical replacement table."""
import hashlib
import json
from pathlib import Path
import struct
from jsonschema import Draft202012Validator


def errors(root: Path, data=None):
    def read(rel):return json.loads((root/rel).read_text(encoding='utf-8'))
    try:
        data=read('resources/data/presentation/tactical_roster.json') if data is None else data
        result=[e.message for e in Draft202012Validator(read('resources/schemas/tactical_roster.schema.json')).iter_errors(data)]
        if result:return result
        profiles={p['id']:p for p in data['profiles']}
        if len(profiles)!=3:result.append('Duplicate tactical actor identity')
        original={p['id'] for p in read('resources/data/presentation/original_roster.json')['characters']}
        if set(data['replacements'])-original:result.append('Unknown original actor replacement')
        if 'bandit_brute' in data['replacements']:result.append('Cleaver brute cannot be globally replaced by a shield fighter')
        for target in list(data['replacements'].values())+list(data['archetype_replacements'].values()):
            if target not in profiles:result.append('Missing enabled replacement '+target)
        for id,p in profiles.items():
            home=root/'assets_src/characters/tactical_batch/2026-11-03'/id
            proof=read(home.relative_to(root)/'source_proof.json')
            manifest=read(home.relative_to(root)/'manifest.json')
            if proof.get('status')!='PASS' or len(proof.get('clips',[]))!=len(p['frame_counts'])*2 or not all(c.get('roundtrip') for c in proof['clips']):result.append('Incomplete reopened sources '+id)
            if len(proof.get('source_hashes',{}))!=len(p['frame_counts'])*2:result.append('Incomplete canonical source hashes '+id)
            for path,sha in proof.get('source_hashes',{}).items():
                if hashlib.sha256((root/path).read_bytes()).hexdigest()!=sha:result.append('Changed source requires explicit re-export '+path)
            if set(p['frame_counts'])!=set(p['durations_ms']):result.append('Clip/duration mismatch '+id)
            if p['impact_frame']>=p['frame_counts']['attack']:result.append('Impact beyond attack '+id)
            if p['body_height']!=(95 if id=='painted_wolf' else 171):result.append('Wrong species body scale '+id)
            if manifest['body_height']!=p['body_height'] or manifest['walk_stride_pixels']!=160:result.append('Manifest/runtime scale mismatch '+id)
            for side in p['facings']:
                folder=home if side=='south_east' else home/'directions'/side
                view=read(folder.relative_to(root)/'manifest.json')
                clips={c['id']:c for c in view['clips']}
                for action,count in p['frame_counts'].items():
                    if len(p['durations_ms'][action])!=count or clips[action]['durations']!=p['durations_ms'][action]:result.append('Source timing mismatch '+id+action)
                    source=root/'assets_src/aseprite/characters/tactical_batch/2026-11-03'/id/side/(action+'.aseprite')
                    if not source.is_file():result.append('Missing editable source '+str(source))
                    for n in range(count):
                        runtime=root/p['root'].removeprefix('res://')/action/f'{id}_{side}_{action}_{n:03}.png'
                        canonical=folder/'frames'/action/f'{n:03}.png'
                        a,b=runtime.read_bytes(),canonical.read_bytes()
                        if a!=b or struct.unpack('>II',a[16:24])!=(384,320):result.append('Runtime differs from canonical source frame '+str(runtime))
            for action,target in p.get('action_aliases',{}).items():
                if action!='status_reaction' or target not in p['frame_counts']:result.append('Invalid authored reaction alias '+id)
        return result
    except (OSError,ValueError,KeyError,TypeError) as exc:
        return ['Tactical roster: '+str(exc)]

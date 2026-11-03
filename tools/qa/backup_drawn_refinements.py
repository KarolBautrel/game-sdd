"""Retain affected pre-correction frames, editable sources and provenance."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/drawn_animation/2026-11-03'
OUT=BASE/'refinements/before'
SOURCES=ROOT/'assets_src/aseprite/characters/drawn_animation/2026-11-03'

def main():
    identities={}
    for home in BASE.glob('*/manifest.json'):
        role=home.parent.name
        for manifest in [home,*sorted((home.parent/'directions').glob('*/manifest.json'))]:
            view='south_east' if manifest==home else manifest.parent.name
            data=json.loads(manifest.read_text(encoding='utf-8'))
            actions={'neutral_idle','combat_idle'}
            if role=='archer_1':actions.add('attack')
            if role=='warrior' and view in ('north','north_east','north_west'):
                actions.update(c['id'] for c in data['clips'])
            files=[manifest,manifest.parent/'export_report.json']
            cfg=manifest.parent/'clips_source.json'
            if cfg.is_file():files.append(cfg)
            for action in actions:
                files.extend(sorted((manifest.parent/'frames'/action).glob('*.png')))
                files.append(manifest.parent/(action+'.png'))
                source=SOURCES/role
                if view!='south_east':source=source/'directions'/view
                files.append(source/(action+'.aseprite'))
            for path in files:
                relative=path.relative_to(ROOT)
                destination=OUT/relative
                destination.parent.mkdir(parents=True,exist_ok=True)
                if not destination.exists():shutil.copy2(path,destination)
                identities[relative.as_posix()]=hashlib.sha256(destination.read_bytes()).hexdigest()
    (OUT/'identities.json').write_text(json.dumps(identities,indent=2)+'\n')
    print('DRAWN_REFINEMENT_BASELINE_PRESERVED',len(identities))

if __name__=='__main__':main()

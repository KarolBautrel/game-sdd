"""Collect authored modular actor exports into the runtime presentation catalogue."""
import hashlib,json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def main():
    rows={}
    for source in sorted((ROOT/'assets_src/characters/modular').glob('*/model.json')):
        row=json.loads(source.read_text())
        row['sha256']=hashlib.sha256((ROOT/row['resource'].removeprefix('res://')).read_bytes()).hexdigest()
        rows[row['id']]=row
    aliases=json.loads((ROOT/'resources/data/presentation/original_roster.json').read_text())['aliases']
    for alias,target in aliases.items():
        if target in rows:rows[alias]=dict(rows[target])
    (ROOT/'resources/data/presentation/modular_actors.json').write_text(json.dumps(rows,indent=2)+'\n')
    print('Modular actor catalogue:',len(rows))

if __name__=='__main__':main()

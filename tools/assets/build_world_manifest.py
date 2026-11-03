"""Route retained authoring IDs to the coherent original environment family."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
exact={}
for prefix,names in {
 'nature_1':['oak','bush','bush','flowers','branches','stump','fallen_log','stump','boulder','boulder','rock_cluster'],
 'nature_2':['fallen_log','bush','grass','boulder','rock_cluster','grass','rock_cluster','bush','grass','branches','branches','mushrooms'],
 'dung_1':['statue','brazier','rubble','broken_pillar','bones','pillar','crate','chest','altar','statue','bones'],
 'dung_2':['arch','crate','rock_cluster','branches','pillar','bone_totem','coffin','brazier','spike_fence','rubble','broken_pillar']}.items():
    exact.update({f'{prefix}_{i:02d}':name for i,name in enumerate(names)})
def target(path):
    stem=Path(path).stem
    if stem in exact:return exact[stem]
    for marker,name in [('column','pillar'),('rubble','rubble'),('dung_stone','rock_cluster'),('tree_stump','stump'),('fallen_branch','branches'),('grass_tuft','grass'),('boulder','boulder'),('arched','arch'),('spike_fence','spike_fence'),('bone_spike','bone_totem'),('coffin','coffin'),('chest','chest'),('brazier','brazier'),('torch','brazier'),('wall','wall'),('barrel','barrel'),('crate','crate'),('sack','sacks'),('bone','bones'),('tree','oak'),('mushroom','mushrooms'),('fence','spike_fence'),('barricade','spike_fence')]:
        if marker in path:return name
    return 'rubble' if '/dungeon' in path or '/dung_' in path else 'rock_cluster'
def main():
    props=json.loads((ROOT/'assets_src/environment/props.json').read_text())
    routes={};floor_routes={}
    processed=json.loads((ROOT/'assets/combat/terrain/processed/processed_terrain_manifest.json').read_text())
    floor_paths={row['path'] for row in processed['assets'] if row.get('category')=='floor'}
    for row in json.loads((ROOT/'resources/catalogues/textures.json').read_text())['textures']:
        path=row['path']
        if '/combat/terrain/' in path or '/combat/dungeons/props/' in path:
            if path in floor_paths or any(marker in path for marker in ['/backgrounds/','/floors/','/grass/meadow_grass_floor']):
                floor_routes[path]='flagstone' if '/dung' in path or 'dungeon' in path else 'woodland'
            else:routes[path]=target(path)
    floors={name:'res://assets/combat/environment/floors/'+name+'.png' for name in ['woodland','earth','flagstone','cave']}
    data={'schema':'sdd.world-art-v1','assets':props,'legacy_routes':routes,'floor_routes':floor_routes,'floors':floors,'ledges':{theme:'res://assets/combat/environment/ledge_'+theme+'.png' for theme in ['nature','dungeon']}}
    (ROOT/'resources/data/presentation/world_art.json').write_text(json.dumps(data,indent=2)+'\n')
    files=[]
    for folder in ['assets_src/environment','assets_src/aseprite/environment','assets/combat/environment']:
        for path in sorted((ROOT/folder).rglob('*')):
            if path.is_file() and path.suffix in ['.png','.blend','.fbx','.aseprite','.json','.txt'] and path.name!='manifest.json':
                files.append({'path':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (ROOT/'assets_src/environment/manifest.json').write_text(json.dumps({'status':'PASS','files':files},indent=2)+'\n')
    print('World art:',len(props),'original props;',len(routes),'legacy routes;',len(files),'hashed sources/exports')
if __name__=='__main__':main()

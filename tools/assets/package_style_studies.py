"""Persist provenance and a self-contained source-art study delivery manifest."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/style_studies/2026-11-02'
CACHE=Path.home()/'.codex/tools/character-art/base-meshes'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


# These exact files were generated only by this study's quick passes / Blender
# save backups. Delete files individually after resolving them inside BASE.
removed=[]
for p in BASE.rglob('*'):
    if p.is_file() and (p.name.endswith(('_work.blend','_work.blend1','.blend1')) or p.name in ('quick.png','quick_face.png')):
        require_path=p.resolve();require_path.relative_to(BASE.resolve())
        removed.append(p.relative_to(BASE).as_posix());p.unlink()

provenance=dict(schema='sdd.character-style-provenance-v1',date='2026-11-02',
    anatomy=dict(name='Blender Studio Human Base Meshes v1.4.1',license='CC0-1.0',
        source='https://www.blender.org/download/demo-files/',
        archive='https://download.blender.org/demo/asset-bundles/human-base-meshes/human-base-meshes-bundle-v1.4.1.zip',
        archive_sha256=digest(CACHE/'human-base-meshes-bundle-v1.4.1.zip'),
        blend_sha256=digest(next((CACHE/'unpacked').rglob('human_base_meshes_bundle.blend'))),
        used=['GEO-body_male_realistic','GEO-body_male_stylized','corresponding anatomical eyes'],
        scope='Face/neck/eyes and derived fitted garment anatomy; underlying scaffold is third-party CC0, not authored from scratch.'),
    project_authored=['costume construction','cape folds','hair/beard treatment','armour','gloves and curled fingers','sword','round shield and heraldry','materials','camera/light recipe','comparative renders'],
    skills_researched=dict(repo='https://github.com/arjun988/blender-skills',revision='8f778d2405a214b508d4c7d80742be8e43acdd52',license='MIT',
        consulted=['character-artist','stylized-style','comic-book-style','hand-painted-style','painterly-style','stylized-style/references/npr-shaders.md'],installed=False),
    tools=dict(blender='5.2.3 LTS',aseprite='1.3.17.2',execution='owned background CLI; hidden Aseprite batch',cloud_generators=False,desktop_input=False),
    scope=dict(static=True,rigged=False,animated=False,game_integrated=False,status='AWAITING_STYLE_CHOICE'),
    comparison=dict(main='comparison.png',all_views='all_views.png',editable=['comparison.aseprite','all_views.aseprite'],
        native_scale='100px/m;384px source canvas, unscaled character in the ground composite',
        ground='retained assets/combat/environment/floors/earth.png + contact_shadow.png; reference composite, not gameplay screenshot'),
    limitations=['Not production retopology/LOD/animation assets.','B emission/ink hull and procedural bump are Blender-render features; FBX contains baked albedo and basic PBR values.','Textures are procedural/baked, not hand-painted final production maps.'])
(BASE/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf-8')
readme='''# Three actual 3D character style studies

Open `comparison.png` for A/B/C plus native100px/m ground composites, or
`all_views.png` for front/three-quarter/side/rear. `.aseprite` files are editable.

- A: anatomical veteran, leather brigandine, restrained matte wool/steel.
- B: graphic stepped shading, contour and hatching, angular armour.
- C: stylized head/face, broader heroic silhouette, brighter blue/brass.

Each folder includes a Blender scene, FBX,2048px albedo, six actual renders and
hashed model metadata. In Blender, enable the hidden AUTHORING collection to edit
separate costume/hair/gear pieces; hide the joined render actor while editing.
Lighting uses a common neutral orthographic recipe. B's contour hull is render-only.

These are **static prototypes**, not rigged/animated replacements. The restored
stage33 game roster and new world art remain unchanged. Choose a style before
starting a separate rigged pilot / motion and gameplay acceptance task.

See `docs/design/character-art/STYLE_RESEARCH.md` for research/rebuild commands,
`provenance.json` for CC0 scaffold attribution/tool limits and `verification.json`
for actual fresh-scene FBX reimports and production-baseline checks.
'''
(BASE/'README.md').write_text(readme,encoding='utf-8')
files=[]
for path in sorted(BASE.rglob('*')):
    if path.is_file() and path.name!='delivery.json':
        files.append(dict(path=path.relative_to(ROOT).as_posix(),bytes=path.stat().st_size,sha256=digest(path)))
result=dict(schema='sdd.character-style-delivery-v1',status='TECHNICAL_PASS',art_acceptance='AWAITING_STYLE_CHOICE',files=files)
(BASE/'delivery.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(f"Style study package: {len(files)} files, {sum(f['bytes'] for f in files)} bytes; {len(removed)} generated quick/backups removed")

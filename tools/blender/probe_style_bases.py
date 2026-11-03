"""Inspect the official CC0 Blender Studio base library without altering it."""
import bpy
import json
from pathlib import Path

cache = Path.home() / '.codex/tools/character-art/base-meshes/unpacked'
library = next(cache.rglob('*.blend'))
with bpy.data.libraries.load(str(library), link=False) as (src, dst):
    names = list(src.objects)
    dst.objects = names
data = []
for obj in dst.objects:
    if obj is None or obj.type != 'MESH':
        continue
    bpy.context.collection.objects.link(obj)
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    if not any(s in obj.name for s in ('GEO-body_male', 'Head -', 'Head ', 'Eye -')):
        continue
    data.append(dict(name=obj.name, parent=obj.parent.name if obj.parent else None, vertices=len(points), faces=len(obj.data.polygons),
                     bounds=[[round(min(p[i] for p in points), 4),
                              round(max(p[i] for p in points), 4)] for i in range(3)],
                     modifiers=[m.type for m in obj.modifiers]))
print('BASE_LIBRARY=' + str(library))
print('BASE_PROBE=' + json.dumps(data))

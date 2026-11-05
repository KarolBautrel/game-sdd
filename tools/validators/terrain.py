"""Semantic terrain shape and four-neighbour connectivity validation."""
from collections import deque
import math

CODES = set('RPFHMWXB')
PASSABLE = set('RPFHMB')


def terrain_errors(data, anchors=()):
    errors = []
    if not isinstance(data, dict):
        return ['terrain must be an object']
    w, h = data.get('width'), data.get('height')
    def integer(n):
        return type(n) in (int, float) and math.isfinite(n) and n == math.floor(n)
    if not integer(w) or not integer(h) or not 4 <= w <= 512 or not 4 <= h <= 288:
        return ['invalid terrain dimensions']
    w, h = int(w), int(h)
    if data.get('version') != 1 or data.get('region') != 'living_marches_v1':
        errors.append('unsupported terrain version/region')
    if not integer(data.get('revision')) or data['revision'] < 1:
        errors.append('invalid terrain revision')
    rows = data.get('rows')
    if not isinstance(rows, list) or len(rows) != h or any(not isinstance(r,str) or len(r) != w for r in rows):
        return errors + ['invalid terrain rows']
    if any(set(r)-CODES for r in rows):
        return errors + ['unknown terrain codes']

    def cell(point):
        x, y = point.get('x'), point.get('y')
        if not all(type(n) in (float,int) and math.isfinite(n) and 0 <= n < 1 for n in (x,y)):
            return (-1,-1)
        return int(x*w), int(y*h)

    def free(c):
        return 0 <= c[0] < w and 0 <= c[1] < h and rows[c[1]][c[0]] in PASSABLE

    anchors = list(anchors)
    if anchors:
        origin = cell(anchors[0]['position'])
        seen, queue = set(), deque()
        if free(origin):
            seen.add(origin)
            queue.append(origin)
        while queue:
            x,y = queue.popleft()
            for nxt in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if nxt not in seen and free(nxt):
                    seen.add(nxt)
                    queue.append(nxt)
        for anchor in anchors:
            c = cell(anchor['position'])
            if not free(c): errors.append(f"{anchor['id']} is blocked")
            elif c not in seen: errors.append(f"{anchor['id']} is disconnected")
    crossings = data.get('crossings', [])
    if not isinstance(crossings, list):
        return errors + ['invalid crossings']
    ids = set()
    for crossing in crossings:
        if not isinstance(crossing,dict) or not isinstance(crossing.get('position'),dict):
            errors.append('invalid crossing');continue
        c = cell(crossing['position'])
        if c == (-1,-1): errors.append('invalid crossing position')
        if not isinstance(crossing.get('id'),str) or not isinstance(crossing.get('name'),str): errors.append('invalid crossing identity')
        if crossing.get('id') in ids: errors.append('duplicate crossing id')
        ids.add(crossing.get('id'))
    return errors

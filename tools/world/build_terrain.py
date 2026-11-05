"""Rebuild the initial semantic terrain mask from hand-traced atlas geography.

Coordinates below are pixels on the approved1672x941 illustration. This is
navigation data, not image processing. Runtime/editor consume the exported rows.
Do not run over a designer-edited mask without preserving those edits first.
"""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIDTH, HEIGHT = 192, 108
PLATE = (1672, 941)


def polygon(p, vertices):
    inside = False
    x, y = p
    for a, b in zip(vertices, vertices[1:] + vertices[:1]):
        if (a[1] > y) != (b[1] > y) and x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:
            inside = not inside
    return inside


def segment_distance(p, a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]
    t = max(0, min(1, ((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy)))
    return math.hypot(p[0]-a[0]-t*dx, p[1]-a[1]-t*dy)


def build():
    rows = [['P']*WIDTH for _ in range(HEIGHT)]

    def fill(vertices, code):
        for y in range(HEIGHT):
            for x in range(WIDTH):
                if polygon(((x+.5)*PLATE[0]/WIDTH, (y+.5)*PLATE[1]/HEIGHT), vertices):
                    rows[y][x] = code

    def stroke(points, radius, code, protect=False):
        for y in range(HEIGHT):
            for x in range(WIDTH):
                if protect and rows[y][x] in 'WX':
                    continue
                p = ((x+.5)*PLATE[0]/WIDTH, (y+.5)*PLATE[1]/HEIGHT)
                if any(segment_distance(p,a,b)<=radius for a,b in zip(points,points[1:])):
                    rows[y][x] = code

    # Navigable foothills, then progressively more difficult mountain terrain.
    fill([(430,14),(1635,14),(1650,510),(1430,490),(1280,410),(1050,470),(800,530),(630,400),(550,190)], 'H')
    fill([(550,720),(730,590),(1030,630),(1150,810),(1100,925),(650,925),(560,845)], 'H')
    fill([(760,130),(900,112),(1030,180),(1000,350),(1110,420),(1030,510),(850,520),(695,435),(730,310)], 'M')
    fill([(990,20),(1640,20),(1645,250),(1480,290),(1290,215),(1170,240),(1070,160)], 'M')
    fill([(700,650),(870,610),(985,740),(1080,900),(880,930),(750,820)], 'M')
    # Forest canopy, traced independently of movement roads/rivers.
    fill([(125,210),(200,110),(390,23),(590,50),(715,100),(760,200),(700,310),(625,390),(520,432),(340,465),(100,425),(25,350)], 'F')
    fill([(615,612),(665,570),(800,580),(875,636),(760,685),(650,690)], 'F')
    # Peak ridges and sheer faces. Valleys/pass corridors remain accessible.
    for vertices in [
        [(780,165),(825,133),(890,149),(925,202),(1020,221),(1024,273),(900,255),(840,234)],
        [(810,276),(881,256),(948,280),(983,331),(960,377),(870,348),(814,397),(755,380)],
        [(772,421),(842,397),(915,405),(955,452),(903,494),(821,483)],
        [(1070,65),(1140,45),(1190,109),(1166,170),(1111,150),(1045,175),(1029,130)],
        [(1285,40),(1340,14),(1410,42),(1400,102),(1351,127),(1300,109)],
        [(1420,25),(1494,15),(1563,50),(1635,54),(1640,145),(1560,140),(1515,102),(1440,126)],
        [(1370,172),(1430,124),(1490,154),(1540,216),(1500,249),(1430,231)],
        [(706,653),(790,623),(839,676),(869,730),(839,787),(780,750),(748,700)],
        [(869,773),(913,751),(958,798),(1004,851),(1000,908),(940,926),(888,873)],
        [(80,45),(115,45),(122,135),(73,135)],
    ]:
        fill(vertices, 'X')
    # Sea follows the visible coast instead of the old coarse land polygon.
    fill([(1672,492),(1623,508),(1598,534),(1527,539),(1481,557),(1450,590),(1396,615),(1352,635),(1300,650),(1260,659),(1200,650),(1170,640),(1135,646),(1121,662),(1150,690),(1194,706),(1178,742),(1140,770),(1100,788),(1080,813),(1120,837),(1118,862),(1084,882),(1030,904),(977,920),(925,941),(1672,941)], 'W')
    fill([(950,505),(1000,515),(1030,535),(1046,570),(1100,603),(1140,620),(1170,640),(1135,660),(1080,641),(1035,626),(1000,615),(980,587),(939,566),(897,553),(912,535)], 'W')
    # Main north-south river, western tributary, waterfall branch.
    stroke([(790,117),(760,143),(711,156),(710,174),(751,187),(754,201),(717,218),(710,236),(741,250),(736,265),(708,285),(671,300),(643,305),(619,314),(585,322),(592,339),(606,350),(597,361),(564,370),(518,381),(472,400),(430,423),(386,435),(366,452),(372,477),(401,493),(440,512),(470,537),(478,565),(468,590),(443,611),(402,628),(377,645),(368,668),(345,687),(305,704),(260,715),(210,722),(182,738),(145,753),(115,758),(88,773),(60,792),(35,803),(20,822)], 12, 'W')
    stroke([(351,105),(330,119),(348,130),(366,140),(353,154),(320,164),(295,177),(280,203),(265,226),(240,240),(219,259),(224,280),(193,298),(178,310),(185,327),(210,339),(212,353),(193,370),(193,386),(218,400),(249,406),(281,420),(310,424),(341,433),(370,436)], 7.5, 'W')
    stroke([(966,370),(956,390),(937,407),(940,425),(967,447),(987,465),(985,482),(963,499),(935,513),(916,529),(908,546)], 9, 'W')
    # Roads follow the painted tracks. They cannot create accidental crossings.
    roads = [
        [(368,583),(367,611),(400,633),(445,649),(475,672),(492,704),(503,729),(537,756),(568,774),(616,780),(669,786)],
        [(405,631),(438,606),(477,587),(526,580),(579,581),(626,574),(674,566),(718,553),(757,532),(784,512),(824,504),(870,507),(913,520),(965,545),(1020,566),(1104,583)],
        [(439,402),(494,419),(556,432),(606,435),(651,452),(698,470),(727,496),(757,532)],
        [(439,402),(405,384),(381,362),(368,339),(350,325),(344,310),(362,298),(389,286),(423,275),(451,259)],
        [(1030,510),(1082,478),(1140,456),(1214,435),(1295,410),(1352,388),(1400,359),(1430,331)],
        [(1030,510),(1012,477),(1010,446),(1037,414),(1041,393),(1022,375),(1004,360),(1035,341),(1058,324),(1046,300),(1066,285),(1100,271),(1128,249),(1145,230),(1140,218),(1115,211),(1122,198),(1161,191),(1207,185),(1254,188)],
        [(752,187),(804,180),(843,178),(895,174),(944,185),(980,207),(1020,229),(1060,247),(1100,271)],
    ]
    for road in roads:
        stroke(road, 9, 'R', protect=True)
    # The authored High Pass marker denotes the narrow saddle between ridges.
    stroke([(774,192),(819,179),(849,194),(877,212)], 12, 'H')
    # Explicit crossings: Ravenford stone bridge, abbey bridge, northern ford,
    # and the coastal stream's road crossing. No implicit river walkability.
    crossings = [
        {'id':'ravenford_bridge','name':'Ravenford Bridge','points':[(343,617),(426,649)],'radius':13},
        {'id':'abbey_bridge','name':'Abbey Bridge','points':[(393,391),(462,419)],'radius':14},
        {'id':'highland_ford','name':'Highland Ford','points':[(728,169),(774,211)],'radius':13},
        {'id':'coastal_bridge','name':'Coastal Bridge','points':[(920,509),(1010,497)],'radius':13},
    ]
    for crossing in crossings:
        stroke(crossing['points'], crossing['radius'], 'B')
    # The decorative outer paper border is never a route around the geography.
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if x<2 or x>=WIDTH-2 or y<2 or y>=HEIGHT-2:
                rows[y][x] = 'W'
    return {'version':1, 'region':'living_marches_v1', 'revision':1,
            'width':WIDTH, 'height':HEIGHT, 'rows':[''.join(row) for row in rows],
            'crossings':[{'id':c['id'],'name':c['name'],'position':{
                'x':sum(p[0] for p in c['points'])/len(c['points'])/PLATE[0],
                'y':sum(p[1] for p in c['points'])/len(c['points'])/PLATE[1]}} for c in crossings]}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(build(),indent=2)+'\n',encoding='utf-8')
    print(f'Wrote {WIDTH}x{HEIGHT} semantic terrain to {args.output}')

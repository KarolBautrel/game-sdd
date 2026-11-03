"""Reuse the tested native-size player for the two authored Bran kits."""
import json
import os
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'assets_src/characters/hero_identity/bran'
BASE = ROOT/'assets_src/characters/drawn_animation/2026-11-03'


def main():
    registry = json.loads((ROOT/'resources/data/presentation/drawn_roster.json').read_text(encoding='utf-8'))
    new = json.loads((ROOT/'resources/data/presentation/hero_identity_animations.json').read_text())['profiles'][0]
    warrior = next(p for p in registry['profiles'] if p['id'] == 'warrior')
    profiles = []
    labels = {'neutral_idle':'Spoczynek', 'combat_idle':'Gotowosc bojowa', 'neutral_walk':'Chod spokojny',
              'combat_walk':'Chod bojowy', 'attack':'Atak', 'hit':'Trafienie', 'death':'Upadek'}
    total = 0
    for p, title in [(warrior, 'Bran / miecz i tarcza'), (new, 'Bran / miecz dwureczny')]:
        views = []
        for view in p['facings']:
            home = (BASE/'warrior' if view == 'south_east' else BASE/'warrior/directions'/view) if p['id'] == 'warrior' else OUT/'greatsword'/view
            clips = []
            for action, count in p['frame_counts'].items():
                path = home/(action+'.png')
                assert struct.unpack('>II', path.read_bytes()[16:24]) == (384*count, 320), path
                clips.append({'id':action, 'title':labels[action], 'atlas':action+'.png', 'frames':count,
                              'durations':p['durations_ms'][action], 'loop':action in ['neutral_idle','combat_idle','neutral_walk','combat_walk'],
                              'mode':'neutral' if action.startswith('neutral') else 'combat'})
                total += count
            views.append({'id':view, 'label':view+(' / odbicie' if view in ['south_west','west','north_west'] else ''),
                          'asset_base':os.path.relpath(home, OUT).replace('\\','/')+'/', 'clips':clips,
                          'direction_note':'Ta sama tozsamosc Brana; piec rysowanych widokow i trzy odbicia. Nowy wariant oczekuje oceny wizualnej.'})
        profiles.append({'id':p['id'], 'title':title, 'canvas':p['canvas'], 'pivot':p['pivot'],
                         'walk_stride_pixels':p['walk_stride_pixels'], 'views':views, 'exported_views':p['facings']})
    data = {'profiles':profiles, 'ground_base':os.path.relpath(ROOT/'assets/combat/environment/floors', OUT).replace('\\','/')+'/',
            'shadow':os.path.relpath(ROOT/'assets/combat/environment/contact_shadow.png', OUT).replace('\\','/')}
    template = (ROOT/'tools/qa/drawn_animation_player.html').read_text(encoding='utf-8')
    html = template.replace('__DRAWN_ANIMATION_DATA__', json.dumps(data, ensure_ascii=False))
    html = re.sub(r'<title>.*?</title>', '<title>Bran - dwa zestawy uzbrojenia</title>', html)
    (OUT/'preview.html').write_text(html, encoding='utf-8')
    (OUT/'player_data.json').write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    assert total == 704
    print('HERO_EQUIPMENT_PREVIEW_PASS 2 kits / 112 clips / 704 source frames; native1x and enlargement')


if __name__ == '__main__':
    main()

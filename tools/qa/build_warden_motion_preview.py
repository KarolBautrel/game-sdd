"""Package the existing native Blender renders as a local24fps review player."""
import json
from pathlib import Path
import shutil
import struct

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_src/characters/warden_motion_pilot/2026-11-03'
TITLES={'Idle':('Bezczynność','Oddech i przeniesienie ciężaru','Stopy pozostają na ziemi. Pancerz zachowuje sztywność.'),
        'Walk':('Chód','Dwa kroki / pełna pętla','Kamera podąża za postacią. Siatka pokazuje jej rzeczywisty ruch.'),
        'Sword':('Atak mieczem','Zamach, cięcie, powrót','Broń jest przypięta przez rękojeść do prawej dłoni.')}
VIEWS={'three_quarter':330,'front':0,'side':90,'rear':180}


def main():
    timing=json.loads((OUT/'timing.json').read_text());proof=json.loads((OUT/'motion_verification.json').read_text())
    assert proof['status'].startswith('TECHNICAL_PASS')
    clips=[];verified=0
    for index,(name,clip) in enumerate(timing['clips'].items(),1):
        count=clip['render_frames']
        for view in VIEWS:
            for frame in range(count):
                p=OUT/'renders'/name/view/(str(frame).zfill(3)+'.png')
                with p.open('rb') as f:header=f.read(33)
                assert header[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',header[16:24])==(384,384),str(p)
                assert header[25]==6,'RGBA required '+str(p)
                verified+=1
        title,subtitle,note=TITLES[name]
        clips.append(dict(id=name,frames=count,title=title,subtitle=subtitle,note=note,number='0'+str(index),feet=proof['clips'][name]['foot_tracks']))
    data=dict(fps=24,views=VIEWS,clips=clips)
    template=(ROOT/'tools/qa/warden_motion_player.html').read_text(encoding='utf-8')
    (OUT/'preview.html').write_text(template.replace('__MOTION_DATA__',json.dumps(data,ensure_ascii=False)),encoding='utf-8')
    shutil.copyfile(ROOT/'tools/qa/warden_motion_player.js',OUT/'player.js')
    result=dict(status='PASS',rgba_native_frames=verified,views=4,fps=24,tactical_pixels_per_metre=100,
        rendering='unchanged Blender PNGs; canvas is a player, not a new painted asset',external_network_requests=0,desktop_input_used=False,
        browser_ui_tested=False,continuous_playback_reviewed=False,browser_blocker='CUA isolated browser access host unavailable',
        javascript_syntax_check='node --check tools/qa/warden_motion_player.js')
    (OUT/'preview_verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print('WARDEN_PREVIEW_PASS',verified,'native frames, local24fps player')


if __name__=='__main__':main()

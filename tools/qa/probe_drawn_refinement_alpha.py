"""Summarize alpha without transforming raster assets."""
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]
image=ROOT/'assets_src/characters/drawn_animation/2026-11-03/archer_1/raw/attack_aim.png'
p=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b','--script-param',
    'input='+image.as_posix(),'--script',str(ROOT/'tools/aseprite/probe_drawn_alpha.lua')],
    capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
data=json.loads(p.stdout)
print(json.dumps({'size':[data['width'],data['height']],'samples':data['samples'],
    'alpha_0_31':sum(data['hist'][:32]),'alpha_255':data['hist'][255]}))

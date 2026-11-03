"""Produce and disclose the three mirrored left facings through Aseprite."""
import argparse
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('profiles',nargs='+')
    args=parser.parse_args()
    for profile in args.profiles:
        for source,target in [('south_east','south_west'),('east','west'),('north_east','north_west')]:
            result=subprocess.run(['C:/Program Files/Aseprite/Aseprite.exe','-b',
                '--script-param','root='+ROOT.as_posix(),'--script-param','id='+profile,
                '--script-param','from='+source,'--script-param','to='+target,
                '--script',str(ROOT/'tools/aseprite/mirror_drawn_actions.lua')],
                cwd=ROOT,capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
            print(result.stdout)
            assert result.returncode==0 and 'DRAWN_MIRROR_PASS' in result.stdout,result.stderr or result.stdout

if __name__=='__main__':main()

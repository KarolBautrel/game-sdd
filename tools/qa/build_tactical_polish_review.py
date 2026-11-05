"""Preserve unmodified native/desktop evidence and a file:// timed-frame player."""
import html
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/design/tactical-polish/2026-11-05"
RUNS = ROOT / "artifacts/qa-runs"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    entries = [
        ("painted-props-native-imported/arena-painted_forest_ambush-1920x1080.png", "Forest Ambush — painted environment"),
        ("painted-props-native-imported/arena-painted_mine_breach-1920x1080.png", "Mine Breach — painted environment"),
        ("painted-props-native-imported/environment-prop-family-1920x1080.png", "Sixteen editable environment props"),
        ("live-tooltip-native-entered/live-tooltip-death-1920x1080.png", "Native stationary-pointer tooltip after death"),
        ("live-control-2026-11-05/forest-victory.png", "Actual desktop play — Forest victory, round 2"),
        ("live-control-2026-11-05/mine-tooltip-fixed.png", "Actual desktop play — updated HP after aimed shot"),
        ("live-control-2026-11-05/mine-victory.png", "Actual desktop play — Mine victory"),
    ]
    figures = []
    for relative, caption in entries:
        source = RUNS / relative
        if not source.is_file():
            continue
        shutil.copy2(source, OUT / source.name)
        figures.append(f'<figure><a href="{source.name}"><img src="{source.name}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>')
    motion = RUNS / "tactical-motion-clip-final/motion-1280x720"
    data = json.loads((motion / "frames.json").read_text(encoding="utf-8"))
    target = OUT / "motion"
    target.mkdir(exist_ok=True)
    shutil.copy2(motion / "frames.json", target / "frames.json")
    for frame in data["frames"]:
        shutil.copy2(motion / frame["file"], target / frame["file"])
    for run, name in [
        ("painted-props-native-imported", "environment-native.json"),
        ("live-tooltip-native-entered", "tooltip-native.json"),
        ("tactical-motion-clip-final", "motion-native.json"),
        ("tactical-environment-los-final", "terrain-native.json"),
    ]:
        shutil.copy2(RUNS / run / "native-review.json", OUT / name)
    source_report = RUNS / "tactical-polish-final/report.json"
    if source_report.is_file():
        shutil.copy2(source_report, OUT / "source-verification.json")
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><title>Tactical polish review</title>
<style>body{background:#171613;color:#e4d8c0;font:18px Georgia,serif;margin:30px auto;max-width:1500px;padding:0 22px}h1,h2{color:#c9ad74}a{color:#d8be88}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(430px,1fr));gap:24px}figure{margin:0}img{max-width:100%;border:1px solid #796645}figcaption{margin:10px 0 24px}button,input{font:inherit}button{background:#302c24;color:#e4d8c0;border:1px solid #8a734c;padding:8px 20px}#motion{display:block;width:1280px;max-width:100%}#seek{width:70%}</style>
<h1>Tactical polish — native game evidence</h1>
<p>Painted props, 18% faster translation, distance-driven foot phase and live target tooltips.
Character artwork, SE/SW facing and combat rules are preserved. Agent review; user acceptance remains pending.</p>
<p><a href="../../../qa/2026-11-05-ordinary-skirmishes.md">Desktop play report</a> ·
<a href="../../../qa/2026-11-05-painted-environment.md">Environment report</a> ·
<a href="environment-native.json">Environment native receipt</a> ·
<a href="tooltip-native.json">Tooltip receipt</a> · <a href="motion-native.json">Motion receipt</a> ·
<a href="terrain-native.json">Corrected terrain receipt</a></p>
<h2>Real-time native movement sequence</h2>
<p>Unmodified GPU frames from an ordinary four-cell move. Playback follows recorded milliseconds;
the recording is sampled, not a smooth desktop video. Pause and scrub to inspect the planted end pose.</p>
<img id="motion" alt="Native game movement sequence"><p><button id="play">Play</button>
<input id="seek" type="range" min="0" max="1000" value="0"><output id="time"></output></p>
<h2>Full-resolution captures</h2><main>FIGURES</main>
<script>const frames=FRAMES;const pictures=frames.map(f=>{const image=new Image();image.src='motion/'+f.file;return image});
const view=document.querySelector('#motion'),seek=document.querySelector('#seek'),button=document.querySelector('#play'),clock=document.querySelector('#time');
const first=frames[0].ms,last=frames.at(-1).ms,duration=last-first;let running=false,start=0,elapsed=0;
function show(t){elapsed=Math.max(0,Math.min(t,duration));let i=0;while(i+1<frames.length&&frames[i+1].ms-first<=elapsed)i++;view.src=pictures[i].src;seek.value=elapsed/duration*1000;clock.textContent=(elapsed/1000).toFixed(2)+' s · '+frames[i].phase;}
function tick(now){if(!running)return;show(now-start);if(elapsed>=duration){running=false;button.textContent='Replay';return}requestAnimationFrame(tick)}
button.onclick=()=>{running=!running;if(running){if(elapsed>=duration)elapsed=0;start=performance.now()-elapsed;button.textContent='Pause';requestAnimationFrame(tick)}else button.textContent='Play'};
seek.oninput=()=>{running=false;button.textContent='Play';show(Number(seek.value)/1000*duration)};show(0);</script></html>'''
    page = page.replace("FIGURES", "\n".join(figures)).replace("FRAMES", json.dumps(data["frames"]))
    (OUT / "index.html").write_text(page, encoding="utf-8")
    print(f"TACTICAL_REVIEW {len(figures)} captures / {len(data['frames'])} timed native frames: {OUT}")


if __name__ == "__main__":
    main()

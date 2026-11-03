"""Validate original source deliveries, complete sprite coverage and design provenance."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parents[2]


def inspect_roster(ids=None):
    data=json.loads((ROOT/"resources/data/presentation/original_roster.json").read_text())
    references=json.loads((ROOT/"assets_src/characters/roster/references.json").read_text())
    profiles={p["id"]:p for p in data["characters"]}
    assert len(profiles)==len(data["characters"])==27,"Complete unique roster"
    assert set(data["aliases"].values())<=profiles.keys(),"Alias target"
    assert len(set(data["camera"]["yaw"].values()))==8,"Eight actual cameras"
    files=[];models=[]
    def record(path):
        content=path.read_bytes()
        row={"path":path.relative_to(ROOT).as_posix(),"bytes":len(content),"sha256":hashlib.sha256(content).hexdigest()}
        files.append(row)
        return row
    for relative in ["assets_src/characters/roster/references.json","assets_src/characters/roster/material-atlas.png",
                     "assets_src/characters/roster/MATERIAL-PROMPT.txt","assets_src/characters/roster/provenance.json",
                     "resources/data/presentation/original_roster.json","resources/schemas/original_roster.schema.json",
                     "tools/blender/build_roster.py","tools/blender/roster_geometry.py","tools/blender/roster_creatures.py",
                     "tools/blender/verify_roster.py","tools/qa/normalize_roster.py",
                     "tools/aseprite/roster.lua","tools/aseprite/roster_timing.lua"]:record(ROOT/relative)
    for ident in ids or profiles:
        profile=profiles[ident]
        source=ROOT/"assets_src/characters/roster"/ident
        runtime=ROOT/"assets/combat/characters/original"/ident
        assert not (source/".rendering").exists(),ident+" render still active or failed"
        meta=json.loads((source/"model.json").read_text())
        assert meta["id"]==ident and not meta["preview_only"],ident+" incomplete render"
        assert meta["uv"] and meta["weighted"] and 0<meta["triangles"]<22000,ident+" geometry"
        assert meta["frame_counts"]==data["frame_counts"],ident+" timing"
        assert meta["camera_elevation"]==18 and meta["pixels_per_metre"]==100,ident+" camera"
        margin=[128,64] if profile["weapon"]=="spear" else [0,0]
        assert meta["canvas_size"]==[a+b for a,b in zip(data["camera"]["size"],margin)]
        assert meta["pivot"]==[a+b//2 for a,b in zip(data["camera"]["pivot"],margin)]
        ref=next(r for r in references if r["id"]==ident)
        assert record(ROOT/"assets_src/characters/roster/references"/(ident+".png"))["sha256"]==ref["sha256"],ident+" reference changed"
        for path in [source/(ident+".blend"),source/(ident+".fbx"),source/"textures"/(ident+"_albedo.png"),source/"model.json"]:record(path)
        report=json.loads((source/"sprite-report.json").read_text())
        record(source/"sprite-report.json")
        assert report["frame_count"]==256 and not report["clipped"],ident+" normalization/clipping"
        assert len(report["frames"])==256
        assert all(r["bounds"][0]>1 and r["bounds"][1]>1 and r["bounds"][2]<meta["canvas_size"][0]-2 and r["bounds"][3]<meta["canvas_size"][1]-2 for r in report["frames"]),ident+" margins"
        expected=set();views=set()
        for action,count in data["frame_counts"].items():
            for direction in data["camera"]["yaw"]:
                motion=set()
                for frame in range(count):
                    path=runtime/action/f"{ident}_{direction}_{action}_{frame:03}.png"
                    expected.add(path)
                    row=record(path);motion.add(row["sha256"])
                    with path.open("rb") as handle:header=handle.read(24)
                    assert header[:8]==b"\x89PNG\r\n\x1a\n" and list(struct.unpack(">II",header[16:24]))==meta["canvas_size"],str(path)
                    if action=="pose" and frame==0:views.add(row["sha256"])
                assert len(motion)>1,(ident,action,direction,"static animation")
                record(ROOT/"assets_src/aseprite/combat/characters"/ident/f"{action}_{direction}.aseprite")
        assert len(views)==8,ident+" mirrored/duplicate views"
        assert set(runtime.rglob("*.png"))==expected|{runtime/"portrait.png"},ident+" unexpected frame files"
        record(runtime/"portrait.png");record(ROOT/"assets_src/aseprite/combat/characters"/ident/"portrait.aseprite")
        models.append({"id":ident,"kind":profile["kind"],"frames":256,"editable_sources":41,"triangles":meta["triangles"],"bones":meta["bones"],"status":"PASS"})
    def walk(value):
        if isinstance(value,dict):
            visual=value.get("visual",{})
            if isinstance(visual,dict) and "character" in visual:assert visual["character"] in profiles or visual["character"] in data["aliases"],visual
            for child in value.values():walk(child)
        elif isinstance(value,list):
            for child in value:walk(child)
    for path in (ROOT/"resources/data").rglob("*.json"):walk(json.loads(path.read_text(encoding="utf-8")))
    if ids is None:
        fbx_path=ROOT/"assets_src/characters/roster/fbx-check.json"
        fbx=json.loads(fbx_path.read_text())
        assert fbx["status"]=="PASS" and len(fbx["models"])==27
        proofs={row["id"]:row for row in fbx["models"]}
        assert set(proofs)==set(profiles)
        for model in models:
            ident=model["id"];proof=proofs[ident]
            assert proof["status"]=="PASS" and proof["triangles"]==model["triangles"] and proof["bones"]==model["bones"]
            assert proof["uv"] and proof["weighted"] and proof["texture"] and all(value>0 for value in proof["motion"].values())
            assert len(proof["motion"])==5
            assert proof["fbx_sha256"]==hashlib.sha256((ROOT/"assets_src/characters/roster"/ident/(ident+".fbx")).read_bytes()).hexdigest()
            if profiles[ident]["weapon"]=="spear":assert len(proof["weapon_min_z"])==5 and min(proof["weapon_min_z"].values())>=-.025
        record(fbx_path)
        timing_path=ROOT/"assets_src/characters/roster/timing-check.json"
        timing=json.loads(timing_path.read_text())
        assert timing["status"]=="PASS" and len(timing["clips"])==1080
        actual={(row["id"],row["action"],row["direction"]):row for row in timing["clips"]}
        assert len(actual)==1080
        for ident in profiles:
            for action,count in data["frame_counts"].items():
                for direction in data["camera"]["yaw"]:
                    clip=actual[ident,action,direction]
                    assert clip["frames"]==count and abs(clip["seconds"]-data["frame_seconds"][action])<.0005
        record(timing_path)
    return {"schema":"sdd.original-roster-delivery-v1","status":"PASS","models":models,"files":sorted(files,key=lambda r:r["path"])}


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids")
    parser.add_argument("--write",action="store_true")
    args=parser.parse_args()
    report=inspect_roster(args.ids.split(",") if args.ids else None)
    target=ROOT/"artifacts/roster"/("human-check.json" if args.ids else "complete-check.json")
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(report,indent=2)+"\n")
    if args.write:
        assert not args.ids,"Only a complete delivery may replace the source manifest"
        (ROOT/"assets_src/characters/roster/manifest.json").write_text(json.dumps(report,indent=2)+"\n")
    print(f"Original roster PASS: {len(report['models'])} models, {sum(m['frames'] for m in report['models'])} frames, {len(report['files'])} hashed files")

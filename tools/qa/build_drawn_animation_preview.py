"""Package actual Aseprite-exported action atlases in an offline animation player."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets_src/characters/drawn_animation/2026-11-03"
VIEW_NAMES = {'south_east':'Przód 3/4','south':'Przód','south_west':'Przód z lewej',
              'west':'Lewy profil','north_west':'Tył z lewej','north':'Tył',
              'north_east':'Tył z prawej','east':'Prawy profil'}


def validate_view(path, view_id):
    p = json.loads(path.read_text(encoding='utf-8'))
    relative = path.parent.relative_to(BASE).as_posix()+'/'
    total = 0
    w,h = p['canvas']
    for clip in p['clips']:
        image = path.parent/clip['atlas']
        header = image.read_bytes()[:33]
        assert header[:8] == b'\x89PNG\r\n\x1a\n', image
        assert struct.unpack('>II',header[16:24]) == (w*clip['frames'],h), image
        assert len(clip['durations']) == clip['frames']
        assert all(t>0 for t in clip['durations'])
        for n in range(clip['frames']):
            assert (path.parent/'frames'/clip['id']/f'{n:03}.png').is_file()
            total+=1
    report=json.loads((path.parent/'export_report.json').read_text(encoding='utf-8'))
    assert not report['clipping'],path
    assert report['saved_source_roundtrip']=='PASS',path
    label=VIEW_NAMES[view_id]+(' · odbicie' if p.get('mirror_of') else '')
    return dict(id=view_id,label=label,asset_base=relative,clips=p['clips'],
                direction_note=p.get('direction_note','')),total


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--knight-only", action="store_true")
    args = parser.parse_args()
    profiles = []
    total = 0
    for path in sorted(BASE.glob("*/manifest.json")):
        p = json.loads(path.read_text(encoding='utf-8'))
        if args.knight_only and p["id"] != "knight":
            continue
        main_view,count=validate_view(path,'south_east')
        p['views']=[main_view]
        total+=count
        for view in VIEW_NAMES:
            view_path=path.parent/'directions'/view/'manifest.json'
            if view_path.is_file():
                entry,count=validate_view(view_path,view)
                p['views'].append(entry)
                total+=count
        p['exported_views']=[v['id'] for v in p['views']]
        profiles.append(p)
    assert profiles, "No complete profiles exported"
    order=['knight','warrior','archer_1','rogue_1','axe_bandit','bandit_spearman']
    profiles.sort(key=lambda p:order.index(p['id']))
    data = {"profiles": profiles,
            "ground_base": "../../../../assets/combat/environment/floors/",
            "shadow": "../../../../assets/combat/environment/contact_shadow.png"}
    template = (ROOT/"tools/qa/drawn_animation_player.html").read_text(encoding="utf-8")
    html = template.replace("__DRAWN_ANIMATION_DATA__", json.dumps(data, ensure_ascii=False))
    (BASE/"preview.html").write_text(html, encoding="utf-8")
    (BASE/"player_data.json").write_text(json.dumps(data, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
    identities = json.loads((BASE/"previous_sources.json").read_text())
    for name, sha in identities.items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == sha, name
    report = {"status": "ASSET_PACKAGE_PASS", "profiles": len(profiles), "frames": total,
              "clips": sum(len(v['clips']) for p in profiles for v in p['views']), "previous_sources_preserved": len(identities),
              "views": {p['id']:p['exported_views'] for p in profiles},
              "user_motion_acceptance": {"knight_south_east_12_clips":"USER_ACCEPTED_2026-11-03",
                                         "other_roles_and_directional_runtime":"positive overall user feedback; physical scenarios remain open",
                                         "idle_shield_bow_corrections":"USER_ACCEPTED_PREVIEW_2026-11-03"},
              "continuous_motion_reviewed": False,
              "external_network_requests": 0, "desktop_input_used": False}
    (BASE/"preview_verification.json").write_text(json.dumps(report, indent=2)+"\n")
    print("DRAWN_ANIMATION_PREVIEW_PASS", len(profiles), "profiles", total, "frames")


if __name__ == "__main__":
    main()

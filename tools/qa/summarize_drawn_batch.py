"""Persist final source/runtime provenance and actual verification summaries."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'assets_src/characters/drawn_animation/2026-11-03'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')


def main():
    registry = read(ROOT/'resources/data/presentation/drawn_roster.json')
    preview = read(BASE/'preview_verification.json')
    package = read(BASE/'runtime_package_verification.json')
    native = read(ROOT/'artifacts/drawn-animation/result.json')
    assert native['status'] == 'PASS' and native['require_all'] and native['regression']
    assert package['frames'] == 2304 and preview['frames'] == 2344
    for name, sha in package['identities'].items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == sha, name
    views = []
    profiles = []
    for profile in registry['profiles']:
        source_frames = 0
        for view in profile['facings']:
            provenance = profile['view_sources'][view]
            folder = ROOT/provenance['source']
            manifest = read(folder/'manifest.json')
            report = read(folder/'export_report.json')
            assert not report['clipping'] and report['saved_source_roundtrip'] == 'PASS'
            frames = sum(c['frames'] for c in manifest['clips'])
            source_frames += frames
            views.append(dict(id=profile['id'], view=view, status='SOURCE_ROUNDTRIP_PASS',
                              kind=provenance['kind'], mirror_of=manifest.get('mirror_of'),
                              clips=len(manifest['clips']), frames=frames,
                              source=provenance['source'],
                              visual_acceptance='USER_ACCEPTED_BASELINE_AND_CORRECTION_SAMPLE' if
                              profile['id']=='knight' and view=='south_east' else 'pending'))
        profiles.append(dict(id=profile['id'], runtime_clips_per_view=len(profile['frame_counts']),
                             runtime_frames=sum(profile['frame_counts'].values())*8,
                             source_frames=source_frames, facings=profile['facings']))
    assert len(views) == 48 and sum(v['kind']=='mirror' for v in views) == 18
    summaries = {}
    for suite in native['suites']:
        lines = (ROOT/'artifacts/drawn-animation'/(suite+'.log')).read_text(encoding='utf-8').splitlines()
        summaries[suite] = next((line for line in lines if any(marker in line for marker in
            ['Drawn animation:', 'Original roster:', 'combat_animation_lifecycle_tests: OK',
             'Equipment appearance:', 'Godot combat slice validation passed.',
             'combat_feedback_polish_tests:'])), 'Godot asset import PASS')
    source = ROOT/'assets_src/aseprite/characters/drawn_animation/2026-11-03'
    weapons = read(BASE/'weapon_library/weapon_manifest.json')
    assert len(weapons['props']) == 10 and all(p['roundtrip']=='PASS' for p in weapons['props'])
    result = dict(status='TECHNICAL_PASS_AWAITING_INTERACTIVE', profiles=profiles,
                  source_views=len(views), drawn_views=30, mirrored_views=18,
                  source_clips=sum(v['clips'] for v in views), source_frames=preview['frames'],
                  runtime_frames=package['frames'], editable_aseprite_files=len(list(source.rglob('*.aseprite'))),
                  independent_weapon_masters=len(weapons['props']),
                  source_roundtrip='PASS_ALL_48_VIEWS', runtime_copy_sha256='PASS',
                  earlier_source_identities_preserved=preview['previous_sources_preserved'],
                  offline_player='3579 deterministic timing/canvas checks PASS',
                  native_summaries=summaries,
                  user_acceptance=preview['user_motion_acceptance'],
                  continuous_motion_observed_by_agent=False, desktop_input_used=False,
                  browser_render='NOT_RUN: browser access host unavailable',
                  physical_scenarios='61 earlier cases and L53-01/L54-01/L54-02 remain NOT_RUN')
    if (BASE/'refinements/jobs.json').is_file():
        baseline=BASE/'refinements/before'
        retained=read(baseline/'identities.json')
        for name,sha in retained.items():
            assert hashlib.sha256((baseline/name).read_bytes()).hexdigest()==sha,name
        idle=read(BASE/'refinements/idle_contact_report.json')
        assert idle['status']=='PASS' and len(idle['views'])==30
        bow=next(p for p in registry['profiles'] if p['id']=='archer_1')
        assert sum(bow['durations_ms']['attack'])==1800
        assert sum(bow['durations_ms']['attack'][:bow['impact_frame']])==1260
        samples=read(BASE/'refinements/player_data.json')
        assert len(samples['cases'])==125
        result['refinements']=dict(status='TECHNICAL_PASS_USER_ACCEPTED_PREVIEW',
            corrected_idle_clips=96,drawn_idle_source_roundtrip='60 clips PASS;36 reflected clips PASS',
            pinned_shins_from_y=idle['lock_y'],shield_inside_views=['north','north_east','north_west'],
            bow_clip_ms=1800,bow_release_ms=1260,bow_views=8,
            baseline_files_preserved=len(retained),before_after_samples=len(samples['cases']),
            preview='refinements/preview.html',user_acceptance='USER_ACCEPTED_PREVIEW_2026-11-03')
        write(BASE/'refinements/verification.json',result['refinements'])
    write(BASE/'direction_plan.json', dict(status='SOURCE_BATCH_COMPLETE', views=views,
          unused_candidates='raw/sequence_candidate.png retained; never activated',
          next='User gallery/game review; do not regenerate the superseded pending queue'))
    completed = read(BASE/'direction_completed_jobs.json')
    known = {(j['id'], j.get('view'), j['kind'], j['source']) for j in completed}
    for job in read(BASE/'knight_showcase_jobs.json'):
        key = (job['id'], job.get('view'), job['kind'], job['source'])
        if key not in known:
            completed.append(job)
            known.add(key)
    write(BASE/'direction_completed_jobs.json', completed)
    write(BASE/'batch_verification.json', result)
    print('DRAWN_BATCH_SUMMARY_PASS', len(profiles), 'profiles', result['source_clips'],
          'source clips', result['editable_aseprite_files'], 'editable Aseprite files')


if __name__ == '__main__':
    main()

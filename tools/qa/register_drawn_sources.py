"""Copy built-in imagegen outputs into their recorded project source profiles."""
import argparse
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'assets_src/characters/drawn_animation/2026-11-03'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('jobs', type=Path)
    args = parser.parse_args()
    jobs=json.loads(args.jobs.read_text(encoding='utf-8'))
    copied=0
    for job in jobs:
        profile = BASE/job['id']
        if job.get('view'):
            profile = profile/'directions'/job['view']
        raw = profile/'raw'
        raw.mkdir(parents=True, exist_ok=True)
        destination = raw/(job['kind']+'.png')
        source = Path(job['source'])
        if destination.exists():
            assert destination.read_bytes() == source.read_bytes(), destination
        else:
            shutil.copy2(source, destination)
            copied+=1
        prompts_path = profile/'prompts.json'
        prompts = json.loads(prompts_path.read_text(encoding='utf-8')) if prompts_path.exists() else {}
        prompts[job['kind']] = {'prompt': job['prompt'], 'generator':'built-in imagegen',
            'source':str(source), 'output':str(destination.relative_to(ROOT)),
            'review':job.get('review','see source/export reports')}
        prompts_path.write_text(json.dumps(prompts, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
    print('REGISTERED_DRAWN_SOURCES',len(jobs),'records',copied,'new files')

if __name__ == '__main__':
    main()

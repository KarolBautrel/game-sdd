"""Fetch pinned official MPFB and CC0 packs into the owned, isolated art tools."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
INSTALL = Path.home() / '.codex/tools/character-art/mpfb-2.0.18'
DOWNLOADS = INSTALL / 'downloads'
PACKS = ('makehuman_system_assets', 'skins02', 'system_eye_materials01')
PINNED_SHA256 = {
    'mpfb-2.0.18': 'ada7c4ff11e79cf6ed9b441bccabc52c9359f2848b988f66e89c14c30b21fed7',
    'makehuman_system_assets': 'b542127a8e25547c7c29c19f2d1d2adb9a664c80396ecd694095dbc8028a0107',
    'skins02': '1613f1ef3afca53094511d26620ed7cf1d2dedc29ed3d384d60bdebe250698ae',
    'system_eye_materials01': 'acad4636c08ff96ac8a27775cfa071052c8cba9b21e0029b649bdd6ec7aeb332',
}


def fetch(name, urls):
    target = DOWNLOADS / (name + '.zip')
    origin = urls[0]
    if not target.exists():
        for url in urls:
            try:
                subprocess.run(['curl.exe', '--location', '--fail', '--silent', '--show-error',
                                '--connect-timeout', '15', '--max-time', '300',
                                '--output', str(target.with_suffix('.part')), url], check=True)
                with zipfile.ZipFile(target.with_suffix('.part')) as archive:
                    assert archive.testzip() is None, name
                target.with_suffix('.part').replace(target)
                origin = url
                target.with_suffix('.origin.txt').write_text(origin)
                break
            except Exception as exc:
                print(f'DOWNLOAD_RETRY {name} {type(exc).__name__}: {exc}', flush=True)
        else:
            raise RuntimeError(f'All official mirrors failed: {name}')
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None, name
    if target.with_suffix('.origin.txt').exists():
        origin = target.with_suffix('.origin.txt').read_text()
    report = dict(name=name, origin=origin, mirrors=urls, bytes=target.stat().st_size,
                  sha256=hashlib.sha256(target.read_bytes()).hexdigest())
    assert report['sha256']==PINNED_SHA256[name], f'Pinned archive changed: {name}'
    print('DOWNLOAD_READY ' + json.dumps(report), flush=True)
    return report


def extract_safe(archive_path, target):
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path) as archive:
        for entry in archive.infolist():
            assert (target / entry.filename).resolve().is_relative_to(target.resolve()), entry.filename
        archive.extractall(target)


def main():
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    jobs = [('mpfb-2.0.18', ['https://codeload.github.com/makehumancommunity/mpfb2/zip/refs/tags/v2.0.18'])]
    jobs += [(p, [f'https://{host}.makehumancommunity.org/asset_packs/{p}/{p}_cc0.zip'
                  for host in ('files', 'files2')]) for p in PACKS]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        receipts = list(pool.map(lambda item: fetch(*item), jobs))
    extract_safe(DOWNLOADS / 'mpfb-2.0.18.zip', INSTALL / 'source')
    source = next((INSTALL / 'source').glob('*/src/mpfb'))
    addon = INSTALL / 'addons/mpfb'
    shutil.copytree(source, addon, dirs_exist_ok=True)
    for pack in PACKS:
        extract_safe(DOWNLOADS / (pack + '.zip'), INSTALL / 'assets')
    receipt_path = ROOT / 'tools/assets/mpfb_dependencies.json'
    compatibility = 'NOT_TESTED_YET'
    if receipt_path.exists():
        previous = json.loads(receipt_path.read_text())
        if {p['name']:p['sha256'] for p in previous.get('downloads', [])} == {p['name']:p['sha256'] for p in receipts}:
            compatibility = previous.get('compatibility', compatibility)
    receipt = dict(schema='sdd.mpfb-dependencies-v1', addon_version='2.0.18',
                   source_tag='v2.0.18', install=str(INSTALL), addon=str(addon),
                   packs_license='CC0; retain individual asset license files',
                   addon_license='GPL-3.0-or-later; see downloaded LICENSE.md',
                   downloads=receipts, compatibility=compatibility)
    receipt_path.write_text(json.dumps(receipt, indent=2) + '\n')
    print('MPFB_DOWNLOAD_AND_ISOLATED_INSTALL_PASS', flush=True)


if __name__ == '__main__':
    main()

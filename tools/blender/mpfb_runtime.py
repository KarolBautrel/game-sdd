"""Owned MPFB extension registration; no saved/global Blender preferences."""
from pathlib import Path
import importlib
import os
import sys

INSTALL = Path.home() / '.codex/tools/character-art/mpfb-2.0.18'
ASSETS = INSTALL / 'assets'
MODULE = 'bl_ext.sdd_mpfb.mpfb'


def enable_mpfb():
    import bpy
    import addon_utils
    os.environ['BLENDER_USER_EXTENSIONS'] = str(INSTALL / 'extension-user')
    repo = next((r for r in bpy.context.preferences.extensions.repos if r.module == 'sdd_mpfb'), None)
    if repo is None:
        repo = bpy.context.preferences.extensions.repos.new(
            name='SDD isolated MPFB', module='sdd_mpfb', custom_directory=str(INSTALL / 'addons'))
    addon_utils.enable(MODULE, default_set=True, persistent=False)
    assert MODULE in bpy.context.preferences.addons, 'MPFB failed to register'
    from_module = lambda path: importlib.import_module(MODULE + '.' + path)
    human = from_module('services.humanservice').HumanService
    target = from_module('services.targetservice').TargetService
    location = from_module('services.locationservice').LocationService
    user_dir = Path(location.get_user_data()).resolve()
    assert user_dir.is_relative_to(INSTALL.resolve()), f'Unexpected addon user directory: {user_dir}'
    return human, target, location

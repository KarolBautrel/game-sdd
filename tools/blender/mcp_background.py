"""Main-thread command pump for the pinned upstream addon, without a GUI.

Run only in an owned, factory-startup background Blender. Upstream start() refuses
background mode because bpy timers do not run during a blocking Python job; this
adapter explicitly drains the same queue on Blender's main thread instead.
Viewport/UI tools require interactive Blender; rendering through bpy still works.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import socket
import sys
import threading
import time

import bpy

parser = argparse.ArgumentParser()
parser.add_argument("--tool-root", type=Path, required=True)
parser.add_argument("--session", type=Path, required=True)
parser.add_argument("--port", type=int, required=True)
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
assert bpy.app.background, "This adapter must never attach to a user's GUI"
os.environ["DISABLE_TELEMETRY"] = "true"
spec = importlib.util.spec_from_file_location(
    "blendermcp", args.tool_root / "mcp-for-blender/addon.py")
addon = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = addon
spec.loader.exec_module(addon)
addon.register()
for module in ("rigify", "retarget"):
    bpy.ops.preferences.addon_enable(module=module)
    assert module in bpy.context.preferences.addons
for name in ("polyhaven", "hyper3d", "sketchfab", "polypizza", "hunyuan3d", "tripo", "meshy"):
    attr = "blendermcp_use_" + name
    if hasattr(bpy.context.scene, attr):
        setattr(bpy.context.scene, attr, False)

server = addon.BlenderMCPServer(host="127.0.0.1", port=args.port)
try:
    server.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.socket.bind((server.host, server.port))
    server.socket.listen(5)
    server.running = True
    server.server_thread = threading.Thread(target=server._server_loop, daemon=True)
    server.server_thread.start()
    (args.session / "ready.json").write_text(json.dumps({
        "pid": os.getpid(), "port": args.port, "blender": bpy.app.version_string,
        "mode": "background-main-thread-pump", "viewport_available": False,
    }), encoding="utf-8")
    while not (args.session / "stop").exists():
        server._drain_command_queue()
        time.sleep(0.02)
finally:
    server.stop()

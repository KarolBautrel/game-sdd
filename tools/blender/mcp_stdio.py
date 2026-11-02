"""Own one background Blender for the lifetime of an upstream stdio MCP server."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tool-root", type=Path,
                        default=Path.home() / ".codex/tools/character-art")
    args = parser.parse_args()
    tools = args.tool_root.resolve()
    install = json.loads((tools / "blender-install.json").read_text())
    # Reserve an available loopback port; fail rather than connect to another
    # application's scene. The child owns the actual listener after startup.
    with socket.socket() as reserve:
        reserve.bind(("127.0.0.1", 0))
        port = reserve.getsockname()[1]
    session = ROOT / "artifacts/blender-mcp" / (time.strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
    session.mkdir(parents=True)
    env = {**os.environ, "DISABLE_TELEMETRY": "true",
           "BLENDER_HOST": "127.0.0.1", "BLENDER_PORT": str(port),
           "BLENDER_USER_CONFIG": str(tools / "profile/config"),
           "BLENDER_USER_SCRIPTS": str(tools / "profile/scripts")}
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    with (session / "blender.log").open("w", encoding="utf-8") as log:
        blender = subprocess.Popen([
            install["path"], "--background", "--factory-startup", "--python-exit-code", "1",
            "--python", str(ROOT / "tools/blender/mcp_background.py"), "--",
            "--tool-root", str(tools), "--session", str(session), "--port", str(port),
        ], stdout=log, stderr=subprocess.STDOUT, env=env, creationflags=flags)
        try:
            deadline = time.monotonic() + 40
            while not (session / "ready.json").exists():
                if blender.poll() is not None:
                    raise RuntimeError(f"Blender exited {blender.returncode}; see {session / 'blender.log'}")
                if time.monotonic() > deadline:
                    raise TimeoutError(f"Blender startup timed out; see {session}")
                time.sleep(0.1)
            return subprocess.call([
                str(tools / "mcp-for-blender/.venv/Scripts/python.exe"),
                "-m", "blender_mcp.server",
            ], env=env)
        finally:
            (session / "stop").touch()
            try:
                blender.wait(timeout=5)
            except subprocess.TimeoutExpired:
                blender.kill()  # Only the process this wrapper owns.
                blender.wait()


if __name__ == "__main__":
    raise SystemExit(main())

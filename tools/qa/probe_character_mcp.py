"""Sequential MCP protocol smoke; edits only an owned background Blender scene."""
from __future__ import annotations

import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import threading
import time

ROOT = Path(__file__).resolve().parents[2]
TOOLS = Path.home() / ".codex/tools/character-art"
OUT = ROOT / "artifacts/character-art-setup"


def probe(command, calls, name):
    OUT.mkdir(parents=True, exist_ok=True)
    env = {**os.environ, "DISABLE_TELEMETRY": "true"}
    # Never use a real account/key for connector discovery.
    env.pop("MESHY_API_KEY", None)
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    with (OUT / (name + "-stderr.log")).open("w", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=ROOT, stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=log, text=True,
                                   encoding="utf-8", env=env, creationflags=flags)
        messages = queue.Queue()

        def read():
            for line in process.stdout:
                try:
                    messages.put(json.loads(line))
                except ValueError:
                    pass
            messages.put({"eof": True})

        threading.Thread(target=read, daemon=True).start()

        def send(message):
            process.stdin.write(json.dumps(message) + "\n")
            process.stdin.flush()

        def request(ident, method, params):
            send({"jsonrpc": "2.0", "id": ident, "method": method, "params": params})
            deadline = time.monotonic() + 65
            while time.monotonic() < deadline:
                response = messages.get(timeout=max(0.1, deadline - time.monotonic()))
                if response.get("eof"):
                    raise RuntimeError(f"{name} exited; see {log.name}")
                if response.get("id") == ident:
                    assert "error" not in response, response
                    assert not response.get("result", {}).get("isError"), response
                    return response["result"]
            raise TimeoutError(method)

        try:
            initialized = request(1, "initialize", {
                "protocolVersion": "2025-03-26", "capabilities": {},
                "clientInfo": {"name": "sdd-character-tooling", "version": "1.0"},
            })
            send({"jsonrpc": "2.0", "method": "notifications/initialized"})
            listing = request(2, "tools/list", {})
            results = []
            for ident, (tool, arguments) in enumerate(calls, start=3):
                results.append(request(ident, "tools/call", {"name": tool, "arguments": arguments}))
            report = {"status": "PASS", "initialize": initialized,
                      "tool_count": len(listing["tools"]),
                      "tool_names": sorted(t["name"] for t in listing["tools"]),
                      "results": results}
            (OUT / (name + ".json")).write_text(json.dumps(report, indent=2), encoding="utf-8")
            return report
        finally:
            process.stdin.close()
            try:
                process.wait(timeout=12)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
                raise RuntimeError(f"{name} did not stop cleanly")


if __name__ == "__main__":
    blend_path = str(OUT / "mcp-diagnostic.blend")
    code = ("import bpy\n"
            "bpy.ops.mesh.primitive_cube_add(size=0.25)\n"
            "bpy.context.object.name='SDD_MCP_PROOF'\n"
            "assert 'rigify' in bpy.context.preferences.addons\n"
            "assert 'retarget' in bpy.context.preferences.addons\n"
            f"bpy.ops.wm.save_as_mainfile(filepath={blend_path!r})\n"
            "assert 'SDD_MCP_PROOF' in bpy.data.objects\n"
            "print('SDD_MCP_EDIT_SAVE_PASS')")
    blender = probe([sys.executable, str(ROOT / "tools/blender/mcp_stdio.py")], [
        ("execute_blender_code", {"code": code, "user_prompt": "Local diagnostic only"}),
        ("get_scene_info", {}),
    ], "blender-mcp")
    assert "SDD_MCP_EDIT_SAVE_PASS" in json.dumps(blender["results"][0])
    assert "SDD_MCP_PROOF" in json.dumps(blender["results"][1])
    assert Path(blend_path).is_file()
    meshy = probe(["node", str(TOOLS / "meshy-mcp/node_modules/@meshy-ai/meshy-mcp-server/dist/index.js")], [], "meshy-mcp")
    assert {"meshy_image_to_3d", "meshy_rig", "meshy_animate"} <= set(meshy["tool_names"])
    print(json.dumps({"status": "PASS", "blender_tools": blender["tool_count"],
                      "meshy_tools": meshy["tool_count"], "paid_calls": 0}))

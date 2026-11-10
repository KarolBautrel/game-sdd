# Stage96: bounded strategist evidence

Owners: world019/slice020 and presentation046/slice046. Final automated receipts
are referenced from docs/qa/2026-11-09-strategist-adapter.md. This directory is
portable QA evidence, not a new gameplay-rule owner.

The transport used here produces authored local examples. These are **not**
captured external-model responses and do not measure model intelligence, latency,
real token invoices or balance. No provider/key/network call is configured.
The native mode is explicitly labelled Recorded examples (offline).

The normal managed trace uses31ordinary battle commands and real packing,
checkpoint/reload, loot, mine restoration and report payment on campaignv4. It
does not claim a physical victory or visible animation/readability approval.
All scene checks are headless; the user's desktop remains withheld.

`contingency_probe.gd` and its9check JSON receipt supplement the normal full
runner. They reconstruct the exact pre-reply checkpoint from the committed
reference and submit alternative legal replies. A true food-deficit predicate
attempts its observed candidate; a false war predicate attempts none. Both use
the same future boundary and authoritative accounting. This supplementary probe
is separate from the registered full-run check count.

## Reproduce

```powershell
.\.venv\Scripts\python.exe tools/strategy/build_strategist_schemas.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/qa/strategist_fixture_export.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/qa/strategist_replay.gd
```

The exporter intentionally rewrites only the named source fixtures. Replay
instantiates no transport and writes only its ignored QA receipt. A checkpoint
plus its recorded command tail is required; a seed or pruned journal alone is
not a promise of replay from campaign start.

For later physical review use `tools/qa/start_game.ps1 -Scene strategy-ai`.
Open Factions, select Recorded examples (offline), then advance time. Initial
classic plans retain their3day commitment: on fresh2087 the first request is
around264ticks and applies288ticks. The next three factions are staggered. Company
and Jobs pause time; reply processing itself does not advance the world.
Use `-Scene strategy` for the independent v3 pilot. No existing save is converted.

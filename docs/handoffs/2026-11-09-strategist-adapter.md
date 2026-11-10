# Bounded strategist adapter, stage96

User: "Dawaj nastepny etap". Implement96 after terrain/company95. Source/headless
ONLY: no desktop takeover, OS input, activation or visible/GPU launch. Local
master583ebc84; preserve earlier85..95 plus96 uncommitted work. No commit/push.

Owners [world019](../specs/world/019_model_strategist.md),
[slice020](../specs/world/slices/020_model_strategist.md),
[presentation046](../specs/presentation/046_strategist_lab.md),
[QA](../qa/2026-11-09-strategist-adapter.md).

Explicit fresh campaignv4 adds a durable strategist block to v3 composition.
The optional classic hooks keep one actual authority/seeded operator order and
company/terrain/dungeon transaction. All old formats keep explicit independent
creation/load; no migration/reset. StrategistWorld reuses the native map/UI with
Classic and Recorded examples (offline) controls and public-only adapter status.
The fixture provider is authored local data, not captured live-model output.

Strict per-faction requests include bounded private-own observations, hashed
finite goal/intent capabilities, generation, deadlines and protocol/policy IDs.
Replies choose known IDs/reasons/observable contingencies and actual citations;
no arbitrary actions/payloads/text effects. Fixed future boundaries revalidate
context/goal; real operators recheck money/readiness/path/consent. Waiting,
malformed/missing/late/stale/timeout/interrupted/budget responses use classic.
Initial classic commitment remains intact; the first fresh2087 request starts
around tick264, applies288, then faction reviews stagger168ticks.

Session transport tickets bind epoch/generation/request; dispatch persists before
work is exposed. Valid reply bytes survive a failed write in runtime cache and
retry without redispatch. Restart does not resend lost sent work. Real-minute
rate, world-day calls/token estimates, bounded journal and permanent watermarks
support pruning, cancellation and duplicate rejection. Checkpoint-plus-recorded
command-tail replay is exact and instantiates no transport; a seed/pruned journal
does not promise replay from campaign start. Schemas, references, fixture exporter,
replay CLI and Python semantics are included. No provider API/key or paid call.

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene strategy-ai
```

Default is Classic. Open Factions -> Recorded examples (offline), then advance
time; it does not wait for a model or rewrite a still-committed plan immediately.
Use the original `-Scene strategy` for v3. Dungeon return respects the owner.

Final-source107/107PASS,0errors/0warnings,104Python tests. Source hash
`b5f340968b43172bbc99c3396264c0862e3b874b8030560bd158f02f7b49e3d0` matches
the verified tree;10/10preexisting save/art hashes unchanged. New suites:
184domain/67session/131managed/54interface checks,31ordinary battle commands.
Supplementary9check contingency proof and standalone replay pass. See QA for
portable receipts. The legacy core `planner_mode` remains its fixed classic
format marker; actual optional selection belongs to v4 `strategist.mode`.

## Next unfinished work

97: matched-campaign comparison and balance. Real LLM comparison additionally
requires choosing provider/model/cost budget and implementing its nonblocking
transport/accounting. This stage intentionally implements protocol/lifecycle with
authored offline examples and injectable dispatch/reply tickets, not a fake live
AI. Do not infer billing authorization or provider selection from this handoff.
Earlier L96-01/L95/L91/L77/user visual/movement acceptance remains open. QA owns
actual full-source receipts/preservation; headless ordinary commands are not a
physical victory. Do not restart expired autonomous queues.

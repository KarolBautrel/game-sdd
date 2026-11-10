# 017 Versioned strategy foundation

Stage93,2026-11-09. Owner: [world016](../016_strategy_foundation.md).
Status: IMPLEMENTED, focused automated PASS; full-source result in
[stage93 QA](../../../qa/2026-11-09-strategy-foundation.md).
Headless-only scope authorized; no playable scene or physical acceptance claimed.

- Load the reference four-faction/six-settlement graph and validate all dynamic
  references, six canonical pairs, headcounts and resource bounds. Reorder every
  registry; equivalent queries/commands retain the same facts. Invalid/fractional/
  nonfinite counts, missing references, disconnected routes and extra fields reject.
  Add a fifth faction/seventh settlement and exercise a budget and bilateral pact
  through the same API, with no new hardcoded actor slots.
- Two plans cannot reserve more stock than is available; release by a foreign
  faction, duplicate release and reused IDs reject atomically. Holdings never
  change just because they are held/released.
- A proposal has only the proposer's signature and no active treaty. Only the
  named recipient can accept the same terms. Acceptance creates one canonical
  bilateral pact; forged/one-sided/duplicate/conflicting state rejects.
- Failure, duplicate/out-of-order command or unsupported war/mode operation
  changes no snapshot/sequence. After more than64commands, old receipt replay
  remains rejected by the saved watermark. Company reputation is independent.
- Dedicated memory and fresh QA-only disk sessions use the same pure executor.
  Save/reload preserves exact company, world, holds, pacts and watermark. Missing,
  corrupt/unsupported or wrong-mode loads preserve files; creation never overwrites.
  Forced write failure rolls back; retry succeeds once.
  Both temporary-write and atomic-rename failures retain prior memory/file bytes;
  a failed pact acceptance grants no signature/treaty. Paths cannot traverse
  directories or escape the dedicated QA filename.
- Legacy loader rejects strategy envelopes/reserved missing paths without
  writing. Dedicated loader rejects legacy/player paths. Existing authored/v1/v2
  saves, canonical restored mine, accepted/paid jobs and terrain remain intact.

Proof locations: world_strategy_tests.gd, strategy_campaign_session_tests.gd,
strategy-world JSON schema/reference validator and Python negative fixtures.
No physical or new gameplay acceptance is inferred. There is no new game scene
to launch at this backend stage; stage94's classic simulation remains next.

Focused proof:252domain checks,93session checks,8Python tests PASS. Required full
verification uses `tools/qa/verify_project.py`; the QA report owns run identity,
logs and final-source fingerprint. Existing live gaps remain unchanged.

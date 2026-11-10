# 015 Delivery, reconnaissance and upkeep transaction audit

Date:2026-11-09. Owners: ../010_living_region.md and ../001_campaign_boundary.md.
Status: focused session/UI PASS; actual play deferred by explicit user instruction.

Use isolated memory fixtures for boundary cases and fresh QA-only files for
atomic save/reload. Do not access player saves or use OS input. Prove:

- Delivery requires acceptance, the actual stationary issuer and at least3owned
  food. Missing offer/unknown id/wrong issuer/stale location/moving/insufficient
  stock and duplicate reporting leave the snapshot unchanged.
- A shared read-only availability query drives command rejection and real card
  status/tooltips. Verify exact reason parity and enablement after each relevant
  stock/location/stage/event change, preserving card identity and query purity.
- Successful delivery spends exactly3food and pays the configured gold/XP /
  relation once; supply caps at100. Failed write publishes no state, stock or
  reward changes and preserves the old file. Retry succeeds; paid reload cannot
  duplicate payment.
- Recon requires acceptance before a real High Pass arrival and report at Black
  Keep. A wrong town, premature report and duplicate visit/report cannot pay.
  Verify Iron March+6, River League-2 and tension+8 with their existing bounds.
- Pending events and active expeditions block strategic contract commands.
- Real service/travel chains on authored and generated Large regions use normal
  course/tick/purchase/accept/report calls, not teleported objective completion.
  Record time, food, wages/tolls, payouts and final state as diagnostic metrics.
- Existing upkeep crosses food32tick and wage96tick boundaries once; camping
  reduces fatigue without moving the company and still pays upkeep. Empty food
  or depleted gold does not lock out legal travel. No balance change is inferred
  from an unattended simulation or headless PASS.

Proof: `scripts/session/living_contract_regression_tests.gd` and the existing
living-world/session/terrain suites. Boundary fixtures and automated service
chains are technical evidence, not physical travel/pace acceptance. Preserve
L77-01's remaining ordinary desktop cases and user review as open.

Focused proof2026-11-09: session151checks and real headless interface157checks
at720p/1080p/1440p PASS. Authored and Large seeds2087/20261107 complete both
delivery and recon via actual course/tick/service commands, including a provision
purchase and tolls. Whole-chain gold reconciles configured payouts minus wages,
actual shop invoices and recorded road payments. Metrics are diagnostic; no
economy values changed. Desktop L91-01/L91-02 remain NOT_RUN.

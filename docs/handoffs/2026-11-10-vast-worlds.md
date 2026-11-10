# Vast world maps, follow-up96c

User prioritizes more map space and explicitly leaves the current save/retest
alone. No reset/overwrite/migration. Source/headless ONLY; no OS input, activation
or visible/GPU launch. Local master583ebc84, preserve85..96c, no commit/push.

Owners [world020](../specs/world/020_vast_regions.md),
[slice021](../specs/world/slices/021_vast_regions.md),
[presentation048](../specs/presentation/048_vast_worlds.md),
[QA](../qa/2026-11-10-vast-worlds.md).

Generatorv3 creates768x432Vast terrain: four times Large area /16times Classic.
Real new terrain detail, biomes, rivers/crossings and safe paths; the accepted
painted assets/shader remain. Gen.world_scale maps1/2/3to1/2/4; shared company/NPC
integration and strategic route weights apply it. Current Large budget stays
.0225/.007; Vast normalized company/caravan budgets halve, preserving local pace
at double camera scale and lengthening region-crossing journeys. No economic
retune or fake new site families. Actual bindings still have nine functional
sites/seven routes. Old v1/v2 generated reference checksums remain identical.

Vast camera starts5.2/max9, reference illustration6688wide, with native labels,
RMB/MMB/wheel, minimap and explicit Overview. Old defaults2.6/max4.5remain. Foundry
adds Vast; strategic factories choose Large/Vast. Existing slots/commands stay
Large; Vast v3/v4 use `_g3_` paths, selected explicitly by new/resume. Correct size
and campaign scene survive dungeon return. No shared global builder dimensions.
Generic navigator capacity grows to768x432; the authored terrain writer's192x108
guard remains. Inline/standalone schemas stay synchronized by rebuild tooling.

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene strategy-ai-vast
```

Use `strategy-vast` for the v3 classic campaign; original `strategy-ai` resumes
the user's current Large v4 profile. The new size has its own fresh/resumable
company. No external model: authored offline examples remain optional in Factions.

Focused72domain/38session/84native/127managed checks plus6Python cases PASS,
including three Vast biome bindings, old fingerprints, failed-write rollback /
exact reload,30simulated days and31ordinary battle commands/loot/report. Current
full-source results/integrity/preservation are owned by QA. No physical claim.

Final113/113PASS,0errors/0warnings,110Python tests. Source fingerprint
`d95384ec3ed753bf6390f295d7069cb22294175306e21ec23a532b0f457a42bf` matches the
tree.10/10baseline save/art hashes unchanged. Existing player Largev4 is still
generator2/tick410; it had advanced since the older96b tick343receipt and its
last write predates this verification. Do not reset it or mislabel that changed
historical hash as a test mutation. Supplementary Foundry11checks also PASS.

Next: user review of actual world size/scrolling/travel/logistics, then balance
and stage97comparison. More towns/playable site families need their own genuine
content; do not fill the enlarged map with fake interactive markers. Provider /
model/cost choice still precedes live inference. L96c-01 and all prior live gaps
remain open; do not restart the expired autonomous queue or reset old progress.

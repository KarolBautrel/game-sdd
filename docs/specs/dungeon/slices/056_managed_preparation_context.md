# Managed preparation survives preview changes

Stage86, 2026-11-05. Owners: presentation014 (preview reset), presentation015
(generator controls), world010 (owned mine expedition and atomic settlement).

- From campaign mine preparation, switch authored/generated sources, reroll and
  change difficulty. Keep town_preparation true, no active run, unchanged gold,
  supplies, equipment and receipts. Default packing still obeys actual ownership.
- Select authored mine and Start. Create exactly one managed active run, deduct
  its selected owned supplies once, preserve its equipment snapshot and clear
  the preparation flag only after begin_run succeeds.
- Insufficient owned supplies reject Start without entering a sandbox, losing
  preparation or altering the profile. A standalone preview performs the same
  source/generator changes without acquiring campaign preparation or charges.
- Native input integration follows the complete contract in world/slices/010:
  actual guarded-room combat victory, loot, exit, settlement, issuer report and
  exact disk reload. No forced combat result or cleared-room fixture.

Proof: dungeon_preparation_context_tests.gd and native livingcontract review;
physical/user acceptance remains distinct. Original defect was exposed by
living-contract-native-first, not a claimed full-victory result.

# Supply-pipeline evidence

Before: published97a production654aaa225abdf9b53678a68f639748d33405b47b.
After:97b source hashes in after-source.json, before subsequent97c changes.

- before.json / after.json:12identical-start faction-only180day cases. This
  isolates faction decisions; opening job reservations stay fixed.
- native-before.json / native-after.json: six identical-start actual30day regional
  probes. Regional job expiry/reposting and company upkeep run normally; the
  company remains idle at its starting town, mine occupied, no player actions.
- capacity-iteration.json / capacity-iteration-native.json: intermediate results
  that exposed repeated full-capacity attempts, before the shared free-slot gate.
- before-replay.json: previous expected result under the old production revision;
  old checkpoints/commands/replies stay unchanged, current expected digest follows
  the updated simulation revision.

Classic faction-only shortages581->4, deliveries1671->6238; authored offline
shortages654->2, deliveries1642->6125. Native shortages55->4, deliveries221->937.
Shortages count faction-days, not elapsed world days. All accounting reconciles.
Recorded fixtures are authored examples, not live-model output or a cost result.
Physical acceptance remains open. No player save or desktop surface is touched.

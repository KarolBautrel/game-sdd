# Background contracts and preview audit

Latest user request: choose and perform only tasks WITHOUT computer takeover.
No OS input, activation or visible launch is authorized. This supersedes earlier
desktop-release notes. No new commit/push; local master583ebc84, preserve85..91.

Read [the report](../qa/2026-11-09-background-contracts.md) and the final verification
receipt in docs/design/background-polish/2026-11-09/ before choosing further work.

## Current state

- Stage90: headless actual HUD/animation audit475checks/40cases PASS, covering
  real roster attacks, basic-to-Aimed number shortcut, miss and near-death HP.
  The old2-versus3preview observation did not reproduce. No damage/resolver/art /
  animation fix was made; do not claim the tentative defect was confirmed/fixed.
- Stage91: delivery/recon cards and commands share a pure availability query.
  New progress and tooltips explain carried food, issuer/stationarity, missing
  objective, pending event/expedition and paid/closed state. No save schema,
  rewards, costs or accepted style change. Session151/UI157checks PASS.
- Authored and Large2087/20261107 service chains complete delivery and recon
  using normal course/tick/shop/accept/report commands. Actual cost reconciliation,
  failed write/retry, one-time rewards, exact disk reload and upkeep boundaries
  pass. Diagnostic economy table is in the report; no balance change is implied.
- Full verification and preservation receipts are linked by the report. Eight
  known preexisting player/QA profiles still matched their earlier hashes before
  full validation. Final after-run comparisons are retained with the receipt.
- Stage91 is AWAITING_INTERACTIVE, not fully accepted. No computer-use tool or
  physical play ran this batch; do not substitute the automated service chains.
- Earlier physical mine contract and L87/L88/L89 evidence remain historical PASS;
  accepted art, manually authored terrain and local earlier fixes are preserved.

## Next work

While the user retains the desktop, source/headless work only. Do not reopen
passed suites without a new change/failure, start a new feature pool or change
balance merely to consume time. Record any further bounded issue before editing.

When controls are explicitly released, run L91-01 delivery/recon normally on a
separate QA profile and L91-02 progress/tooltips/readability. Then remaining
L77-01 camp/speeds/raids/conflict and user movement/map/prop review. Existing
mine QA seed20261107 remains the paused paid profile from the previous session;
do not reset it or use a player's save for new tests.

Later launch (do not run while the user holds the desktop):

```powershell
& .\tools\qa\start_game.ps1 -Scene regions
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish
```

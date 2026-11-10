# Slice024: negotiations without repeated offers

Owner [world023](../023_diplomatic_proposals.md).

1. An otherwise eligible pair with an outgoing or incoming nonaggression offer
   produces no second same-kind proposal. Incoming acceptance/rejection still
   uses the original ID/terms, and only the counterparty can sign it.
2. A pending defensive pact suppresses another defensive proposal. An actually
   active pact is not confused with a pending offer or an expired treaty.
3. A pressured war faction with either-direction live ceasefire offer responds
   or waits instead of proposing another. Once the offer expires, an ordinary
   new proposal can be made even before archival; old replies still fail.
4. Expired incoming trade/pact/peace offers do not become new classic/model
   response candidates. State/receipts are not mutated by observation.
5. A current explicit duplicate still rejects immutably; stale model intent and
   simultaneous conflicts still pass the real operator gates. No consent is
   granted by reading a pending flag. Legacy request/reply bytes remain valid.
6. Repeat identical-start native30day and faction-only180day matrices after97b.
   Record actual rejected reasons and war/peace/resource outcomes, not an assumed
   zero-error success. Final shared regressions and save/art preservation pass.

Proof: `diplomatic_proposal_tests.gd`, existing classic/adapter/session/native
tests, `strategy_comparison_run.gd` and `regional_supply_probe.gd`.
L97c-01 remains AWAITING_INTERACTIVE.

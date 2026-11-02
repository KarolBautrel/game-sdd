# Slice001: campaign handoff

Owner: ../001_campaign_boundary.md

| ID | Scenario | Expected |
| --- | --- | --- |
| W6-01 | purchase, insufficient gold, unknown supply | exact stock/cost; rejected transaction unchanged |
| W6-02 | managed start, packing/stock/duplicate failures | one deduction and unique active receipt; effects retained |
| W6-03 | checkpoint and new service instance | data/state/seed restored from isolated file |
| W6-04 | completed/retreated/failed and duplicate/mismatch | exact domain delta, injury persistence and single refund |
| W6-05 | malformed/unsupported save and write failure | blocked, original bytes/state unchanged |
| W6-06 | hub/town/preparation/return UI | real scene controls, sandbox isolation, resume and normal retreat |

Automated: scripts/session/campaign_session_tests.gd and
scripts/presentation/world_town_tests.gd. Actual: stage6 report. No Debug Win
is used as proof of combat or expedition completion.

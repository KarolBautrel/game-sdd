# Slice 053: Beta full-loop QA

Owner: `overview/045_beta_full_loop_qa_v1.md`.

| ID | Action | Expected |
| --- | --- | --- |
| B1-01 | Repeat generated D2 seed 170717 and combat seed 1234 | Identical checkpoints and final payload |
| B1-02 | Prepare capacity, travel, resolve event/hazard, refuel, claim chests | Legal transitions; correct supply/reward deltas |
| B1-03 | Win through resolver commands and return through session | Secured room, no pending launch; returned HP retained |
| B1-04 | Finish exit and attempt further movement | Completed result with kept rewards; movement rejected |
| B1-05 | Return injured hero then launch next combat | Absolute HP retained without double-counting old injury |
| B1-06 | Unsupported/wrong-source/duplicate result | Rejection preserves input state and pending request |
| B1-07 | Incapacitated hero then bandage | Zero HP persists before recovery; one recovered HP permits next fight |
| B1-08 | Actual preparation -> hazards/event -> combat -> reward -> exit | Personally operated, readable feedback; HP return/recovery verified |

Automated B1-01..07: named suites in owner spec. B1-08: actual stage report.

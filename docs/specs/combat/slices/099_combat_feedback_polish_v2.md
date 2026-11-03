# Slice099: feedback polish

Owner: [presentation091](../presentation/091_combat_feedback_polish_v2.md).

| ID | Acceptance | Proof |
| --- | --- | --- |
| S10-01 | Hover shows profile AP/destination MP, correct display resources; animation/result feedback survives hover. | combat_feedback_polish_tests |
| S10-02 | Rejected command shows readable reason in banner/feed, spends nothing and creates no damage feedback. | same suite; floating text tests |
| S10-03 | Preview's three lines fit padded frame and sit below resources at top edge. | same suite; targeting/layout suites |
| S10-04 | Committed victory/defeat is explicit and preserves normal return controls/history. | same suite awaits actual completion within6seconds, including long painted bow/death; beta/session tests |
| S10-05 | Actual effects, input unlock and victory/defeat/return look correct. | live L10-01/02, NOT_RUN |

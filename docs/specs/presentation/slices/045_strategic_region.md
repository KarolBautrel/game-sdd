# Native strategic region

Owner [presentation045](../045_strategic_region.md), gameplay world018.
Exercise actual controls/focus/pause at1280x720/1920x1080/2560x1440, six towns,
camera/terrain-safe orders/party interpolation, job reasons/callbacks, provisions,
gear and managed mine prepare/resume/return. Preserve row/scroll identity and
input/modal isolation. Proof: strategic_interface_tests.gd, regional_session_tests.gd.
Automated interface81checks pass at the three named resolutions; session380 and
managed expedition127checks cover callback/persistence integration. Actual
headless DungeonDebug/CombatDebug scenes use31ordinary resolver commands, owned
packing, loot and managed strategic return. No physical play is inferred.
[Final-source QA](../../../qa/2026-11-09-strategic-region.md) owns the full run.
Visible L95 appearance/gestures/ordinary victory remain deferred.

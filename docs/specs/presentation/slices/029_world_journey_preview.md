# World journey preview acceptance

Owner: presentation029. Stage69. Status: IMPLEMENTED / AUTOMATED_PASS /
AWAITING_INTERACTIVE. Native GPU proof is separate from OS input acceptance.

1. Preview Old Mine and Broken Cart repeatedly from Ravenford. The complete
   profile remains byte/data equivalent: same food, time, seed/count and events.
2. Old Mine quotes6hours/1food, reserve1, arrival Day1 14:00 before events.
   Confirm once: location/time/food update exactly once and selected plan clears.
3. Cancel a preview: no transaction. Confirm after a stale/blocked selection:
   backend guards preserve state. Insufficient food is explained and disabled.
4. Travel to Broken Cart through the normal confirm button; actual authored
   pending choices appear and all further journey controls are unavailable.
5. Preserve existing write-failure/save/packing-reserve tests and verify native
   region/control bounds at720p/1080p/1440p, recording physical input separately.

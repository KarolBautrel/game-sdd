# 052 Skill Cooldown Expires On Own Turn

Status: implemented  
Date: 2026-07-14

## Acceptance

- enemy starts with `skill_cooldown` for `power_strike`;
- enemy ends turn;
- player ends turn;
- enemy turn starts again;
- cooldown remaining turns reaches 0;
- `status_expired` is emitted;
- enemy no longer has the cooldown status.


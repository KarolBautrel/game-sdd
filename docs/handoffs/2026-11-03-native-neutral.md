# Native neutral reference and calm gait: accepted for now

User explicitly accepts this version FOR NOW and requests game-repo publication.
Follow [publication handoff](2026-11-03-painted-game-publication.md). Further
posture/locomotion polish is deferred; no new art iteration is active.

Latest user explicitly reopens work after59: base the two-handed knight's neutral
standing pose closely on the sword/shield warrior, and slow the horse-like foot
cycling. Only these tasks are authorized. Read [stage60](../qa/stages/2026-11-03-stage-60.md)
and presentation022/slice022/milestone017. IMPLEMENTED / AUTOMATED_PASS /
USER_ACCEPTED_FOR_NOW. Do not reapply rejected58's broad stance/model.

Current neutral uses original native knight/warrior/weapon pixels in Aseprite;
no whole-model regeneration/resampling. Original knight head/boots verified exact.
24 knight neutral_idle PNG changes only;2280 other PNGs, including all combat and
walking drawings, unchanged. NE lowered carry retained. Five source views and
three disclosed reflections; source reopen/idle planting PASS. All non-walk times
unchanged. Main source script tools/aseprite/knight_neutral_native.lua.

Walking now8x125ms=1000ms cycle/160px stride/160px/s: two foot contacts per second,
20% slower travel than57,60% faster than initial100px/s. All96 walk sources and
source/runtime/player metadata agree. No domain or AP/MP changes.301 before files
and2304 baseline PNG identities under refinements/native_neutral/before.

Proof: native7386/0, battle313/0, original15679/0, equipment31/0, feedback179/0,
lifecycle/combat/import/offline3579/validator PASS. Actual104px steps about0.69s,
declared0.65s; new test rejects full-cycle churning during that short travel.
28-case player logic/local PNG loading/frame controls PASS. Static poses inspected;
no agent-observed continuous motion or physical approval. Preview/reference:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_native_neutral_preview.ps1"
```

Battle (new window, normal actions; Tools / Enemy AI once during enemy turns):

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat -CombatScenario drawn_roster_skirmish
```

L60-01 has temporary explicit acceptance. Terminal/campaign/61 older physical
cases remain open. The user authorizes game master publication; no next roster,
workshop release or desktop control. English workshopv1.0.1 remains unchanged.

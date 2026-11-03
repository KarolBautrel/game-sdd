# Expedition and battle visual target

The user approved the campaign/inventory appearance and asked for the same family
in exploration and battle. Owners presentation007/slice007. Stage27 room map and
paper preparation/events;28 board-preserving battle side inspector/actions;29
integrated release. These are extensions of concept A, not another style reset.

Actual final EXE captures: [dungeon](implemented-dungeon.png),
[battle](implemented-combat.png), [terminal result](implemented-result.png).
Fixtures are isolated/in-memory, never physical gameplay acceptance.

Source preview on larger left DISPLAY1, windowed (run ONE scene at a time):

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
.\tools\qa\start_game.ps1 -Scene dungeon
```

For battle replace dungeon with combat. The explicit debug entry command is:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
```

Native automated play review:

```powershell
.venv/Scripts/python.exe tools/qa/render_campaign.py --suite play --run-id UNIQUE --views dungeon,combat --sizes 1920x1080,2560x1440,1280x720,3840x2160 --exercise
```

Add --exe PATH to test a packaged build. The existing ExportProbe opt-in starts
the same fixture in editor/runtime because release templates disable CLI script
overrides. It stays minimized/no_focus and uses viewport input only. Read the
campaign [tool/art workflow](../campaign-ui/TOOLING.md) for fonts/assets/Aseprite/MCP.

Room sources and generation brief are under assets_src/campaign_ui; final pixels
come from tools/aseprite/campaign_ui_assets.lua. Dark vignette illustration
backdrops stay inside room cards; no unverified transparency claim.
Battle chrome never changes resolver commands, costs, rolls or animation timing.
Tools retains scenario picker and developer helpers; terminal fixtures are not
ordinary victory proof. Live acceptance is recorded separately in the QA registry.

# Combat Terrain Backgrounds

These are precomposited 10x10 combat board backgrounds.

The current generator creates two continuous meadow surfaces. It does not paint visible per-tile grass blocks. It uses procedural grass texture, soft clumps, and occasional `grass_tuft` accents so the board reads as one coherent field.

Use them as full-board combat floor images through `background_path` in combat encounter data. Terrain props, blockers, cover objects, overlays, and units render on top of these backgrounds.

Regenerate the set with:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://tools/terrain/generate_combat_backgrounds.gd
```

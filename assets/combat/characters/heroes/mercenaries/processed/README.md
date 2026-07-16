# Processed Combat Character Sheets

Generated category: `hero_mercenaries`.

The extractor chroma-keys green backgrounds, crops detected sprite components, assigns rows to coarse action groups, and writes mirrored left/right PNG variants.

Current action row contract:

- row 1: `pose`
- row 2: `walk`
- row 3: `combat`
- row 4: `hit`
- row 5+: `death`

Regenerate with:

```powershell
.\tools\characters\extract_mercenary_combat_heroes.ps1
```
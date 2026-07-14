# 004 Data Contracts

Status: draft  
Date: 2026-07-14

## Rule

Runtime content data must be validated before it is used by Godot scenes.

## Contract locations

- World regions: `resources/schemas/world_region.schema.json`
- Towns: `resources/schemas/town.schema.json`
- Dungeons: `resources/schemas/dungeon.schema.json`
- Combat actions: `resources/schemas/combat_action.schema.json`

## Validation command

```powershell
python tools/validators/validate_all.py
```

## Required guarantees

- Every data file has an `id`.
- IDs use lowercase snake case.
- Files are valid JSON.
- Files match their schema.
- Cross-file references resolve where currently supported by the validator.


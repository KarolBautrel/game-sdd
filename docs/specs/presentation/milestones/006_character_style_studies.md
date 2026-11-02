# Character style research and studies

Owner: presentation011; slice011. User authorized2026-11-02.

1. DONE: rollback checkpoint619237db pushed; remote hash verified,7850 LFS objects/679MB.
2. DONE: primary-source research, pinned CC0 anatomy archive and skill references;
   see `docs/design/character-art/STYLE_RESEARCH.md` and study provenance.
3. DONE: three isolated static3D studies, separate editable source parts,
   .blend/FBX/2048px albedo,18 real renders and two Aseprite comparison boards.
4. TECHNICAL_PASS:8681 verification checks (243 study checks plus8438 baseline
   file hashes),3 actual FBX reimports, validator and complete roster check PASS.
   Delivery37 files/66009425 bytes plus its manifest. Requested study commit/push
   follows these checks; the commit identity is available in branch Git history.
5. AWAITING_STYLE_CHOICE: user chooses a direction; no production replacement.

No OS input or visible game/editor launch; physical test backlog remains pending.

Proof: [stage38](../../../qa/stages/2026-11-02-stage-38.md),
`assets_src/characters/style_studies/2026-11-02/verification.json` and `delivery.json`.
Commands: Blender background `tools/blender/verify_style_studies.py`, Aseprite
hidden batch `tools/aseprite/style_studies.lua`, `python tools/validators/validate_all.py`
and `python tools/qa/check_roster.py` all PASS. Next step is a user style choice,
then a separately authorized rigged pilot with motion/gameplay acceptance.

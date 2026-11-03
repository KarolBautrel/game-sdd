# Stage61: Bran identity / two equipment kits

User instruction: "TO do dziela, wykonaj1". Scope: one hero's identity across
sword/shield and greatsword, proven in campaign before more roster work.
IMPLEMENTED / AUTOMATED_PASS / AWAITING_INTERACTIVE. Local on master; no commit
or push requested for this task. Stage60's accepted art/cadence remains unchanged.

## Implemented behavior

`hero_equipment_identity.json` explicitly maps Bran's two supported kits to
authored variants. CampaignEquipment selects by hero identity and both equipped
hands, preserving existing stats, roster name/portrait, ownership and snapshots.
Unsupported kits/heroes retain the old weapon-driven fallback; this pilot does
not convert arbitrary armour, empty hands or other weapon families.

Sword/shield retains accepted warrior art. New bran_greatsword has352runtime
frames/56layered Aseprite clips, seven primary actions/eight directions. It uses
Bran's native front/profile head drawings on accepted two-handed body/weapon
poses; rear drawings retain compatible brown hair. The small falling head rotates
with the pose; the body is never resampled. Three views are disclosed reflections.
All2304 accepted six-role PNGs are byte-identical. New art remains a candidate.

Ravenford sells hero_greatsword for20g (resale9g). Its existing-rule two-handed
profile grants Basic Attack(+2) and Power Strike(+4,2AP,3-turn cooldown). Buying
never equips. Shield conflict still rejects atomically; remove the shield first.
No save migration, automatic equipment grant or player-save reset.

The opt-in launcher opens ordinary App/Stash with a separate resumable
`user://qa_hero_equipment_pilot_v1.json`, seeded only when missing with both kits.
Existing/corrupt pilot saves are preserved; failure never falls through to the
real save. The player campaign_v1.json was checked unchanged in session tests.
Ordinary campaign can purchase/use the item without the pilot switch.

## Evidence

- `build_bran_identity.py`:56sources reopened, pixels/tags/timings exact;
  recorded head masks only, idle feet planted;2304 old PNG hashes unchanged.
- `build_hero_equipment_preview.py`:2kits,112clip/view combinations,704source
  frames, correct atlas sizes/timings and unchanged tested player template.
- `run_hero_equipment_checks.py`: fail-closed logs under artifacts/bran-identity.
  Identity1046/0, including normal shop/UI equip, failed-save rollback, conflict
  atomicity, reload, pending-road/expedition locks and return persistence.
- Full legal AI road battles: sword/shield victory33commands, greatsword
  victory30commands; both authoritative result payloads settled and reloaded.
  Managed expedition snapshot/reload and domain retreat/settlement also PASS.
  These are automated proofs, not physical ordinary victory acceptance.
- Drawn runtime7386/0; battle313/0; original roster15679/0; equipment31/0;
  feedback179/0; animation lifecycle/domain combat/import PASS. Campaign gear50/0,
  campaign session and trade48/0 PASS. `validate_all.py` PASS.
- Identity validator rejects missing variants, ambiguous kits, greatsword/shield
  and wrong hero references. The item/schema and runtime catalogue are updated.
- Launcher ConfigureOnly: DISPLAY1,3840x2160,Godot screen0; no process launched.
  Prior override.cfg restored byte-for-byte after that test. Ordinary App with
  the pilot argument starts headlessly without diagnostics. No OS input used.

An initial test parse error (untyped Dictionary indexing) was fixed; final suites
pass. Static front/profile/back/attack and falling samples were inspected. Full
continuous1x motion and physical campaign flow await L61-01/02/user review.

## User review commands

Preview (both kits, direction/action selector, native1x and enlargement):

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_hero_equipment_preview.ps1"
```

Ordinary campaign on the larger left display, isolated resumable pilot save:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_hero_equipment_pilot.ps1"
```

Bran starts with sword/shield. In Stash, select Off hand and Unequip, select
Two-handed greatsword and Equip. Leave town and test an ordinary fight and
return/restart. To restore sword/shield, equip the owned sword, then the shield.
Normal player campaign entry is `start_game.ps1 -Scene app`.

Next: L61-01/02 only. Do not expand humans/creatures or reopen stage60 posture
without user direction. Do not label newly composed Bran art user-approved yet.

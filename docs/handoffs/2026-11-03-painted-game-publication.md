# Accepted painted battle checkpoint: publication

User2026-11-03 explicitly accepts stage60 FOR NOW, requests publication in the
main game repository and asks for next-step advice. Posture/locomotion polish is
deferred for a later user-authorized pass. Decision source:
assets_src/characters/drawn_animation/2026-11-03/refinements/native_neutral/user_acceptance.json.

Repository https://github.com/KarolBautrel/game-sdd, default branch master.
Publication is authorized; source/author/remote audit completed before commit.
The publication receipt in docs/qa/2026-11-03-painted-battle-publication.md will
record the verified pushed source commit. No rewrite/force push or workshop release.

Accepted current state: six painted roles, isolated eight-actor Painted Six review
encounter and direct -CombatScenario launch; warrior/north shield/sword correction;
native two-handed knight neutral stance, exact original heads/boots;24 neutral
PNG changes against the rollback baseline. Walking uses125ms cels/1000ms cycles,
160px stride/160px/s, two foot contacts per second. Other combat/walk drawings and
non-walk timing unchanged. Source/backups/rejected58/rollback records are retained
as ignored-by-Godot art sources, with rejected reapplication blocked.

Proof: native7386/0, battle313/0, original15679/0, equipment31/0, feedback179/0,
lifecycle/combat/import PASS; native source/scope verifier, offline3579 and repository
validator PASS before publication. L60-01 is PASS_USER_REPORTED_FOR_NOW. This does
not close terminal battle/campaign or61 old physical cases; no result was reported.

Next proposed scope: character identity and weapon/loadout agreement. The current
accepted sprites have baked weapons; weapon-driven profile selection can change
the whole hero appearance. Define one hero identity across supported weapon
variants, with truthful actions/ranges/hands and existing campaign save handoff.
Start with one painted hero/two supported loadouts and prove equip→battle→return
before extending the remaining humans. Then an early-enemy human batch; creatures
need a separate motion pilot (e.g. wolf). These are recommendations, not a newly
authorized implementation queue. Keep accepted art stable while gameplay develops.

Active game remains game_dir/sdd-game. Desktop not released, no new provider/
installation/paid generation; reusable English workshopv1.0.1 remains unchanged.

# Publish stages61..65 to the main game repository

User explicitly requests publication after positive feedback: "Mozesz tyo teraz
juz wypchnac". This authorizes the current equipment identity, SE/SW tactical
view, painted bandits and wolf work on the default master branch. It does not
close unreported ordinary physical-play cases or authorize a new production batch.

Repository: https://github.com/KarolBautrel/game-sdd (default master).
Pre-publication parent:041072a7b5d1a440539831fa7f6301b892dbfe1d.
Fetched origin/master equals local parent; no remote work is overwritten.
Effective approved identity: Karol Bautrel,
93617105+KarolBautrel@users.noreply.github.com; GitHub login/id verified
KarolBautrel/93617105. No historical author rewrite or force push.

Scope: Bran's two equipment variants and normal greatsword/shop/save handoff;
two-view tactical rendering with preserved eight-view archives; full managed
two-kit campaign proof; painted bandit archer/shield fighter and grey wolf;
sources, raw prompts/references, offline previews, review launchers, tests/specs.

Art delivery includes352 Bran variant frames and272 new enemy/wolf frames,
one greatsword icon, editable Aseprite sources and nine generated raw sheets.
Runtime catalogue grows9920 ->10545 entries:625added,0removed,0changed existing
entries. All2304 accepted painted PNG hashes remain exact. Source re-export
reproduces272 new enemy PNGs byte-for-byte without changing44 edited sources.
The large line diff in the deterministic catalogue is insertion alignment, not
replacement of old actor graphics.

Pre-publication checks: run_hero_equipment_checks.py (full import/drawn/battle/
tactical/new-enemy/original/lifecycle/equipment/combat/feedback and campaign/shop/
identity/validator); native preview logic413 and baseline3579; source hash audit;
staged whitespace/LFS pointer review. The final pre-publication combined run is
PASS: drawn7386/0, battle313/0, tactical5157/0 under the selected7actor pilot,
new enemy1887/0, original16111/0, lifecycle, equipment31/0, domain combat,
feedback179/0, identity1259/0, campaign gear50/0, campaign session/trade48/0 and
validator. Offline players413/3579 pass. Remote source/LFS receipt follows below
after publication is verified.

The fresh publication run exposed a terminal-feedback test timing assumption:
the current painted_enemy_pilot override selects an archer whose full attack /
target death lasts longer than the old fixed2.5second test delay. The regression
now waits for actual animation unlock with a6second failure deadline, preserving
the hidden-before-commit/banner/hover/input assertions. Focused feedback179/0
passes with that same override; the complete combined rerun also passes before
committing. Product attack/death timing is unchanged.

Next recommended work: user review/ordinary play of the delivered batch via
start_painted_enemy_pilot.ps1 and the resumable campaign pilot. Address specific
visual/gameplay feedback, then select the next human-enemy batch. Further city
movement, creature expansion and workshop publication remain separate scopes.

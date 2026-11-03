# Painted hero identity and equipment pilot

Subsequent stage62/presentation024 limits tactical display to SE/SW. Eight-view
source coverage remains archival; active battle review now concerns those two
front three-quarter views. No additional art acceptance is inferred.

Stage61, authorized2026-11-03: implement point1 of the proposed next steps.
This narrowly supersedes presentation010's weapon-selected body rollback for
Bran's sword/shield and greatsword kits. It does not restore the rejected3D rig.

Bran retains his roster id, portrait, name, bearded face, brown hair and blue/gold
armour family when changing between a one-handed sword with salvaged shield and
a two-handed greatsword. A kit selects an authored animation variant of that
hero, not another hero. The accepted warrior and knight files remain unchanged.
The greatsword variant uses native Aseprite head composition from Bran's existing
drawings onto the approved two-handed poses; preserve weapon/body pixels outside
the recorded head edit regions. No whole-body resampling or new gait changes.

The pilot covers seven clips and eight facings for both kits: neutral/combat
idle, neutral/combat walk, attack, hit and death. Five views are drawn and three
are disclosed reflections, including reversed asymmetry. Shared standing head
references are translated at native resolution; falling heads use nearest-pixel
rotation of the small head only, following their falling pose. Compatible rear
drawings retain their brown-haired heads. Sources, edit regions and reopen/pixel
proofs are retained.
This is authored sprite variation, not a general interchangeable equipment rig.

An explicit identity/kit table owns the two mappings. Outside those mappings,
the existing weapon-driven fallback remains for compatibility; no claim is made
that arbitrary bows, empty hands, cosmetic armour or other heroes are converted.
Existing six-role registry and accepted sprites are not replaced by this pilot.

World005 owns inventory and save transactions. A catalogue greatsword is offered
by Ravenford using existing two-handed combat rules. Buying does not equip;
equipping with a shield is rejected atomically until the shield is removed.
Existing saves receive no new items and need no version migration. Campaign
launch uses frozen equipment snapshots; reload and return retain hero identity.

An opt-in campaign pilot uses a separate QA save, seeds only a missing pilot
save with both owned kits, and opens the ordinary campaign/stash UI. Subsequent
launches resume it. Never load, overwrite or seed the player's campaign_v1.json.
Normal campaign and merchant integration also work without the QA entry point.

Proof: slice023, identity/equipment session tests, source reopen proof, native
runtime texture checks, combat regressions and validate_all. Physical campaign
equip -> ordinary fight -> return/restart and continuous motion remain separately
reported AWAITING_INTERACTIVE until actually exercised. Do not infer art approval
for the new face composition from the stage60 acceptance.

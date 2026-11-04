# Approved world atlas preservation checkpoint

Date:2026-11-04. The user approves the current world-map appearance and explicitly
requests preserving it before redesigning the campaign structure.

`world-atlas-stage76.zip` contains233files: the complete uncommitted stage76
working-tree delta, the accepted Marches and new world/province plates, original
campaign material/illustration inputs, Aseprite sources/export recipes, shared
campaign art/fonts/licenses, native screenshots, rules/tests and handoff records.
Private ignored skill packages, caches and player saves are excluded.

ZIP SHA256:
`d208ceb651294cc56318d4aa32bee7a5caa44a7cf9c7ec76d8f54bbf9280e777`

The adjacent `manifest.json` records every payload hash/size, the published base
commit, validation receipts and the second copy's location. The ZIP also contains
an internal `snapshot.json` and root-relative files beneath `payload/`.

Byte-identical backup:
`C:/Users/karol/Desktop/Gierka/backups/sdd-game/2026-11-04-world-atlas-approved/world-atlas-stage76.zip`.
Both copies were checksum-verified. Every payload file was extracted into a new
isolated artifacts/qa-runs/world-atlas-preservation-check/payload/ directory and
verified against its manifest:233/233PASS. This proves archive recovery of the
files; it is not a claim of a separately exported/physically played game.

To recover the playable source, use a separate fresh clone of game-sdd at the
manifest's `base_commit`, fetch that clone's Git LFS assets, then overlay the
ZIP's `payload/` at its repository root. Do not overwrite an active working copy.
The bundle is a delta plus explicit art dependencies, not a standalone game.
Godot4.7 and the project's normal import/launch workflow still apply.

Current accepted style instructions:
docs/design/world-atlas/2026-11-04/APPROVED_STYLE.md.
The living-world proposal in the same folder is a discussion draft; visual
approval does not approve fixed geography or those new gameplay mechanics.

Publication status: local preservation only; no new commit/push was requested.
The ZIP has an explicit Git LFS rule so a future authorized publication can carry
the checkpoint without placing a104.7MiBblob in ordinary Git history.

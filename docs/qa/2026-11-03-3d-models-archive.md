# Preserve the rejected3D direction before drawn2.5D research

User2026-11-03 explicitly requests a full current-state commit/push on a separate
branch named `3d-models`. Source branch before archive:
`feature/dungeon-eod-checkpoint-2026-07-17`, base commit `de83f87b`.

Scope: all current nonignored game/source art, editable Blender/FBX/Aseprite files,
renders, tooling, licensing, preview UI and workflow notes, including prior dirty
work. Existing .gitattributes sends binary art through Git LFS. The six new source
delivery folders also retain exact text bytes: normalizing their CRLF files would
invalidate recorded delivery hashes. No source files are deleted or redesigned.
Ignored machine caches, installers, Blender backups and artifact logs remain local.

The user rejects the motion result despite technical gates: bowed-looking legs,
wide stiff walking, unnatural wrist-driven sword rotation and poor bare hands;
gloves are desired. Do not interpret numeric foot/grip/FBX checks as visual
approval. The3D source is historical/experimental; no full-set/cast rollout.

Before commit/push: project validator, current style-preview headless tests,
source-delivery hashes and staged diff/LFS review. Git and remote branch identity
are the authoritative archive receipt; the following research handoff records
the actual pushed commit. No force push or update to the original branch.

Executed: project validator PASS; headless style-preview42 checks PASS;843 source
delivery hashes PASS. Source archive folders preserve upstream CRLF/trailing
formatting under narrow -text/-whitespace attributes; code checks remain active.
Staged-byte verification also PASS for all843 identities (766 LFS pointers).
Diff check excludes only four unchanged copies of upstream MPFB-LICENSE.md:
their literal Setext `LICENSE` / `=======` header triggers Git's conflict-marker
heuristic. The original licence bytes are hash-verified and retained verbatim.

Next authorized task after successful archive: primary-source internet research
for detailed drawn/painted characters, directional sprite animation and appropriate
tools/skills/integration. Keep the selected terrain/UI and existing Godot renderer.
Distinguish the visual references' actual pipelines from the requested drawn
production method. No implementation/installation/purchase is implied by research.
61 physical game cases remain NOT_RUN; native desktop controls unreleased.

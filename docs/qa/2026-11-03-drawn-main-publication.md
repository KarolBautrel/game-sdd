# Promote accepted painted character work to the default branch

User2026-11-03 explicitly requests committing/pushing all current work and making
the accepted painted direction the main game branch. Default branch verified via
GitHub REST: `KarolBautrel/game-sdd`, `master`. Authenticated account KarolBautrel,
ID93617105. Effective author Karol Bautrel with the account-linked address
93617105+KarolBautrel@users.noreply.github.com.

Complete art/source/code checkpoint on2d-art-research:
`9edbd4a32286586ba6f3053d1ca60d41d5003a63`.9324 changed paths include static studies,
all accepted animations, raw inputs/prompts, editable Aseprite sources, rejected
candidates/baselines, runtime frames, Godot import metadata, specs and test tools.
Ignored local caches, builds, override.cfg, installers and artifacts stay local.
Assets remain in Git LFS under the existing extension rules.

Pre-commit validation PASS: drawn7368/0, original roster15679/0, equipment31/0,
feedback179/0, animation lifecycle OK, Godot combat slices and validate_all.py.
Staged-source audit PASS:4626 source files,4145 LFS pointers, all source bytes
match the working files. Narrow source attributes preserve CRLF/hashes and allow
CR at line ends while retaining whitespace checks. No source normalization or
deletion was used to make publication pass.

Git LFS fsck PASS. Merge diff check retains four already archived, byte-identical
MPFB licence files whose literal Setext `=======` heading triggers Git's conflict-
marker heuristic. Exclude only those four from that check; all other merge paths
must pass. Their content is unchanged from the audited feature checkpoint.

Previous remote master `a851ca87c90770ff7a984957ce0145d9f9118eed` has one README
cleanup not in the feature ancestry. Local master first fast-forwards to that
tip, then merges2d-art-research. The README conflict retains removal of redundant
absolute launch commands and retains newer campaign guidance; it adds the accepted
character source/stage links and the relative drawn-gallery launch entry.
No gameplay or source assets conflict. Publication uses ordinary fast-forward
remote push after this merge, without force, history replacement or protection
changes. The old author-repair preview refs remain unexecuted.

Publication CONFIRMED2026-11-03: normal push advanced origin/master from a851ca87
to merge167e2e22e07dfb52422c1f545b7b64aabc8c339e. Git LFS uploaded4069objects /
404MB successfully. `git ls-remote` returned that exact master SHA. GitHub REST
confirmed both author.login and committer.login as KarolBautrel, and both intended
parents (old main and complete source checkpoint). Local master was clean.
This receipt is subsequently committed on top of that published merge; the final
tip is the receipt commit, while167e2e22 is the complete accepted game merge.
Local audit/push receipts: artifacts/publication/.
All61 earlier physical cases and L53/L54 game cases remain NOT_RUN; stage55 preview
is explicitly USER_ACCEPTED. Source backups and the rejected3D archive are retained.

User also requests advice on preserving this process for future projects. No new
external repository or installed skill is authorized by that request for a
proposal. The current repository already carries the exact source guides,
prompts, pipelines, good/bad examples and verification records for later extraction.

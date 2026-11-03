# Git author attribution repair

User2026-11-03 requests correct account/contributions after the art research.
Authenticated GitHub account: `KarolBautrel`, user ID93617105.

## Completed: configuration and current archive

The repository-local identity was `Karol <karol@example.local>`. Push credentials
were already for the real account; changing credentials was not the remedy.

First tried the user's supplied `karol.bautre@gmail.com`. After the bounded
archive-only update, GitHub's commit API returned both author/committer as null.
This is observed lack of attribution, not proof about the user's private email
settings. Email-settings API access was unavailable under the current token;
no OAuth scope expansion or account-setting change was attempted.

The existing correctly attributed GitHub commit proves the account's own address:
`93617105+KarolBautrel@users.noreply.github.com`. Set repo-local user.name to
`Karol Bautrel` and user.email to this verified account address. Rebuilt only the
new archive checkpoint, retaining the original tree, parents, dates and message.
Used exact force-with-lease for this newly created task branch, never plain force.

Current remote/local `3d-models`:
`540524ed32e77f8d1f5219da62759a343ca2058a`.
GitHub REST confirms `author.login == committer.login == KarolBautrel`.
Tree remains `fb20d3b704e6a0e70acc41611bd15676b945efda`, identical to the original
e696d1c4 archive. No game/source asset bytes changed. Current local research
branch points to that same corrected checkpoint with uncommitted research notes.

Original task checkpoint and the unlinked Gmail experiment remain in local
`refs/archive/3d-models-before-email-fix-20261103` and
`refs/archive/3d-models-gmail-unlinked-20261103`. The default/master and original
feature branch have not been changed by the completed archive-only repair.

## Prepared: wider historical repair, NOT authorized/published yet

The old history contains45 placeholder-author commits reachable from master and
51 reachable from the feature/archive lineage. Built a53-commit preview in local
Git objects; original tree IDs, dates and message bytes match for every commit.
Only placeholder author/committer identities change, plus parent hashes. One
existing GitHub signature cannot transfer to a rebuilt commit and remains valid
in the preserved original. No replacement signature is fabricated.

| Remote branch | Current expected tip | Prepared corrected tip |
| --- | --- | --- |
| 3d-models | 540524ed32e77f8d1f5219da62759a343ca2058a | 496138e1 (full ID in preview ref) |
| feature/dungeon-eod-checkpoint-2026-07-17 | de83f87b6439e7479fb87729863d719de4c91034 | fd57454c (full ID in preview ref) |
| master | a851ca87c90770ff7a984957ce0145d9f9118eed | f75ca1f6 (full ID in preview ref) |

Prepared refs: `refs/author-repair-preview/<branch>`; preserved originals:
`refs/archive/author-repair-before/<branch>`. Full local mapping/proof:
`artifacts/git-author-repair/full-history-plan.json`.

An asynchronous question asks whether to update all three remote histories with
backups, or retain only the already completed archive/future-commit correction.
No elapsed time is approval. Do not publish these candidate refs or rewrite
master until the wider scope is explicitly approved. If approved: recheck every
remote SHA, publish old-tip backup refs first, then use exact leases and an atomic
push for the intended heads. Verify GitHub linkage, unchanged trees and refs.
Do not disable branch protections or merge rejected3D code to gain contributions.

Session-end update: user requests these research/handoff notes pushed on the
separate `2d-art-research` branch under their real account. This authorizes that
new branch push, not the pending rewrite of master. The53-commit preview above
predates the new research/handoff commit and remote branch; recompute against
current refs, including that branch, before any later approved history repair.
The full-history plan is local and not needed to reconstruct the research handoff.

GitHub associates author accounts using the commit email, not the pusher's display
name. [Email attribution documentation](https://docs.github.com/en/account-and-profile/concepts/email-addresses).
For the profile graph, eligible commits must also be on the default or gh-pages
branch; old history/config and graph refresh are separate concerns.
[Contribution troubleshooting](https://docs.github.com/en/account-and-profile/how-tos/contribution-settings/troubleshooting-missing-contributions).
No claim is made that the historical contribution graph is repaired yet.

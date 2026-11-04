# UI workshop publication

The user explicitly requested publication to a separate repository, then
continuation of native UI production. The English workshop is published privately:
https://github.com/KarolBautrel/dark-fantasy-ui-workshop.

- Branch main: `7ee44150ccce6cdced1be9ec9e090dad8d5f4652`.
- Verified author: Karol Bautrel, GitHub account KarolBautrel / id93617105;
  `93617105+KarolBautrel@users.noreply.github.com`.
- Tag/release v0.1.0 with the installable ZIP attached:
  https://github.com/KarolBautrel/dark-fantasy-ui-workshop/releases/tag/v0.1.0.
- Canonical standalone checkout:
  `C:/Users/karol/Desktop/Gierka/dark-fantasy-ui-workshop/`.
- In-game fallback copy remains `packages/dark-fantasy-ui-workshop/`.

Six tests / 3,600 seeded configurations and official skill validation pass locally.
Repository validator passes. A fresh remote clone under ignored
`artifacts/ui-workshop-publication/clean-clone/` passes all six tests and verifies
actual reference bytes. Checksummed assets explicitly preserve line endings in
Git; the initial EOL normalization issue was corrected before tagging the release.

GitHub CI at the published revision passes all four jobs: Windows/Linux, Python
3.10/3.12. Run: https://github.com/KarolBautrel/dark-fantasy-ui-workshop/actions/runs/41851352297.
Remote main and local commit were compared through `git ls-remote`; privacy and
default main were verified through `gh repo view`. No Git LFS stubs or secrets
are bundled. This release is the preparation/design workshop, not a claim of
finished native production components. Those are the next active stage034/75.

Only the new workshop repository was committed/pushed. Existing local game UI,
art, research and other uncommitted work in game-sdd remain preserved.

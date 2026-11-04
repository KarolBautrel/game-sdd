# Ashen Cartographer — environment samples

Status: APPROVED_VISUAL_FAMILY_BY_USER. Owner: presentation032 and slice032.
The user approved all four samples and requested seeded configurations plus a
reusable English skill. See presentation033 / dungeon047 and the portable source
in `packages/dark-fantasy-ui-workshop/`. Native component production is next.

Open `index.html` locally. It shows all four variants and links each full-size
PNG. The original approved mine is reused unchanged; new samples share its UI.

| File | Environment | Review state |
| --- | --- | --- |
| mine.png | Old Mine: excavation, timber and rubble | APPROVED_STYLE_ANCHOR |
| dungeon.png | Blackbarrow: vaulted halls, flooded cells and crypt | APPROVED_VISUAL_FAMILY_BY_USER |
| castle.png | Ravenkeep: gatehouse, courtyard, chapel and tower | APPROVED_VISUAL_FAMILY_BY_USER |
| forest.png | Crowswood: roots, paths, shrine, camp and barrow | APPROVED_VISUAL_FAMILY_BY_USER |

All four images are approximately 1672x941 concepts (exact sizes in the manifest).
They are not 4K production textures or native
interfaces. The gallery's image links open originals; compare text and detail
there rather than judging only the reduced thumbnails.

## Provenance and review

Tools: game-ui-design/create-game-assets planning, built-in OpenAI imagegen.
Reference: the user's approved Ashen Cartographer mine concept, originally
inspired by Bloodlines' general mood without copying components. No new external
pack graphics or paid files are used. `prompts.json` stores the full common prompt,
variant prompts, final forest prompt and targeted castle correction. The first
castle draft retained the mine seal in one small marker; the final replaces it
with the matching tower. `drafts/castle-v1.png` is retained as generation history.
Manifest records current file dimensions/hashes and approval scopes.

Inspected originals and rendered gallery: consistent shared shell, typography,
supplies, whole portraits, red current/max HP, selected inspector and cost, with
distinct environment architecture/vegetation and identity seals. Seven named
points/six intended route relationships are visible in each. The corrected castle
seal was reviewed. Generated raster detail varies slightly, especially after the
castle edit; production must reuse real shared UI resources and approved portraits.

PNG/manifest/link integrity checks PASS; mine matches approved source exactly.
Local Chrome gallery capture1440x1200was inspected. Evidence:
`artifacts/ui-archetypes-review/review.json` and `gallery.png`. Browser screenshot
arrived asynchronously after its launcher exited; the completed capture was then
verified. This proves gallery presentation, not Godot responsiveness or gameplay.

## Production boundary

The family is approved. Split shared frames/fonts/native controls
from theme-specific substrates, transparent room/POI vignettes, small props and
seals. Map layout, routes, state and labels must be composed from actual dungeon
data, not baked into these pictures. Resource values/light cost are comparison
fixtures; archetype names and points are not new committed campaign content.
Further themes can extend the same visual contract after their own sample review.

No runtime code, default scene, gameplay mechanics, accepted actors or saves were
changed in this sample task. No commit/push or physical gameplay was performed.
Follow-up75 now runs the native Ashen UI. See the actual-engine gallery at
`docs/design/exploration-native/2026-11-04/index.html` and native QA report.
The historical sample task above remains distinct from that implementation.

```powershell
Start-Process "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\docs\design\exploration-archetypes\2026-11-04\index.html"
```

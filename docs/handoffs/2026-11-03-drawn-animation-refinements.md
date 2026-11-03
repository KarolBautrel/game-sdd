# Resume: accepted idle, shield and bow corrections

Active repo game_dir/sdd-game, branch2d-art-research, local/uncommitted. Read
presentation022 / slice022 / milestone017 and stage55. Earlier full batch handoff
retains six-role production history. Preserve all sources and work; no Git task.

Latest user praised the six-role result and requested idle planting, shield
interiors on rear views and a stronger/slower bow draw with aim. All implemented
and supplied through `tools/qa/start_drawn_refinement_preview.ps1`. User explicitly
accepts the corrections ("Tak ma byc") and asks what remains. Only final tests /
records were being completed; do not continue redesigning accepted motion.

96 idle clips (6roles x8views x2states) have fixed lower shins/boots from y232 and
animated upper bodies. Aseprite registration fixes actual per-cell foot drift.
Warrior N/NE/NW shows wooden shield interior, straps/grip. Bow attack in all8views
has stronger draw, cheek anchor/higher elbow, aiming hold, quick release and
follow-through;1800ms total,1260ms release atframe5. New N axial sheet avoids the
unused sideward-aim draft. Original gameplay rules/saves/other art preserved.

Raw sheets/prompts remain in role sources.938 baseline files and hashes preserved
under assets_src/characters/drawn_animation/2026-11-03/refinements/before.
Focused player: refinements/preview.html,125 before/after samples. Source count,
runtime2304frames and source-player2344frames unchanged. Native7368checks/0,
offline3579checks, full regressions and validator PASS. Durable proof in
refinements/verification.json and batch_verification.json; stage55 documents exact
commands and the alpha0 RGB import-comparison correction.

Repeat source exports -> tools/qa/stabilize_drawn_idles.py -> mirror all6profiles
-> package_drawn_roster.py all6 -> build_catalogue.py -> build both players ->
headless tests. Idle stabilization is a required Aseprite post-export step.
Configure generators prefer attack_aim and corrected shield raw sheets; N bow
prefers attack_aim_axial. Main SE bow sheet needs its recorded matte cleanup.

No new task is inferred. Ready for the user's next instruction. Existing61 physical
scenarios and L53-01/L54-01/L54-02 remain NOT_RUN; L55-V01 preview is USER_ACCEPTED.
Desktop remains unreleased: no agent mouse/keyboard or visible app launch. User
may use supplied launch commands. No install/paid provider/commit/push/history work.

# Dwie próbki pozy: z przodu i przy boku

User2026-11-03, presentation021 / slice021 / milestone016, stage51.
Obie próbki są malarskie; A/B tutaj oznacza POZYCJĘ, nie wcześniejsze pixel/painted.

- [comparison.png](comparison.png): **A — miecz wysunięty z przodu** według
  `miecz_z_przodu.jpg`; **B — miecz przy boku** według `pozycja_miecza_bok.jpg`.
- [grips.png](grips.png): zbliżenia obu chwytów i wysokości jelca względem pasa.
- [front.png](front.png) / [side.png](side.png): niezmienione wyniki imagegen.
- [prompts.json](prompts.json): pełne prompty i wyjaśnienie chwytu.

Użytkownik potwierdził, że na bocznej referencji rękojeść jest trzymana OBIEMA
dłońmi; druga jest zasłonięta przez tylne ujęcie. Obie próbki są dwuręczne.

A: ręce dalej przed tułowiem, lekko ugięte łokcie, ostrze ukośnie w górę.
B: łokcie bliżej boku, bardziej ugięte, chwyt przy dolnych żebrach/górnym brzuchu,
ostrze niemal pionowo. W obu jelec jest ponad pasem. Poprzednia niska próbka
stage50 została odrzucona jako zbyt niska; nowa para nie korzysta z jej chwytu.
Zachowano twarz i rodzinę stroju rycerza; przerysowanie ma drobne różnice detalu.

Dwie fotografie są materiałami pozy, nie źródłem nowej twarzy, stroju, tła lub
kamery od tyłu. Kopie JPG w `references/` są identyczne z plikami w workspace root;
hashe są zapisane w [verification.json](verification.json).

Wbudowany imagegen stworzył dwa rysunki. Aseprite1.3.17.2 importuje je, zapisuje
edytowalne płaskie źródła i składa plansze na czerni. Wysokość ciała w porównaniu
jest dopasowana ręcznymi kotwicami włosów/podeszw; to poglądowe próbki pozy, nie
eksporty w docelowej skali gry. Pełna kontrola alfy, odrębna warstwa broni i
animacja pozostają pracą produkcyjną po wyborze pozy.

Źródła Aseprite są w
`assets_src/aseprite/characters/drawn_knight_pose_pair/2026-11-03/`.

```powershell
python tools/qa/build_knight_pose_pair.py
.venv/Scripts/python.exe tools/validators/validate_all.py
```

Builder PASS:8 nowych PNG/źródeł,83 wcześniejsze PNG/źródła zachowane, obie
referencje identyczne. Walidator PASS. Finalne plansze obejrzano. Żadna pozycja
nie jest jeszcze wybrana przez użytkownika; runtime i61 odłożonych testów bez zmian.

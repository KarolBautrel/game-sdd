# Korekta pozy: miecz bardziej z boku

Owner presentation021 / slice021 / milestone016, stage49. Użytkownik przekazał
`C:/Users/karol/Desktop/Gierka/pozycja_miecza.webp` i poprosił o boczne ustawienie
broni. Oba zaakceptowane style pozostają: A pixel art, B malarstwo2D.

- [before_after.png](before_after.png): poprzednia i poprawiona pozycja B, w tej
  samej skali pikseli. Różnicę tworzy położenie obu ramion/dłoni i pionowe ostrze.
- [comparison.png](comparison.png): obie wersje na planszy1x i w powiększeniu3x,
  rękawice6x oraz twarz7x.
- [closeup.png](closeup.png): A natywne piksele4x, B malowane źródło przy tej samej
  ekspozycji; obok obie dłonie i osobna warstwa miecza.
- [board_scale.png](board_scale.png): ziemia i las, skala1x.
- [layer_review.png](layer_review.png): ciało/rękawice bez miecza i oddzielny miecz.

Dłonie są teraz przy bocznej linii barku, po lewej stronie obrazu, wyżej niż
poprzednio. Obie obejmują ten sam długi chwyt; łokcie i przedramiona zostały
przerysowane. Ostrze jest niemal pionowe, obok głowy, z zachowaniem odsłoniętej
twarzy, granatowego stroju, stali, mosiądzu i skórzanych rękawic/butów. Referencja
dostarcza pozy, nie hełmu, zbroi, herbu, szarej rzeźby ani tła.

Referencję skopiowano bez zmian do `references/pozycja_miecza.webp`; jej SHA256
jest w [verification.json](verification.json). To materiał poglądowy użytkownika,
nie grafika postaci do wysłania w runtime gry.

Powstały dwa dopasowane źródła przez wbudowane imagegen. Dwie próbki wydłużenia
ostrza w portretowym kadrze zachowały niepożądaną mgiełkę tła; są tylko w
`raw/drafts/`. Finalne źródła bazują na czystych kwadratowych wersjach bocznej
pozy. [prompts.json](prompts.json) zachowuje cały zestaw promptów i wybór wejść.

Aseprite rozdziela ciało/miecz/rękawice, odtwarza zasłonięty fragment chwytu i
wydłuża teksturę ostrza na jednej prostej osi. Dodaje300px przezroczystego miejsca
u góry źródła, aby uzyskać pełną długość miecza bez ściskania ciała. Pełny master
ma1254x1554px, eksport native280x280, wspólną kotwicę stóp(140,229). Ostrze ma
około80px; dłonie są około26px w bok od kotwicy środka sylwetki. A używa47 kolorów
i binarnej alfy. B zachowuje malarskie przejścia i częściową alfę. Natywne
sylwetki ciała mają165px wysokości, w przybliżeniu tę samą skalę co wcześniej.

Wielokąty i oś broni: [separation.json](separation.json). Źródła trzech warstw
`*_master.aseprite`, `*_native.aseprite` i pięciu plansz są pod
`assets_src/aseprite/characters/drawn_knight_guard_side/2026-11-03/`.
Metadane i stan wyboru: [manifest.json](manifest.json).

```powershell
python tools/qa/build_drawn_knight_guard_side.py
.venv/Scripts/python.exe tools/validators/validate_all.py
```

Cały raster jest obrabiany w Aseprite1.3.17.2. Python uruchamia edytor w tle,
sprawdza parametry plików/raportu i hashe. Zachowano47 wcześniejszych PNG/źródeł
stage47/48. Nowe30 PNG/źródeł obejmuje też odrzucone próbki do dokumentacji;
runtime niczego z tego folderu jeszcze nie używa.

Kompozycje korzystają z aktualnych tekstur i rozmiarów obiektów gry. Nie są
zrzutami rozgrywki. Nowa poza pozostaje do oceny użytkownika; dalsza kolejka to
krótki pilot ruchu, ocena1x i dopiero potem kierunki/akcje oraz integracja.

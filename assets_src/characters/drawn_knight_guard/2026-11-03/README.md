# Rycerz: dwuręczna poza bojowa

Etap1 z uzgodnionej kolejki. Owner presentation021 / slice021 / milestone016.
Użytkownik przyjął oba wykończenia wcześniejszego rycerza jako właściwy kierunek
gry i zlecił kolejne etapy po kolei. Tutaj oceniamy nową pozę gotowości.

- [comparison.png](comparison.png): A pixel / B malarstwo na planszy1x, potem
  natywne piksele3x i zbliżenia obu rękawic/twarzy.
- [closeup.png](closeup.png): pełna sylwetka; A natywne piksele4x, B malowane
  źródło przy tej samej ekspozycji. Obok chwyt i oddzielny miecz.
- [board_scale.png](board_scale.png): oba wykończenia1x na ziemi i w lesie.
- [layer_review.png](layer_review.png): ciało/rękawice po wyłączeniu miecza oraz
  sam sztywny miecz. To dowód rozdzielenia, nie gotowy rig animacyjny.

Zmiana: obie ręce obejmują dłuższy chwyt, prawa pod jelcem, lewa niżej;
ostrze skierowane ukośnie w górę, odsłonięta twarz, rozluźnione łokcie, stopy
lekko przesunięte i kolana miękko ugięte. Ten sam granat, stal, mosiądz i skóra.

Źródła: wbudowane imagegen, dwa wykończenia i jedna iteracja korekty ostrza.
Generator zachował niewielki kąt między ostrzem a rękojeścią; ostateczne
wyrównanie odbywa się deterministycznie w Aseprite. Tekstura namalowanego ostrza
jest przeniesiona na prostą oś wyznaczoną przez jelec i głowicę. Warstwa miecza
ma odtworzony schowany pod dłońmi fragment rękojeści. Ciało za bronią i inne
strony dłoni nie są jeszcze dorysowane do pozostałych póz.

Pełne niezmienione wejścia są w `raw/`, pierwsza iteracja w `raw/drafts/`.
[prompts.json](prompts.json) zapisuje pełne prompty.
[separation.json](separation.json) zawiera jawne wielokąty masek, oś broni i chwyt.
Native280x280 ma wspólną kotwicę stóp(140,229); skalowanie źródła jest jednolite
dla obu wersji, bez dopasowywania do wysokości całej sylwetki z uniesionym mieczem.
Kotwica jest liczona z rzeczywistej wyeksportowanej podeszwy po oczyszczeniu alfy.
Pixel używa47-kolorowej palety poprzedniej propozycji i binarnej alfy.
Painted zachowuje przejścia malarskie i częściową alfę.

Trzy edytowalne warstwy: ciało, sztywny miecz, rękawice na pierwszym planie.
Źródła `*_master.aseprite`, `*_native.aseprite` oraz plansze są w
`assets_src/aseprite/characters/drawn_knight_guard/2026-11-03/`.
Eksporty PNG i źródła mają hashe w [verification.json](verification.json);
[manifest.json](manifest.json) opisuje stan zatwierdzenia i dokładne parametry.

```powershell
python tools/qa/build_drawn_knight_guard.py
.venv/Scripts/python.exe tools/validators/validate_all.py
```

Wszystka obróbka rastra i skład plansz odbywa się w Aseprite; Python tylko
uruchamia aplikację w tle i sprawdza pliki. Zachowano20 wcześniejszych PNG/źródeł
020 bajt w bajt. Plansze wykorzystują obecne tekstury i rozmiary obiektów gry;
są kompozycjami statycznymi, nie zrzutami rozgrywki. Runtime pozostaje bez zmian.

Następny etap kolejki: krótka gotowość/chód/jeden cios w3/4, następnie ocena
ciągłego ruchu1x w skali planszy. Ocena nowej pozy jest osobna od już przyjętego
kierunku artystycznego. Kierunki/pozostałe akcje i integracja jednego rycerza
nastąpią po zaakceptowanej próbie ruchu.61 wcześniejszych testów gry nadal NOT_RUN.

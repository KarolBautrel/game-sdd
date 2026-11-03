# Szybka próbka: jelec przy pasie

User2026-11-03, presentation021 / slice021 / milestone016, stage50.

- [sample.png](sample.png): pojedyncza malowana próbka z obniżonym jelcem na
  wysokości pasa i chwytem przesuniętym lekko w stronę środka talii.
- [before_after.png](before_after.png): poprzedni chwyt przy barku i nowa próbka;
  wysokość ciała dopasowana orientacyjnie, podeszwy na wspólnej linii.
- [native_sample.png](native_sample.png): orientacyjna ekspozycja280x280.
- [prompt.json](prompt.json): pełny prompt wbudowanego imagegen.

Obie ręce przerysowano do niższego chwytu poniżej jelca, ostrze zachowuje pionowe
ustawienie. Źródło to szybki wariant malarski do oceny pozy. Ciało/wyposażenie
mogą mieć drobne różnice rysunkowe; nie jest to gotowy rozwarstwiony sprite
produkcyjny ani animacja. Nie podmieniono stage49 ani żadnego runtime.

Aseprite zapisuje źródło i składa porównanie; edytowalne jedno-warstwowe pliki
są pod `assets_src/aseprite/characters/drawn_knight_waist_sample/2026-11-03/`.
Wysokość włosów do porównania wskazano ręcznie; skala/pivot próbki są orientacyjne.

Reprodukcja: `python tools/qa/build_waist_guard_sample.py`.
Builder PASS,77 poprzednich PNG/źródeł zachowanych; walidator PASS.
Wygląd/poza tej próbki pozostają do oceny użytkownika.

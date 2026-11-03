# Rysowane postacie2.5D: narzędzia, skille i materiały

Sprawdzone2026-11-03. Właściciel: presentation019 / slice019 / milestone014.
To research i propozycja produkcji; nie nowy zestaw postaci ani animacji.

Obecna próba3D została odrzucona przez użytkownika: krzywo wyglądające nogi,
szeroki sztywny chód, obracanie miecza nadgarstkiem oraz słabe dłonie. Techniczne
testy nie mierzyły przekonującego ruchu. Cały stan zachowano na `3d-models`;
teren i UI pozostają bazą. Nowy kierunek ma powstawać z rysunków/sprite'ów.

## Co jest dobrym materiałem odniesienia

- [The Banner Saga — rozmowa z twórcą Alexem Thomasem](https://www.gamedeveloper.com/design/road-to-the-igf-stoic-s-i-the-banner-saga-i-).
  Twórca opisuje malowane ilustracje i ręcznie rysowane klatki animacji, potem
  składane w sprite sheety. To szczególnie trafny przykład taktycznej gry z
  rysowanymi sylwetkami. [Dodatkowa rozmowa z twórcami](https://www.gamereactor.eu/raising-the-banners-stoics-saga/)
  opisuje filmowanie odgrywanego ruchu jako referencji. Przyjmujemy zasadę
  referencji i czytelnych póz, nie kopiujemy ich postaci ani komercyjnych klatek.
- [Vagrus — oficjalny przykład animacji Orc Marauder](https://vagrus.com/news/character-animation-orc-marauder).
  Materiał do obejrzenia: detal rysowanej sylwetki i mroczne fantasy. Jest to
  referencja prezentacji postaci, nie dowód zgodności kamery/techniki z naszą grą.
- [Obsidian — opis renderowania Pillars](https://eternity.obsidian.net/eternity/news/update--79-graphics-and-rendering-).
  Ważne rozróżnienie: opisany pipeline łączy tła2D z postaciami3D. Nazwa gry i
  izometryczny wygląd nie dowodzą, że bohatera narysowano klatka po klatce.
  Z Pillars/BG bierzemy oczekiwanie czytelnej ekspozycji i spójnego świata;
  docelowy sposób tworzenia naszych postaci ma być rysowany. Nie ustalono tu
  kompletnej historii produkcji wszystkich grafik BG1/2 ani Deadfire.

## Najbardziej przydatne narzędzia

| Narzędzie | Zastosowanie w tym projekcie | Sprawdzona dostępność / ograniczenie |
| --- | --- | --- |
| [PixelLab MCP](https://www.pixellab.ai/mcp) | Pixelowe postacie, warianty widoków i krótkie akcje | Oficjalny MCP i wtyczka Aseprite istnieją. Brak podłączonego konta/klucza w tej sesji; generowanie rozliczane kredytami. |
| [AutoSprite MCP](https://www.autosprite.io/docs/mcp) | Animowanie gotowej ilustracji, pozy, kierunki i eksport arkuszy | Udokumentowany tryb animacji z rysunku oraz osobne funkcje3D. Do wypróbowania wybieramy2D; usługi nie uruchomiono. |
| [Retro Diffusion MCP](https://github.com/Retro-Diffusion/retro-diffusion-mcp) | Alternatywny generator pixel artu i animacji | Oficjalny zdalny serwer, konto/API key i saldo. Jakość dla naszego rycerza nieprzetestowana. |
| [SPA — Aseprite Automation](https://github.com/aigengame/aseprite-automation) | Warstwy, klatki, kotwice, kontrola i eksport edytowalnego .aseprite | Osobny skill `spa`, CLI i opcjonalny MCP. Wymaga Python3.13+ i Aseprite; repo używa obecnie Python3.12. Nie zainstalowano. |
| [Aseprite MCP / MalloyTheDev](https://github.com/MalloyTheDev/aseprite-mcp) | Edycja/analiza klatek i palety w tle, eksport | Community MIT, deklaruje Python3.10+, więc pasuje do obecnego3.12. README/manifest przeczytane; serwera nie uruchomiono. |
| [Spine2D](https://en.esotericsoftware.com/spine-purchase) | Kości2D, zamienne części i przygotowanie wariantów stroju | Komercyjny edytor; funkcje mesh należą do Professional. Nie jest generatorem ilustracji i nie wymusza naturalnego ciosu. |
| [Krita](https://docs.krita.org/en/user_manual/animation.html) | Malowane klatki kluczowe, poprawki i onion skin | Dokumentacja potwierdza rastrową animację klatka po klatce; przy większych sekwencjach trzeba uwzględnić RAM. Nowej instalacji nie wykonano. |

### PixelLab: konkretne dopasowanie

[Pełna dokumentacja MCP](https://api.pixellab.ai/mcp/docs) rozróżnia tworzenie
postaci od animowania jej. Tryb `create_character` v3 obsługuje rysunki do256px
i4/8 kierunków; dostępne są także opcje kamery z lekkim widokiem z góry. Inne
tryby mają inne limity. Nie należy utożsamiać maksymalnego rozmiaru statycznej
postaci z dowolnie tanią/szybką animacją. Koszt rośnie z polem klatki, liczbą
klatek i kierunków. Gotowe animacje mają określone długości; cios mieczem wymaga
sprawdzenia odpowiedniego trybu/akcji, nie wymyślenia nazwy szablonu.

Dokumentacja ostrzega też, że referencja kierunku south ma być skierowana prosto
do widza. Wysłanie widoku3/4 jako frontu błędnie obróci oznaczenia całego zestawu.
Dlatego nasz zatwierdzony rysunek3/4 trzeba uzupełnić prawidłową referencją
przednią, a nie bezmyślnie przesłać go do rotacji. To dobry kandydat do prób
pixelowego dark fantasy; jakość dopiero wykaże próbka z naszym bohaterem.

[Sposoby użycia PixelLab](https://www.pixellab.ai/docs/ways-to-use-pixellab)
potwierdzają interfejs Aseprite oraz MCP. Nie znaleziono go w obecnie podłączonym
zestawie narzędzi; nie oznacza to, że nie istnieje jako zewnętrzny MCP.

### AutoSprite: szczegółowa ilustracja jako wejście

[Dokumentacja MCP](https://www.autosprite.io/docs/mcp) opisuje import własnego
rysunku, tworzenie póz i arkuszy, pakiety izometryczne oraz osobne narzędzia3D.
Ostatnich nie potrzebujemy. Istotna pułapka: dedykowane `generate_attack_moves`
dotyczy widoku bocznego; nie zakładamy, że dostarczy poprawny atak izometryczny.
Do niego trzeba sprawdzić właściwy pakiet i nasze pozy. [FAQ](https://www.autosprite.io/docs/faq)
zaleca odpowiednio duży obraz wejściowy i opisuje eksport w większej
rozdzielczości oraz edycję klatek. To czyni narzędzie kandydatem dla mniej
pixelowej, bardziej malowanej postaci; jest to ocena dopasowania, nie wynik testu.

[Opis animacji](https://www.autosprite.io/docs/reference-animation-types)
udostępnia przykłady i opcje ruchu na bazie referencji/klatek kluczowych. Długość
filmu oraz liczba eksportowanych klatek są oddzielne: rozciągnięcie tej samej
liczby obrazków na dłuższy czas nie poprawia płynności. Obietnice serwisu trzeba
zweryfikować na pętli w docelowej skali, szczególnie na stopach i sztywnym mieczu.

### Aseprite: kontrola końcowego rezultatu

Aseprite1.3.17.2 i nasz batch/Lua są już dostępne. Nowy MCP nie jest warunkiem
zrobienia grafiki. Może uprościć sterowanie, ale nie zastąpi dobrego rysunku.

SPA ma wyjątkowo trafny [przykład Wizard v2](https://github.com/aigengame/aseprite-automation/tree/main/examples/wizard_cast_v2):
grafika i pozy z imagegen, edytowalne źródła Aseprite oraz przykład Godota.
To dowód istnienia przykładowego workflow, nie test naszej postaci. Naszą adaptację
wykonamy z zachowaniem repozytoryjnej zasady edycji rastra w Aseprite; nie kopiujemy
automatycznie wszystkich użytych tam kroków obróbki obrazów.

Alternatywny MCP MalloyTheDev deklaruje m.in. porównania klatek, pomiary pętli,
palety i ekspozycji. Takie metryki są przydatne do wykrywania usterek technicznych;
nie powtarzamy błędu uznawania ich za dowód poprawnej anatomii lub naturalnego ruchu.

## Skille, które faktycznie znaleziono

1. [scenario-sprite-animation — SKILL.md](https://github.com/scenario-labs/skills/blob/main/skills/scenario-sprite-animation/SKILL.md):
   specjalizowany workflow dla cykli, kierunków, sprite sheetów i pracy z pozami.
   Wymaga ekosystemu Scenario do opisanych zdalnych operacji. Przeczytany jako
   źródło do oceny; nie zainstalowany ani wykonany. Nasz zainstalowany pakiet
   Scenario Blender nie oznacza obecności tego konkretnego skilla/usługi.
2. [spa — SKILL.md](https://github.com/aigengame/aseprite-automation/blob/main/skills/spa/SKILL.md):
   agentowe sterowanie Aseprite, odkrywanie schematów, inspekcja i eksport.
   Skill nie instaluje aplikacji/CLI. Dobry kandydat do dodania przy wybranej ścieżce.
3. Już dostępne: `imagegen`, `create-game-assets`, `godot-animation`. Generowanie
   obrazu może dać wygląd oraz klatki kluczowe; kompletna animacja nadal wymaga
   kontroli sekwencji. Nie zrobiono tu nowego obrazu ani animacji.

Oficjalny [katalog curated OpenAI](https://github.com/openai/skills/tree/main/skills/.curated)
sprawdzono przez GitHub API; nie znaleziono tam specjalizowanego pakietu do
animowania naszych izometrycznych sprite'ów. Helper instalatora napotkał lokalny
błąd certyfikatu Pythona; odczyt katalogu przez systemowy HTTPS się powiódł bez
wyłączania TLS. Katalog pluginów zwrócił m.in. ogólne narzędzia wideo, nie
PixelLab/Aseprite. Nie rekomendowano ani nie podłączono zbędnych usług.

## Proponowany najbliższy pilot

Moja rekomendacja: źródłowy rysunek dark fantasy, Aseprite jako kontrolowany etap
końcowy; PixelLab do próby pixelowej albo AutoSprite/Scenario do próby malowanej.
Spine pozostawić jako opcję dla rozbudowanych wariantów wyposażenia. [Runtime
Spine dla Godota](https://en.esotericsoftware.com/spine-godot) istnieje, ale nasz
obecny renderer już przyjmuje raster i nie wymaga jego wdrażania do pierwszej próby.

1. Jeden rycerz w dwóch wykończeniach: szczegółowy pixel art i malarstwo2D.
   Proste nogi w spokojnej postawie, rękawice, czytelna bryła zbroi i osobny miecz.
   Wygląd sprawdzamy na planszy i w zbliżeniu przed produkcją całego zestawu.
2. Jedno wybrane wykończenie:8–12 klatek chodu i krótki cios z zaplanowanymi
   pozami zamach -> kontakt -> wyhamowanie -> powrót. Liczba klatek i czas muszą
   wynikać z rzeczywistej próbki i metody, nie sztywnej obietnicy generatora.
3. Cios prowadzony nogami/biodrami, tułowiem i ramieniem. Ostrze zachowuje kształt;
   warstwa rękawicy trzyma rękojeść. Krytyczne pozy rysujemy poprawnie zamiast
   maskować zły ruch samą interpolacją lub obrotem całej wycinanki.
4. Przegląd co najmniej trzech pełnych cykli na1x i w docelowej skali, potem
   inspekcja klatek. Ocena ruchu jest bramką przed8 kierunkami i pełną obsadą.

Duży obraz źródłowy pomaga w rysowaniu, lecz na planszy nie pokaże szczegółów,
które fizycznie nie mieszczą się w ekranowych pikselach. Obecny kontrakt ma
100px/metr i kamerę18stopni. Sprawdzamy twarz/zbroję przy tej ekspozycji; osobne
portrety nadal służą do detalu twarzy. Nie zmieniamy teraz skali świata/rendererów.

Nie instalowano nowych narzędzi, nie kupiono dostępu i nie wygenerowano płatnych
assetów. Żaden generator nie jest tu uznany za przetestowany produkcyjnie.61
testów właściwej gry pozostaje NOT_RUN, kontrola pulpitu nadal nieoddana.

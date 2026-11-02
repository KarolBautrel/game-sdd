# UI do gry research i plan poprawy

Data: 2026-11-02. Zakres: internetowy przegląd referencji, materiałów, generatorów,
skilli i MCP oraz porównanie z obecną implementacją. To propozycja dalszej pracy,
nie nowa specyfikacja zachowania ani zakończony etap implementacji.

Użytkownik odrzucił obecny wygląd interfejsu. Techniczne wyniki etapów 20–22
pozostają dowodami funkcjonalnymi; nie stanowią akceptacji wizualnej. Nadal
obowiązuje rejestr 30 odroczonych prób w [live-test-scenarios.md](live-test-scenarios.md).

## Najważniejszy wniosek

Największa luka to brak ustalonego wzorca wizualnego całego ekranu, spójnego zestawu
grafik i regularnego porównywania tego wzorca z prawdziwym obrazem gry. Kolejne
zmiany kontenerów, kolorów i liczników same tego nie rozwiążą. Dotychczasowa praca
rozwinęła przede wszystkim działający układ. Było zbyt mało projektowania obrazu
przed rozszerzeniem go na wszystkie ekrany.

W repozytorium są już narzędzia wystarczające do rozpoczęcia poprawy. Nowe usługi
mogą przyspieszyć tworzenie grafik lub obserwację gry, ale ich przydatność trzeba
potwierdzić na jednym ekranie.

## Co konkretnie wymaga poprawy u nas

Poniższe uwagi wynikają z kodu oraz istniejącej rekonstrukcji
`artifacts/qa-runs/stage22-design-stash.png`. Rekonstrukcja nie jest zrzutem
uruchomionej gry i nie potwierdza jej faktycznego renderowania.

| Obserwacja | Dowód w projekcie | Konsekwencja projektowa |
| --- | --- | --- |
| Większość okien i przycisków korzysta z podobnych płaskich prostokątów | `scripts/presentation/world/campaign_skin.gd`, `box()` i `theme()` | Słaba różnica między tłem, wyposażeniem, informacją i główną akcją |
| Jedna ozdobna ramka konkuruje z pozostałym, prostym interfejsem | `hero_frame()` wykorzystuje istniejące `dungeon_ui_10.png` | Ornament nie tworzy jeszcze wspólnego języka całego UI |
| Ikony oznaczają kategorię, a nie konkretny przedmiot | `scripts/presentation/world/item_presentation.gd:icon_for()` | Klucz i łup dostają torbę, a pancerz ikonę tarczy; rozpoznawanie wymaga czytania |
| Typografia polega m.in. na systemowym `Georgia/Noto Serif/serif` | `campaign_skin.gd:heading_font()` | Wygląd nagłówków może zależeć od komputera; brakuje dołączonej rodziny fontów |
| Nazwy i ilości na kafelkach mają rozmiary 17/16 jednostek UI | `scripts/presentation/world/item_grid.gd` | Wymagają oceny w rzeczywistym rozmiarze okna, a nie tylko sprawdzenia prostokątów |
| Duże powierzchnie i małe ilustracje nie budują centrum kompozycji | Rekonstrukcja ekwipunku | Zawartość wygląda jak formularz; przedmioty i bohater powinni prowadzić wzrok |

Przy referencji 2560×1440 i oknie 1920×1080 skala wynosi 0,75. Nominalne 17 jednostek
tekstu daje 12,75 piksela przed uwzględnieniem szczegółów renderowania i DPI. To
sygnał do pomiaru, nie pomiar faktycznej wysokości glifów. Microsoft XAG101 jako
punkt odniesienia dla PC podaje 18px wysokości korpusu tekstu przy 1080p i zaleca
możliwość powiększania. [Microsoft XAG101](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101).

## Referencje i materiały do obejrzenia

### Battle Brothers

Najbliższa referencja dla najemniczego, średniowiecznego charakteru projektu.
Twórcy opisują wspólne wykorzystanie drewna, metalu i papieru w dialogach,
przyciskach, tooltipach oraz celach zleceń. Warto przejąć zasadę materiałów i
czytelnych funkcji, a następnie opracować własne grafiki.
[Dev Blog74](https://battlebrothersgame.com/dev-blog-74-progress-update-reworked-ui/),
[Dev Blog75](https://battlebrothersgame.com/dev-blog-75-progress-update-reworked-ui/).

Obejrzana próbka: [opis przedmiotu i cel zlecenia](https://battlebrothersgame.com/wp-content/uploads/2016/05/scrolls-inventory.jpg).
Moja ocena: karta ma wyraźny tytuł, obraz przedmiotu, parametry i działanie;
materiał panelu pomaga odróżnić ją od świata. To wartościowsza wskazówka dla nas
niż samo dodanie złotej obwódki.

### Stoneshard

[Ekran wyposażenia w oficjalnej wiki](https://stoneshard.com/wiki/File:Inventory_2.png)
pokazuje układ slotów i wyposażenia. Plik pochodzi z 2021 roku; traktować go jako
historyczny przykład kompozycji, nie potwierdzenie wyglądu aktualnego wydania.
[Strona gry z materiałami wydawcy](https://store.steampowered.com/app/625960/Stoneshard/).

Proponowany użytek: czytelne sylwetki przedmiotów, zwarte sloty i wyraźne miejsca
na wyposażenie. Nasze trzy sloty nie wymagają kopiowania rozbudowanego systemu
ekwipunku innej gry.

### Kolekcje oraz proces projektowy

- [Interface In Game](https://interfaceingame.com/) pozwala przeglądać interfejsy
  według gatunku i elementu, m.in. ekwipunku, mapy oraz sklepu. Przydatne do zebrania
  konkretnych ekranów pełniących tę samą funkcję.
- [Game UI Database](https://www.gameuidatabase.com/) jest dodatkowym adresem do
  ręcznego przeglądu. Automatyczny odczyt strony został zablokowany przez robots.txt;
  nie opieram na niej szczegółowych ustaleń tego raportu.
- [Asmodee Art Direction and User Interface](https://doc.asmodee.net/art-and-ui)
  opisuje powiązanie kierunku artystycznego z ekranami wzorcowymi, układem,
  biblioteką elementów i prototypowaniem. Dla nas istotne jest ustalenie wyglądu
  przed rozprzestrzenieniem go na wszystkie widoki.
- [GDC Art Direction for AAA UI](https://www.gdcvault.com/play/1025498/Art-Direction-for-AAA)
  to materiał Omera Younasa z DICE LA o spójności oprawy UI. Zweryfikowano stronę
  sesji i jej zakres; nagranie nie było oglądane w ramach tego researchu.

Zrzuty innych gier są referencjami kompozycji. Nie są zestawami grafik do importu.

## Generatory i narzędzia

Możliwości usług poniżej są potwierdzone ich dokumentacją, ale nie lokalną próbą
generowania i importu do tej gry. Próbki na stronach autorów pozostają materiałami
demonstracyjnymi. Żadna nowa usługa nie została zainstalowana ani połączona.

| Narzędzie | Co wnosi | Ocena dla tego projektu |
| --- | --- | --- |
| SpriteLab UI Kit | `generate_ui_kit` i `check_ui_kit`; autor dokumentuje cięcie elementów, stany, marginesy9-slice i eksport motywu Godot4 oraz scen przycisków | Pierwszy kandydat do małej próby całego zestawu. Funkcja jest early access; trzeba obejrzeć rzeczywisty eksport i jego marginesy, a nie uznać podgląd za gotowy interfejs |
| PixelLab MCP | `create_ui_asset`, referencja stylu, ograniczenie palety, szablony kształtów i przezroczyste tło | Dobry kandydat dla pixel artu. Dokumentacja tego narzędzia opisuje generowanie grafiki; nie potwierdza automatycznego złożenia naszego ekranu Godota |
| Dostępne generowanie obrazów | Koncepcje całych ekranów, ilustracje, materiały i warianty stylistyczne | Można zacząć bez podłączania kolejnej usługi. Końcowe elementy pixel art wymagają przygotowania w naszym procesie Aseprite |
| Figma MCP | Edytowalne ekrany, komponenty, zmienne, obrazy referencyjne i eksport zasobów | Narzędzia Figma są już dostępne w tej sesji. Przydatne do ustalenia proporcji, typografii i stanów; implementacja w Godocie nadal jest osobną pracą |
| Recraft remote MCP | Raster i wektory, edycja, wektoryzacja, własne style z referencji | Opcja dla spójnych symboli i ilustracji wektorowych. Mniejszy priorytet przy obecnym pixel arcie |
| Ludo.ai | Grafiki UI, przezroczyste elementy, warianty przez edycję, sprite sheety; CLI i MCP | Alternatywa do próby zestawu grafik. Autor udostępnia demonstrację HUD w Godot4; nie potwierdzono importu do naszego projektu |
| ThemeGen | Wielokrotne użycie stylów i kolorów w GDScript oraz podgląd zmian w edytorze | Pomaga utrzymać wybrany styl. Obecny `CampaignSkin` już centralizuje część tych ustawień; nowa abstrakcja nie jest pierwszą potrzebą |
| Aseprite CLI lub MCP | Skrypty Lua, edytowalne źródła, eksport PNG i danych atlasu, oglądanie i poprawianie wyniku | Zgodne z repozytorium. CLI już pozwala pracować bez otwierania okna, więc MCP jest opcjonalnym usprawnieniem |

Źródła do powyższego zestawienia:
[SpriteLab UI Kit](https://spritelab.dev/game-ui-generator),
[SpriteLab MCP](https://spritelab.dev/docs/mcp),
[PixelLab MCP tools](https://api.pixellab.ai/mcp/docs),
[PixelLab sposoby użycia](https://www.pixellab.ai/docs/ways-to-use-pixellab),
[Figma MCP tools](https://developers.figma.com/docs/figma-mcp-server/tools-and-prompts/),
[Recraft remote MCP](https://www.recraft.ai/docs/mcp-reference/remote-server),
[Ludo Game UI](https://ludo.ai/tools/game-ui-generator),
[ThemeGen](https://github.com/Inspiaaa/ThemeGen),
[Aseprite CLI](https://www.aseprite.org/docs/cli/),
[mattt Aseprite MCP](https://github.com/mattt/aseprite-mcp).

Ważne ograniczenia przy wyborze usługi:

- SpriteLab deklaruje możliwość próby UI Kit na darmowym planie aplikacji.
  Dokumentacja MCP opisuje osobno kredyty API; nie należy zakładać, że dzienne
  darmowe kredyty aplikacji mają identyczne zastosowanie w MCP. Według
  [regulaminu](https://spritelab.dev/terms) wyniki darmowego planu są publiczne;
  płatnego domyślnie prywatne. Nie wysyłać całego repozytorium do takiej próby.
- PixelLab wymaga konta, tokenu i według dokumentacji aktywnej subskrypcji do MCP.
  Koszt konkretnego wygenerowania należy sprawdzić przed próbą.
- [Stary lokalny Recraft MCP](https://github.com/recraft-ai/mcp-recraft-server)
  jest oznaczony przez autora jako deprecated. W razie wyboru Recraft użyć
  aktualnego serwera zdalnego, nie starego poradnika instalacji.
- Figma domyślnie zwraca kontekst React/Tailwind. W naszym procesie służy do
  projektu i zasobów; kod trzeba dostosować do Control/Theme w Godocie.
- [Google Stitch](https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-updates/)
  może pomóc porównywać koncepcje, lecz opisana ścieżka produkcyjna dotyczy
  narzędzi aplikacyjnych i publikacji web. Nie potwierdzono natywnego eksportu
  scen Godota. Przy dostępnej Figmie ma niższy priorytet.

Obejrzane materiały SpriteLab:
[ekwipunek dark fantasy](https://spritelab.dev/static/showcase/uikit/style-dark-fantasy-inventory.jpg)
i [mapa na pergaminie](https://spritelab.dev/static/showcase/uikit/style-world-map.jpg).
Moja ocena: pokazują wyraźną hierarchię ilustracji, slotów i szczegółów. Pierwszy
przykład jest w estetyce HD i ma bardzo drobne napisy; nie jest gotowym wzorcem
czytelności ani dowodem, że wygenerowany zestaw pasuje do naszej gry.

## Gotowe grafiki i próbki

| Materiał | Deklaracja autora | Przydatność |
| --- | --- | --- |
| [Kenney Fantasy UI Borders](https://kenney.nl/assets/fantasy-ui-borders) |140 plików, CC0| Dobra mała próbka spójnych obramowań i ornamentów. Obejrzano przykładową kompozycję; styl jest prostszy od naszego portretu |
| [Kenney Pixel UI Pack](https://kenney.nl/assets/pixel-ui-pack) |750 plików, CC0| Baza paneli i przycisków do pixel artu; potrzebuje własnego kierunku i dopasowania |
| [Shikashi Fantasy Icons](https://shikashipx.itch.io/shikashis-fantasy-icons-pack) |284 ikony32×32; strona oznacza CC BY4.0 i prosi o podanie Matt Firth oraz game-icons.net| Konkretne bronie, pancerze, żywność i klucze zamiast wspólnej torby/tarczy; paleta wymaga dopasowania |
| [Game-icons.net](https://game-icons.net/about.html) |Strona zbiorcza wskazuje CC BY3.0 i kredyt autora| Symbole akcji, parametrów i kategorii. Nie mieszanie wielu stylów przedmiotów; przy wyborze zachować dane konkretnych ikon |
| [CraftPix Fantasy RPG GUI](https://craftpix.net/product/fantasy-rpg-gui/) |Płatny zestaw PSD i przezroczystych PNG; osobna licencja dostawcy| Przykład kompletnej rodziny ekranów. Estetyka bardziej mobilnego/MMO fantasy, więc mniejszy priorytet dla naszego kierunku |

CraftPix opisuje zastosowania i ograniczenia w
[licencji plików](https://craftpix.net/file-licenses/). Do przyszłego importu
zapisać stronę konkretnego zestawu, autora, plik licencji i wymagany kredyt.
W tej sesji niczego nie kupowano ani nie importowano do zasobów gry.

## Skille

Skille opisują sposób pracy, a MCP daje dostęp do narzędzi. Sam dodatkowy plik
instrukcji nie dostarcza rodziny grafik ani ustalonej kompozycji.
[Oficjalna dokumentacja skilli](https://learn.chatgpt.com/docs/build-skills),
[MCP w Codex](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

Już dostępne lokalnie: `create-game-assets`, `game-development-rendering`,
`godot-gamedev`, `godot-gdscript`, `imagegen` i skille Figma. Najbardziej istotny
jest obowiązek jednego celu wizualnego i obejrzenia wyniku w silniku zapisany
w `create-game-assets`. Trzeba stosować ten proces konsekwentnie.

Kandydaci do ewentualnego dołożenia:

- [game-ui-ux](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-ui-ux/SKILL.md):
  skala, focus, przepływ ekranów i aktualizacje przez zdarzenia. Nie znaleziono go
  w lokalnym katalogu skilli. Przydatny jako kontrola użyteczności.
- [godot-ui-control](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-ui-control/SKILL.md):
  Control, kontenery, Theme i nawigacja; autor wskazuje Godot4.7. Także nieobecny
  lokalnie. Uzupełnia implementację, ale nie zastępuje projektu graficznego.
- [Anthropic frontend-design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md):
  przydatne zasady świadomej typografii, kompozycji i krytyki wyniku. Część treści
  dotyczy stron internetowych; stosować selektywnie do kierunku wizualnego gry.

Rekomendacja: do projektu zapisać konkretny wzorzec, rodzinę elementów i kryteria
oględzin. Dwa wyspecjalizowane skille można dodać pomocniczo. Instalacja dużego
pakietu przypadkowych skilli nie daje dowodu lepszej jakości.

## MCP do obserwacji Godota

W aktualnym zestawie narzędzi sesji nie ma Godot MCP, PixelLab, SpriteLab,
Recraft ani Aseprite MCP. Narzędzia Figma są dostępne. Przegląd katalogu pluginów
nie ujawnił gotowej integracji Godota do bezpośredniego użycia w tej sesji;
zewnętrzne repozytoria poniżej wymagają oddzielnej konfiguracji.

| Projekt | Potwierdzony zakres w źródle | Wniosek |
| --- | --- | --- |
| [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) |Uruchamianie, logi, operacje na scenach i zasobach| README nie dokumentuje wymaganej przez nas pełnej pętli wejście→obraz działającej gry |
| [Vollkorn-Games/godot-mcp](https://github.com/Vollkorn-Games/godot-mcp) |`run_interactive`, wejście, viewport screenshot, stan, sekwencje, logi; czasowy autoload| Najbardziej konkretny kandydat do małego pilota obserwacji i wejścia wewnątrz silnika |
| [IvanMurzak/Godot-MCP](https://github.com/IvanMurzak/Godot-MCP) |Addon edytora oparty na C#/.NET; screenshoty i operacje na edytorze| Wymaga oceny dodatkowego stosu .NET; nasz projekt używa standardowego Godota i GDScript, więc niższy priorytet |

Sprawdzono również kod
[input_receiver.gd przypięty do odczytanego commitu](https://github.com/Vollkorn-Games/godot-mcp/blob/632530638448ea3e79394fbf74e9a5c92c4b67e5/src/scripts/input_receiver.gd).
Wejście myszy jest przekazywane do viewportu, klawiatura do Input, a obraz
pobierany z tekstury viewportu. To podstawa do hipotezy, że część prób można
wykonywać bez poruszania systemowym kursorem. Nie jest to lokalny test braku
kradzieży focusu ani gwarancja swobodnego grania użytkownika równolegle.

Pilot powinien działać na kopii testowej z oddzielnym zapisem: sprawdzić Godot4.7,
rzeczywisty obraz GPU, klikanie i klawiaturę bez aktywowania okna użytkownika,
zachowanie fizycznego wejścia oraz sprzątanie tymczasowego autoloadu i zmian
`project.godot`. Zwykły headless test geometrii nie jest takim dowodem. Do czasu
osobnego ustalenia nadal obowiązuje zakaz przejmowania pulpitu podczas pracy
użytkownika i odroczenie natywnych testów.

## Zalecany kierunek wizualny

Propozycja do sprawdzenia: surowy ekwipunek kompanii najemników. Ciemny materiał
pod ilustracje, spokojny papier pod opis, oszczędne metalowe krawędzie, mocne
sylwetki przedmiotów i jeden wyraźny stan wyboru. Własny pixel art dopasowany do
istniejących portretów. Battle Brothers jako referencja materiałów, Stoneshard
jako referencja zwartego wyposażenia.

Na ekranie ekwipunku najpierw widać bohatera i założone przedmioty, następnie
zawartość sakwy/skrzyni, a potem porównanie i działanie. Przy siedmiu stosach
przedmiotów nie wypełniać ekranu fikcyjnym łupem, aby imitował bogaty screenshot.
Kompozycja ma działać z rzeczywistą zawartością naszej gry.

Godot ma do tego potrzebne mechanizmy:
[Theme i skinning](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_skinning.html),
[StyleBoxTexture i9-slice](https://docs.godotengine.org/en/4.7/classes/class_styleboxtexture.html),
[fonty i skalowanie pixel artu](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_using_fonts.html).
Tekst i interakcje pozostają natywne. Grafika wnosi materiał, ilustracje i ramy.

## Kolejność następnej pracy

1. Przygotować trzy wyraźnie różne pełne propozycje tego samego ekranu ekwipunku
   z naszymi bohaterami, siedmioma stosami, trzema slotami i prawdziwymi opisami.
   Warianty: wyposażenie najemników, surowa kamienna rama, atlas/księga wypraw.
   Każdy pokazać w docelowym1920×1080. Rekomendowany punkt startu: pierwszy.
2. Wybrać jeden kierunek wizualny na podstawie wyglądu. Zapisać ekran wzorcowy,
   fonty, paletę, skale ikon i zasady materiałów. Dopiero stąd wyprowadzić zmiany
   właścicielskiej specyfikacji prezentacji i scenariusza akceptacji.
3. Wypróbować jeden sposób dostarczenia grafik: własny zestaw na podstawie
   wybranego konceptu albo mały eksport SpriteLab. PixelLab jest alternatywą
   przy potrzebie większej kontroli pixel artu. Nie podłączać wszystkich usług.
4. Przygotować kompletną małą rodzinę: ramy, przycisk, slot, tooltip, portret,
   znaczniki wyboru/focusu i osobne ikony wszystkich istniejących przedmiotów.
   Stany: normalny, hover, pressed, selected, disabled oraz focus. Fonty z polskimi
   znakami i licencją. Pixel art prowadzić przez Aseprite zgodnie z `agents/README.md`.
5. Wdrożyć wyłącznie ekran ekwipunku jako pierwszy przekrój. Uruchomić scenariusze
   funkcjonalne oraz zobaczyć prawdziwy obraz gry. Poprawiać różnice względem
   wybranego wzorca, zanim ten styl trafi do handlu, treningu, miasta i mapy.
6. Po akceptacji tego ekranu rozszerzyć rodzinę na pozostałe widoki i wykonać
   odroczone scenariusze. Utrzymać normalny spec→slice→implementacja→dowód→raport.

To kolejność proponowana do następnego zlecenia. Obecna prośba dotyczy researchu;
nie uruchamia ona automatycznie nowej przebudowy interfejsu.

## Próby akceptacyjne nowej oprawy

| Próba | Wynik wymagany | Obecny stan |
| --- | --- | --- |
| V01 ekran wzorcowy | Wybrany wygląd całej kompozycji, nie tylko paleta lub pojedyncza ramka | Nie wykonano |
| V02 grafiki przedmiotów | Każdy aktualny przedmiot rozpoznawalny; pancerz, klucz i łup mają właściwe ilustracje | Nie wykonano |
| V03 czytelność | Prawdziwy screenshot1080p; pełne nazwy/dane dostępne, czytelne glify i liczby | Nie wykonano |
| V04 skala | Okno1920×1080 na większym lewym DISPLAY1, dodatkowo1440p i docelowe skalowanie4K; bez zniekształceń ramek | Nie wykonano |
| V05 stany i focus | Hover, kliknięcie, blokada, wybór oraz klawiatura widoczne i rozróżnialne, niezależnie od koloru | Nie wykonano |
| V06 działanie | Filtry, zmiana bohatera, porównanie, założenie/zdjęcie i odświeżenie danych zachowują reguły kampanii | Nie wykonano |
| V07 ewentualny pilot MCP | Zrzut rzeczywistego renderu i wejście do testowej gry bez przejęcia urządzeń użytkownika; potwierdzona zgodność i sprzątanie | Nie wykonano |
| V08 wydanie | Wygląd i scenariusze potwierdzone także w finalnym EXE, po zamknięciu sprawdzone logi | Nie wykonano |

Nie zastępować tych prób dodatkowymi tysiącami asercji geometrii. Testy
automatyczne nadal chronią zachowanie. Ocena oprawy wymaga oględzin i akceptacji
wizualnej. Nie zmieniono statusu istniejących prób L8..L22.

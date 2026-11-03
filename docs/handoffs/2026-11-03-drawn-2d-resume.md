# Wznowienie pracy: rysowane postacie2.5D

Zamknięcie sesji2026-11-03. Użytkownik kończy pracę na dziś i chce jutro wrócić
poleceniem **„Wracamy do tego na czym skończyliśmy ostatnio”**. Ten plik ma
odtworzyć kontekst bez ponownego wypytywania o całą historię projektu.

## Gdzie pracujemy i od czego zacząć

- Aktywne repo: `C:/Users/karol/Desktop/Gierka/game_dir/sdd-game`.
  Folder `C:/Users/karol/Desktop/Gierka` jest tylko wejściem do workspace.
- Branch do dalszej pracy: **`2d-art-research`**. Sprawdź aktualny HEAD/status;
  nie przełączaj się automatycznie na master ani na archiwum3D.
- Przeczytaj `AGENTS.md`, początek `docs/CONTINUE_HERE.md`, ten plik, potem
  presentation019 / slice019 / milestone014 i wskazany poniżej research.
- Na wznowieniu podaj krótkie przypomnienie: odrzucona próba3D jest zachowana,
  kierunek to rysowane postacie2D na taktycznej planszy, następny etap to mała
  próba wyglądu. Nie zaczynaj od ponownego szerokiego researchu lub przeróbki nóg3D.
- Odróżniaj proponowane następne etapy od już wykonanej pracy. Poniższe propozycje
  nie oznaczają, że nowe grafiki/animacje powstały ani że generator został podłączony.

## Decyzje użytkownika, których nie wolno zgubić

1. Użytkownik **odrzucił animowany pilot3D**: nogi wyglądają krzywo, chód jest
   szeroki/sztywny, cios przypomina obracanie miecza nadgarstkiem, dłonie są słabe.
   Chce rękawice, naturalną anatomię/chód i prawdziwy ruch ciosu całym ciałem.
2. Nie kontynuujemy naprawiania tej próby w Blenderze ani pełnej obsady3D.
   Zachowujemy źródła jako archiwum, bez usuwania poprzedniej pracy.
3. Nowy kierunek: **rysowane/malowane lub szczegółowe pixelowe postacie2.5D**.
   Inspiracje wizualne użytkownika: BG1/2, Pillars2; ważne są czytelne zbroje,
   twarze i sylwetki w rzucie taktycznym. Użytkownik pamięta dobre pixelowe sprite'y
   generowane przez ChatGPT i chce wykorzystać narzędzia/AI do takiego wyglądu.
4. Aktualne otoczenie, podłoga i UI pozostają bazą. Zmiana sposobu tworzenia
   postaci nie wymaga automatycznie zmiany silnika lub całego renderera.
5. Techniczny PASS nie jest zgodą użytkownika na wygląd. Nowy kierunek trzeba
   pokazać w docelowej skali i obejrzeć w ruchu przy normalnej prędkości.

## Co zostało wykonane

- Pełny wcześniejszy stan, także poprzednie niecommitowane źródła, zapisano i
  wypchnięto na **`origin/3d-models`**. Aktualny checkpoint:
  `540524ed32e77f8d1f5219da62759a343ca2058a`.
  Początkowy e696d1c4 i pośredni8adcaafe mają tę samą zawartość; różni je
  poprawiane autorstwo. Nie traktuj tych starych SHA jako aktualnego tipa.
- Kontrole archiwum: Git LFS fsck,843 tożsamości plików źródłowych/stagingu,
  walidator projektu i42 headless testy podglądu stylów PASS. To nie są testy
  akceptacji nowego wyglądu ani normalnej rozgrywki.
- Research i konkretne źródła są w
  [DRAWN_25D_RESEARCH.md](../design/character-art/DRAWN_25D_RESEARCH.md).
  Metadane i piny: `tools/assets/drawn_character_research.json`.
  Opis etapu: [stage46](../qa/stages/2026-11-03-stage-46.md).
- Znaleziono rzeczywiste skille `scenario-sprite-animation` oraz `spa`, MCP
  PixelLab, AutoSprite, Retro Diffusion i alternatywne sterowanie Aseprite.
  Przeczytano właściwe dokumentacje/SKILL.md, a nie tylko katalogowe reklamy.
- **Nie zainstalowano nowych skilli/MCP, nie podłączono kont, nie kupiono dostępu,
  nie zlecono płatnej generacji. Nie powstał jeszcze nowy rycerz2D.**
- Istniejące Aseprite1.3.17.2 batch/Lua i narzędzie imagegen są dostępne w tej
  sesji; nowy agent musi sprawdzić swoją aktualną dostępność narzędzi.
- Na koniec użytkownik jawnie zlecił wypchnięcie także researchu/notatek na branch
  jako jego konto. Te pliki mają być commitowane i wysłane na `2d-art-research`.
  To nie jest zgoda na merge3D do master ani na zmianę starej historii master.

## Omówiona kolejność dalszych prac

1. **Pierwsza mała próba wyglądu2D:** ten sam rycerz w dwóch wykończeniach:
   szczegółowy pixel art oraz malarstwo2D. Proste, spokojnie ustawione nogi,
   rękawice, widoczna twarz/zbroja, osobny sztywny miecz. Pokaż na tle obecnej
   gry przy docelowej ekspozycji i w zbliżeniu. To proponowany następny etap;
   nie uruchamiaj od razu produkcji wszystkich postaci/akcji.
2. Do pierwszych ilustracji można wykorzystać dostępny imagegen; przy faktycznym
   generowaniu przeczytaj jego skill i `create-game-assets`. Raster/pixelowe
   poprawki i eksporty muszą przejść przez Aseprite zgodnie z `agents/README.md`.
   Przed implementacją nowego pilota zapisz właściwy owner/slice/milestone.
3. Po wyborze wyglądu: krótki idle/chód i pojedynczy cios. Zaplanuj pozy:
   zamach -> kontakt -> wyhamowanie -> powrót. Ruch bioder, tułowia i ramienia;
   rękawica trzyma rękojeść, ostrze nie odkształca się i nie kręci samym nadgarstkiem.
   Zachowaj wygląd, proporcje, paletę i kotwicę między klatkami.
4. Generator do próby: PixelLab jest kandydatem do pixel artu; AutoSprite/Scenario
   do animowania ilustracji. To kandydaci, nie zatwierdzone rezultaty. Wybór/usługa
   musi odpowiadać zaakceptowanemu wykończeniu i dostępnemu kontu/budżetowi.
   Dostęp do konta i płatne generacje pozostają niezałatwione; nie wymyślaj kluczy
   i nie zakładaj zgody na opłaty. Darmowe przygotowanie nie musi czekać na te konta.
5. Każdy etap -> kontrola plików -> realny podgląd co najmniej kilku cykli1x ->
   poprawki i powtórka. Dopiero po akceptacji tego pilota8 kierunków, pełny zestaw
   akcji, zróżnicowane twarze/sylwetki przeciwników i integracja z grą.

Praktyczne pułapki z researchu: PixelLab ma różne limity statyki/animacji i wymaga
prawidłowo skierowanej referencji frontowej; dedykowane ataki AutoSprite mogą być
boczne, więc nie utożsamiaj ich z widokiem izometrycznym. SPA wymaga Python3.13+,
obecna venv ma3.12; alternatywny Aseprite MCP deklaruje3.10+. Sam skill nie
instaluje CLI/usługi i nie gwarantuje naturalnego ruchu. Spine jest opcją później,
nie warunkiem rozpoczęcia pierwszej próby ani generatorem ilustracji.

## Git i contributions: co jest poprawione, a co nadal czeka

- Aktywne konto GitHub: `KarolBautrel`, ID93617105.
- Stara konfiguracja repo miała fikcyjne `karol@example.local`. Bieżąca lokalna
  konfiguracja: `Karol Bautrel` oraz
  `93617105+KarolBautrel@users.noreply.github.com`.
- Podany `karol.bautre@gmail.com` nie powiązał commita z kontem w API. Adres
  noreply został sprawdzony: autor i commiter checkpointa540524ed to KarolBautrel.
  Nie zmieniaj go z powrotem na placeholder ani na niezweryfikowaną tożsamość.
- Commity na osobnym branchu nie gwarantują pola w wykresie contributions;
  warunki obejmują domyślny branch. **Nie twierdź, że stary wykres naprawiono.**
- Jest45 błędnie przypisanych commitów na master. Przygotowano lokalny podgląd
  naprawy53 commitów, z zachowaniem drzew/dat/wiadomości i starych referencji.
  Jednego podpisu GitHub nie da się przenieść na przebudowany commit.
- Użytkownik **nie potwierdził jeszcze szerszego nadpisania historii master**.
  Pytanie było zadane; polecenie wypchnięcia tych notatek na branch nie jest
  taką zgodą. Przy wznowieniu nie zakładaj, że „wracamy” lub noc oznacza zgodę.
- Szczegóły: [git-author-repair](../qa/2026-11-03-git-author-repair.md).
  `artifacts/git-author-repair/full-history-plan.json` i preview refs są lokalne.
  Ten plan powstał **przed commitem/pushem niniejszych notatek na2d-art-research**.
  Jeżeli użytkownik zezwoli na szerszą naprawę, przelicz go z aktualnych zdalnych
  refów, uwzględniając także nowy branch/handoff; nie odtwarzaj ślepo starych SHA.
  Kopie starych refów, aktualne exact leases, atomowy push i sprawdzenie autorstwa
  po stronie GitHub są wymagane. Do tej decyzji można oddzielnie omawiać2D.

## Testy i kontrola komputera

Wszystkie61 fizycznych testów właściwej gry pozostają NOT_RUN. Kontrola pulpitu
nie została oddana. Bez wyraźnego zwolnienia nie przejmuj myszy/klawiatury ani nie
otwieraj widocznych aplikacji. Gra przy przyszłych testach ma działać windowed na
większym lewym DISPLAY1 przez `tools/qa/start_game.ps1`, z ochroną zapisów.
Host odizolowanej przeglądarki był niedostępny; starych stilli i pomiarów nie wolno
opisywać jako obejrzanej ciągłej animacji. To nie zwalnia przyszłego pilota z1x QA.

Na dziś po zapisaniu, walidacji i zleconym pushu kończymy. Nie generuj kolejnych
assetów, nie instaluj usług ani nie publikuj naprawy historii podczas tej przerwy.

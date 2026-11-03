# Rycerz2D: statyczne propozycje A/B

Owner: presentation020 / slice020 / milestone015. Wykonane2026-11-03 na
`2d-art-research`. Status: **do wyboru przez użytkownika**.

- [comparison.png](comparison.png): oba wykończenia na obecnym leśnym podłożu,
  skala1x, następnie te same piksele powiększone3x i twarz8x.
- [board_scale.png](board_scale.png): porównanie1x na ziemi i w lesie.
- [closeup.png](closeup.png): pixel art powiększony4x i malowane źródło w tej
  samej wielkości; obok twarz, rękawica i chwyt. Rozdzielczość źródła nie jest
  obietnicą takiej ilości detalu przy skali planszy.

To kompozycje statyczne na rzeczywistych teksturach i obiektach gry, nie zrzuty
rozgrywki. Podłoże zachowuje natywną częstotliwość512px, obiekty używają rozmiarów
i kotwic z `world_art.json`. Nie podmieniono żadnej postaci runtime.

Wspólny kierunek: naturalna dorosła sylwetka3/4, spokojnie ustawione nogi,
proporcjonalne buty, odsłonięta twarz, granat, przygaszona stal, mosiądz i skóra.
A ma45 użytych kolorów z47-kolorowej palety i binarną alfę. B zachowuje malarskie
przejścia i częściową alfę. Źródłowy B ma nieco bardziej falowane włosy i cieplejsze
światła; to para bliskich propozycji, nie identyczny rysunek piksel w piksel.

Kontrakt statyki: canvas280x280, kotwica stóp(140,229), sylwetka63x171px.
171px odpowiada przybliżeniu1.8m *100px/m *cos18deg; narysowanej kamery nie można
uznać za pomiar geometryczny. Miecz19x98px, pozycja(159,131), chwyt lokalny(9,13),
punkt chwytu na canvasie(168,144). Oddzielna warstwa miecza leży pod ciałem/rękawicą.
To jest dopasowanie statyczne; chwyt i części zasłonięte wymagają osobnej kontroli
oraz ewentualnego dorysowania przy przyszłych pozach animacji.

Edytowalne źródła są w
`assets_src/aseprite/characters/drawn_knight/2026-11-03/`:
`pixel_master.aseprite`, `painted_master.aseprite` (pełne źródła, ciało i miecz
oddzielnie) oraz `pixel_native.aseprite`, `painted_native.aseprite` (warstwy w
docelowej skali). Obok są również źródła trzech plansz. Eksporty `*_body.png`,
`*_sword.png` i `*_assembled.png` mają zgodny canvas i kotwicę.

Pochodzenie: wbudowane `image_gen.imagegen`, dwa wywołania z prawdziwą alfą;
oryginały bez zmian w `raw/`. Referencje to projektowy zaakceptowany strój
poprzedniego strażnika i obecne podłoże, następnie pierwszy wygenerowany rysunek
jako odniesienie dla wersji malowanej. Nie kopiowano postaci ani klatek BG/Pillars.
Pełne prompty: [prompts.json](prompts.json). Metadane/hashe:
[manifest.json](manifest.json), [verification.json](verification.json).

Powtarzalny eksport bez pulpitu i dodatkowych zależności:

```powershell
python tools/qa/build_drawn_knight_static.py
```

Cała obróbka rastra odbywa się w Aseprite1.3.17.2 przez
`tools/aseprite/drawn_knight_static.lua`. Python tylko uruchamia Aseprite,
sprawdza nagłówki/raport i zapisuje hashe. API:
[Image](https://www.aseprite.org/api/image),
[Palette](https://www.aseprite.org/api/palette).

Kontrole plików i ogląd statycznych plansz nie oznaczają wyboru wyglądu,
akceptacji animacji ani przejścia61 odłożonych testów gry. Następny krok to wybór
A/B i korekty wyglądu; animacja dopiero po wyborze.

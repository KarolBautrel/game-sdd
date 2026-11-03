# Strażnik — pierwsza próba ruchu

Otwórz **preview.html** dwuklikiem. Pliki działają lokalnie, bez serwera.
Trzy animacje odtwarzają się jednocześnie: bezczynność, chód i atak mieczem.
Wybierz przód/bok/tył/trzy czwarte. Możesz zatrzymać ruch, przejść o klatkę,
przeciągnąć oś czasu, zwolnić tempo lub włączyć powiększenie2x.

Zachowane są zaakceptowane ubranie, twarz, tekstury i lekko mniejsze buty.
Model w spoczynku ma dokładnie te same wierzchołki i UV. Dodane: szkielet,
wagi, trzy animacje i osobny miecz przypięty przez rękojeść do dłoni.

Źródła: `warden_bound.blend` — samo powiązanie szkieletu;
`warden_motion.blend` — trzy edytowalne klipy; `warden_motion.fbx` — eksport.
Pliki Aseprite: katalog `aseprite/`; plansze: `motion_review.png` i
`direction_review.png`. Oryginalne384px klatki: `renders/`.

Referencją czasu są HTML i Blender/FBX24fps. Format Aseprite zaokrągla czas
klatki do42ms. Skala1x:100px/metr, kamera18stopni. Podłoże/cień w HTML to pomoc
w ocenie kontaktu; postać pochodzi z rzeczywistych renderów modelu.

Testy i pomiary: `rig_verification.json`, `motion_verification.json`.
Sprawdzenie po imporcie FBX usuwa automatycznie zgadywane przez Blender
połączenia kości, które blokują przesunięcia bioder. Do edycji otwieraj .blend.
Pełna instrukcja: `docs/design/character-art/WARDEN_MOTION_PILOT.md` w repo.

To ograniczona próba animacji. Nie ma jeszcze palców/mimiki, całego zestawu akcji,
ośmiu kierunków ani podmiany w grze. Głęboki przysiad testowy nadal pokazuje
uproszczone zgięcia spodni i małą szczelinę z tyłu poły; nie jest dostarczaną akcją.
Układ odtwarzacza i ciągły ruch wymagają przeglądu użytkownika — host odizolowanej
przeglądarki był niedostępny.61 testów właściwej gry nadal czeka na oddanie kontroli.

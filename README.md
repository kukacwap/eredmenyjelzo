# Eredményjelző ⚽️

Kispályás (5+5 / 6+6) amatőr foci eredményjelző Apple Watch alkalmazás 90 perces meccsekhez.

## Funkciók

- **Eredménykijelzés** – fent a **zöld** csapat, lent a **fehér** csapat góljai nagy számokkal, amelyek minden Apple Watch méretre automatikusan felskálázódnak. A felső képernyőfél halvány zöld, az alsó világos tónust kap, hogy a szám színétől függetlenül is azonnal látszódjon, melyik csapat melyik.
- **Digital Crown gólkezelés** – a koronát **felfelé** tekerve a felső (zöld), **lefelé** tekerve az alsó (fehér) csapat kap egy gólt. A véletlen érintés ellen néhány kattanásnyi tekerés kell egy gólhoz, gól után rövid ideig nem fogad újabb tekerést, és irányonként eltérő haptikus visszajelzést ad. Az irányt az első pár másodpercben nyíl-emlékeztető jelzi.
- **Gól-visszajelzés** – gólnál a szám rövid időre felnagyul és felderül, így a szem sarkából is látszik, hogy a bevitel regisztrálódott.
- **Félidő és szüneteltethető óra** – a menüből indítható a **félidő** (az óra és az edzés is megáll), majd a **2. félidő**, ami a fociban szokásos módon a félidő hosszától számol tovább. Az óra bármikor megállítható és folytatható (sérülés, hosszú beadás). A félidő hossza állítható: 20 / 25 / 30 / 35 / 45 perc.
- **Always-On kijelző** – lefordított csuklóval is látszik az állás: halványított számok, és a rendszer percenkénti frissítéséhez igazodva perc-alapú óra (`23′`), hogy ne álljon meg egy elavult másodpercértéken.
- **Action Button (Ultra) és Double Tap** – a **saját csapatod** egy fizikai gombnyomással is gólt kaphat, ami játék közben sokkal könnyebb, mint koronát tekerni. Lásd lentebb a beállítást.
- **Meccs végi összegzés** – végeredmény, tisztán játékkal töltött idő, átlag- és maximális pulzus, kalória, valamint a **gólok időrendje** percre.
- **Automatikus mentés** – az állás minden gólnál mentődik, így ha a rendszer kilövi az appot vagy újraindul az óra, az indító képernyő felajánlja a **félbehagyott meccs folytatását**.
- **Menü gomb** – a képernyő jobb szélén, középen lévő gombbal nyílik a menü: eredmény szerkesztése (+/-, nullázás), óra megállítása/folytatása, félidő, futó óra mutatása, saját csapat, aktuális pulzus, meccs befejezése.
- **Workout integráció** – a „Meccs indítása" gomb **labdarúgás (soccer)** típusú HealthKit edzést indít, így a meccs alatt megy a pulzusmérés és kalóriaszámlálás, az app a háttérben is aktív marad (`workout-processing` háttérmód), és a meccs edzésként mentődik az Egészség appba. Félidőben és óramegállításnál az edzés is szünetel.

## Használat

1. Nyisd meg az appot, koppints a **Meccs indítása** gombra (első indításkor engedélyezd a HealthKit hozzáférést).
2. Gólnál tekerd a Digital Crownt a gólt szerző csapat iránya felé (fel = zöld, le = fehér), vagy nyomd az Action Buttont / használd a Double Tapet a saját csapatodhoz.
3. A jobb oldali menü gombbal szerkesztheted az eredményt, indíthatsz félidőt, megállíthatod az órát, és befejezheted a meccset.

## Action Button és Double Tap beállítása

**Action Button (Apple Watch Ultra):** Óra → Beállítások → **Action Button** → *Parancs (Shortcut)* → válaszd a **„Gól"** parancsot. Ezután játék közben egy narancs gombnyomás gólt ad a saját csapatodnak, az app megnyitása nélkül. Téves nyomás esetén a **„Gól visszavonása"** parancs is elérhető (pl. a Parancsok appból vagy Siriből).

**Double Tap:** a képernyő bal szélén, középen lévő **+** gomb az app elsődleges művelete, ezért a Double Tap (hüvelyk-mutatóujj koppintás) is ezt hívja meg. Ehhez **Apple Watch Series 9 / Ultra 2 vagy újabb** kell – az első generációs Ultrán ez a gesztus nem támogatott, de a + gomb és az Action Button ott is működik.

Mindkettő a **saját csapatodnak** ad gólt, amit a Beállításokban (indító képernyő) vagy a menüben állíthatsz zöldre/fehérre.

## Fordítás

- Xcode 16 vagy újabb, watchOS 11.0+ cél (a Double Tap `handGestureShortcut` API-ja miatt).
- Nyisd meg az `Eredmenyjelzo.xcodeproj` fájlt, állítsd be a saját fejlesztői csapatod (Signing & Capabilities), majd futtasd az **Eredmenyjelzo Watch App** targetet Apple Watch szimulátoron vagy órán.
- Watch-only app, iPhone-os társalkalmazás nem szükséges.

## Kiadás az App Store-ba

Az App Store megjelenéshez szükséges minden anyag a [`docs/`](docs/) mappában:

- [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) – lépésről lépésre kiadási folyamat (signing, HealthKit App ID, archiválás, feltöltés, review jegyzetek, képernyőkép-méretek).
- [`docs/APP_STORE_LISTING.md`](docs/APP_STORE_LISTING.md) – App Store Connect szövegek magyarul és angolul (név, leírás, kulcsszavak, kategóriák, App Privacy válaszok).
- [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md) – adatvédelmi tájékoztató (HealthKit miatt kötelező, hosztolni kell és linkelni az App Store Connectben).

## Hangolás

A tekerés érzékenysége a `ScoreboardView.swift` elején állítható:

- `goalThreshold` – ennyi kattanásnyi tekerés kell egy gólhoz (alapból 3),
- `goalCooldown` – gól után ennyi másodpercig nem fogad újabb tekerést (alapból 1,2 s).

Ha a tekerés iránya fordítva kényelmes, a `handleCrown` függvényben a zöld/fehér ág cserélendő.

## Felépítés

| Fájl | Feladat |
|------|---------|
| `MatchStore.swift` | `Team`, `MatchPhase`, `GoalEvent`, `MatchSnapshot` (meccsállapot + időszámítás), `MatchStore` (mentés/visszatöltés), `MatchSettings` (beállítások, a meccstől függetlenül) |
| `MatchModel.swift` | A meccs vezérlése: félidők, óra bankolása, gólok, mentés, külső változás visszaolvasása |
| `WorkoutManager.swift` | HealthKit labdarúgás edzés, pulzus/kalória statisztika, szüneteltetés |
| `ScoreboardView.swift` | A meccsképernyő: számok, tónusok, korona, always-on, gól-animáció |
| `HalftimeView.swift` / `SummaryView.swift` | Félidő és meccs végi összegzés |
| `StartView.swift` | Indítás, félbehagyott meccs folytatása, beállítások |
| `MenuView.swift` / `EditScoreView.swift` | Menü és eredményszerkesztés |
| `GoalIntents.swift` | App Intents az Action Buttonhoz (gól / visszavonás) |

Megjegyzés a folytatáshoz: a meccsóra valós idő szerint fut, ezért ha az app hosszabb ideig ki volt lőve, a folytatásnál az addig eltelt idő beleszámít (ez felel meg a valóságnak). Az óra megállításával és az eredmény szerkesztésével bármikor korrigálható. A 6 óránál régebbi mentést az app nem ajánlja fel.

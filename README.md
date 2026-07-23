# Eredményjelző ⚽️

Kispályás (5+5 / 6+6) amatőr foci eredményjelző Apple Watch alkalmazás 90 perces meccsekhez.

## Funkciók

- **Eredménykijelzés** – fent a **zöld** csapat, lent a **fehér** csapat góljai nagy számokkal.
- **Digital Crown gólkezelés** – a koronát **felfelé** tekerve a felső (zöld), **lefelé** tekerve az alsó (fehér) csapat kap egy gólt. A véletlen érintés ellen néhány kattanásnyi tekerés kell egy gólhoz, gól után rövid ideig nem fogad újabb tekerést, és irányonként eltérő haptikus visszajelzést ad.
- **Menü gomb** – a képernyő jobb szélén, középen lévő gombbal nyílik a menü:
  - **Eredmény szerkesztése** – mindkét csapat gólja +/- gombokkal módosítható, illetve nullázható (pl. téves tekerés javítására).
  - **Futó óra mutatása** – a két eredmény között futó meccsóra ki- és bekapcsolása.
  - **Meccs befejezése** – megerősítés után lezárja a meccset és menti az edzést.
- **Workout integráció** – a „Meccs indítása" gomb **labdarúgás (soccer)** típusú HealthKit edzést indít, így a meccs alatt megy a pulzusmérés és kalóriaszámlálás, az app a háttérben is aktív marad (`workout-processing` háttérmód), és a meccs edzésként mentődik az Egészség appba. A menüben az aktuális pulzus is látszik.

## Használat

1. Nyisd meg az appot, koppints a **Meccs indítása** gombra (első indításkor engedélyezd a HealthKit hozzáférést).
2. Gólnál tekerd a Digital Crownt a gólt szerző csapat iránya felé (fel = zöld, le = fehér).
3. A jobb oldali menü gombbal szerkesztheted az eredményt, kapcsolhatod az órát, és fejezheted be a meccset.

## Fordítás

- Xcode 16 vagy újabb, watchOS 10.0+ cél.
- Nyisd meg az `Eredmenyjelzo.xcodeproj` fájlt, állítsd be a saját fejlesztői csapatod (Signing & Capabilities), majd futtasd az **Eredmenyjelzo Watch App** targetet Apple Watch szimulátoron vagy órán.
- Watch-only app, iPhone-os társalkalmazás nem szükséges.

## Hangolás

A tekerés érzékenysége a `ScoreboardView.swift` elején állítható:

- `goalThreshold` – ennyi kattanásnyi tekerés kell egy gólhoz (alapból 3),
- `goalCooldown` – gól után ennyi másodpercig nem fogad újabb tekerést (alapból 1,2 s).

Ha a tekerés iránya fordítva kényelmes, a `handleCrown` függvényben a zöld/fehér ág cserélendő.

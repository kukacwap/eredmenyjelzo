# Adatvédelmi tájékoztató – Eredményjelző

_Utolsó frissítés: 2026. július 23._

Ezt a tájékoztatót nyilvánosan elérhető weboldalra kell kitenni (pl. GitHub
Pages), és a linkjét az App Store Connect **Privacy Policy URL** mezőjébe kell
beírni. A HealthKit használata miatt az App Store megkövetel egy adatvédelmi
tájékoztatót.

---

## Magyar változat

Az **Eredményjelző** alkalmazás („az App") tiszteletben tartja a magánszférádat.
Ez a tájékoztató leírja, hogyan kezeli az App az adatokat.

### Milyen adatokat gyűjtünk?

**Semmilyet.** Az App nem gyűjt, nem tárol szerveren és nem oszt meg semmilyen
személyes adatot. Nincs felhasználói fiók, nincs regisztráció, nincs analitika,
és az App nem kommunikál semmilyen hálózati kiszolgálóval.

### Egészségügyi (HealthKit) adatok

Amikor elindítasz egy meccset, az App a te engedélyeddel egy „labdarúgás"
típusú edzést indít az Apple HealthKit rendszerén keresztül. Ennek keretében:

- **olvassa** a pulzusodat, az aktív kalóriát és a megtett távolságot, hogy a
  meccs alatt megjeleníthesse őket;
- **ír** egy edzésbejegyzést az Egészség (Health) appba.

Ezek az adatok **kizárólag a te eszközödön maradnak**, az Apple HealthKit
biztonságos tárolójában. Az App **nem továbbítja**, **nem másolja** és **nem
osztja meg** ezeket az adatokat sem velünk, sem harmadik féllel. Az egészségügyi
adatokat semmilyen célra (pl. reklám) nem használjuk fel. A HealthKit
hozzáférést bármikor visszavonhatod az iPhone Egészség appjában vagy az óra
beállításaiban.

### Helyadatok (mozgás-hőtérkép)

Ez a funkció **alapértelmezés szerint ki van kapcsolva**, és csak akkor működik,
ha te kapcsolod be a beállításokban. Bekapcsolva az App a meccs ideje alatt
rögzíti az óra helyzetét, hogy megmutassa, a pálya mely részén mennyi időt
töltöttél.

- A helyadatot **csak a meccs alatt** gyűjtjük, a meccs végén a rögzítés leáll.
- A nyers koordinátákat **nem tároljuk**: a meccs végén egy relatív rácsot
  számolunk belőlük (melyik cellában mennyi időt töltöttél), és csak ez kerül
  mentésre. Ebből a pálya földrajzi helye nem állítható vissza.
- Az adat **kizárólag az órádon marad**, sehová nem küldjük el.
- A hozzáférést bármikor visszavonhatod az óra Beállítások → Adatvédelem és
  biztonság → Helymeghatározás menüjében, vagy egyszerűen kikapcsolhatod a
  funkciót az Appban.

### A meccs eredménye

A meccs állása és a beállítások csak az App futása alatt, az eszköz memóriájában
léteznek. Ezeket nem küldjük el sehová.

### Gyermekek

Az App nem gyűjt adatot senkitől, így gyermekektől sem.

### A tájékoztató változásai

A tájékoztatót időnként frissíthetjük. A változásokat ezen az oldalon tesszük
közzé a fenti dátum frissítésével.

### Kapcsolat

Kérdés esetén: nyiss egy issue-t a projekt oldalán
(`https://github.com/kukacwap/eredmenyjelzo`).

---

## English version

**Eredményjelző** ("the App") respects your privacy. This policy explains how
the App handles data.

### What data do we collect?

**None.** The App does not collect, store on any server, or share any personal
data. There is no user account, no sign-up, no analytics, and the App does not
communicate with any network server.

### Health (HealthKit) data

When you start a match, with your permission the App starts a "Soccer" workout
through Apple HealthKit. As part of this it:

- **reads** your heart rate, active energy, and distance in order to display
  them during the match;
- **writes** a workout record to the Health app.

This data **stays entirely on your device**, in Apple's secure HealthKit store.
The App does **not** transmit, copy, or share this data with us or any third
party, and never uses health data for any purpose such as advertising. You can
revoke HealthKit access at any time in the Health app on iPhone or in your
watch settings.

### Location data (movement heat map)

This feature is **off by default** and only works if you turn it on in settings.
When enabled, the App records the watch's position during a match to show where
on the pitch you spent your time.

- Location is collected **only during a match**; recording stops when the match ends.
- Raw coordinates are **not stored**. At the end of the match they are reduced to
  a relative grid (how long you spent in each cell), and only that grid is saved.
  The geographic location of the pitch cannot be recovered from it.
- The data **stays on your watch only** and is never transmitted anywhere.
- You can revoke access at any time in Settings → Privacy & Security → Location
  Services on the watch, or simply turn the feature off in the App.

### Match score

The match score and settings exist only in device memory while the App is
running. They are never sent anywhere.

### Children

The App collects no data from anyone, including children.

### Changes to this policy

We may update this policy from time to time. Changes will be posted on this page
with an updated date above.

### Contact

Questions? Open an issue on the project page
(`https://github.com/kukacwap/eredmenyjelzo`).

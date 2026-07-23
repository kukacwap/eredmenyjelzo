# Kiadási checklist – App Store megjelenés

Lépésről lépésre, hogy az **Eredményjelző** watchOS app kikerüljön az App
Store-ba. Pipáld ki sorban.

---

## 0. Előfeltételek

- [ ] **Apple Developer Program** tagság aktív (99 USD/év). Enélkül nem lehet
      App Store-ba tölteni, csak szimulátorban futtatni.
- [ ] **Xcode 16+** telepítve egy Macen.
- [ ] Bejelentkezve az Apple ID-val: Xcode → Settings → Accounts.

---

## 1. App ID és képességek (developer.apple.com)

- [ ] **Certificates, Identifiers & Profiles** → Identifiers → új App ID:
      `com.kukacwap.eredmenyjelzo.watchkitapp` (Explicit).
- [ ] Ennél az App ID-nál kapcsold be a **HealthKit** capability-t.
      > Ez kritikus: ha az App ID-n nincs bekapcsolva a HealthKit, a feltöltés
      > vagy a review elbukik. Az appban a `com.apple.developer.healthkit`
      > entitlement már be van állítva
      > (`Eredmenyjelzo Watch App/Eredmenyjelzo Watch App.entitlements`).
- [ ] (Automatic signing esetén az Xcode ezt sok esetben magától létrehozza.)

---

## 2. Signing az Xcode-ban

- [ ] Nyisd meg az `Eredmenyjelzo.xcodeproj`-t.
- [ ] Target **Eredmenyjelzo Watch App** → **Signing & Capabilities**:
  - [ ] „Automatically manage signing" bepipálva.
  - [ ] **Team**: a saját fejlesztői csapatod kiválasztva.
  - [ ] A **HealthKit** capability szerepel a listában (ha nem, a „+ Capability"
        gombbal add hozzá).
- [ ] Ellenőrizd a verziót: **Version (MARKETING_VERSION)** = `1.0`,
      **Build (CURRENT_PROJECT_VERSION)** = `1`. Minden új feltöltésnél a
      Build számot növelni kell.

---

## 3. Ikon és utolsó ellenőrzés

- [ ] Az AppIcon be van állítva (`Assets.xcassets/AppIcon`), 1024×1024, alfa
      nélkül. (Már megvan: zöld 6 / fehér 3.)
- [ ] Product → **Clean Build Folder** (⇧⌘K), majd egy sima **Run** (⌘R) igazi
      órán vagy szimulátoron, hogy minden rendben induljon.
- [ ] Teszteld a HealthKit engedélykérést és a meccs indítását igazi Apple
      Watchon (a szimulátor nem ad valós pulzust).

---

## 4. Archiválás és feltöltés

- [ ] Csatlakoztass egy fizikai Apple Watch-hoz párosított iPhone-t, VAGY
      válaszd a **Any watchOS Device (arm64)** célt a séma-választóban.
      (Archiválni csak eszközre/általános eszközre lehet, szimulátorra nem.)
- [ ] Product → **Archive**.
- [ ] Az Organizer ablakban: **Distribute App** → **App Store Connect** →
      **Upload** → végig a varázslón (Automatic signing).
- [ ] A feltöltés után az App Store Connectben a build pár perc – fél óra alatt
      megjelenik (feldolgozás után).

> **Watch-only app:** watchOS 6+ óta önállóan terjeszthető, nem kell hozzá
> iPhone-os társapp. Az archívum közvetlenül a watch app targetből készül.

---

## 5. App Store Connect – app rekord

- [ ] appstoreconnect.apple.com → **Apps** → **+** → **New App**.
  - Platform: **watchOS** (illetve iOS-listában watch-only appként jelenik meg).
  - Név, elsődleges nyelv (Magyar), Bundle ID, SKU – lásd
    `APP_STORE_LISTING.md`.
- [ ] Töltsd ki a **1.0 verzió** oldalt a `APP_STORE_LISTING.md` szövegeivel:
      alcím, promóciós szöveg, leírás, kulcsszavak, kategóriák, URL-ek.
- [ ] Válaszd ki a feldolgozott **buildet**.
- [ ] **App Privacy**: töltsd ki – „**Data Not Collected**" (lásd listing doc).
- [ ] **Age Rating**: 4+.
- [ ] **Privacy Policy URL**: a hosztolt `PRIVACY_POLICY.md` linkje (KÖTELEZŐ).
- [ ] Töltsd fel a **képernyőképeket** (lásd lentebb).

---

## 6. Képernyőképek (Apple Watch)

Legalább **egy** Apple Watch méretre kötelező screenshot. Az App Store Connect
a legnagyobb feltöltött méretet a kisebbekre is használhatja, de érdemes
többet feltölteni. Készítsd őket a **szimulátorból**: futtasd az appot, majd a
szimulátor menü → File → **Save Screen** (⌘S).

Gyakori méretek (px, portré):

| Apple Watch | Felbontás |
|-------------|-----------|
| Ultra / Ultra 2 (49 mm) | 410 × 502 |
| Series 10 (46 mm) | 416 × 496 |
| Series 7–9 (45 mm) | 396 × 484 |
| Series 4–6 / SE (44 mm) | 368 × 448 |
| (41 mm) | 352 × 430 |
| (40 mm) | 324 × 394 |

Javasolt képek (2–4 db): 1) a fő eredményjelző kép egy állással (pl. 6:3),
2) a menü, 3) az eredmény szerkesztése nézet. A screenshot **nem** tartalmazhat
átlátszó hátteret és állapotsort/óra-időt idegen tartalommal.

---

## 7. App Review – megjegyzések a bírálónak (fontos!)

Az App Store Connect **App Review Information → Notes** mezőjébe ajánlott
beírni (HealthKit miatt a bírálók ezt figyelik):

```
Ez egy önálló (watch-only) watchOS app kispályás foci eredményjelzésére.

HealthKit: a "Meccs indítása" gomb egy labdarúgás (Soccer) típusú edzést
indít, hogy a meccs alatt pulzus- és kalóriamérés fusson, és a meccs
edzésként mentődjön az Egészség appba. Az egészségügyi adat az eszközön
marad, nem hagyja el az órát, nem osztjuk meg, nem használjuk reklámra.

Teszteléshez: nyisd meg az appot, koppints a "Meccs indítása" gombra, és
engedélyezd a HealthKit hozzáférést. Gólt a Digital Crown fel/le
tekerésével lehet adni (fel = zöld csapat, le = fehér csapat). A jobb
oldali menü gombbal érhető el az eredmény szerkesztése, a futó óra
kapcsolása és a meccs befejezése.

Az app nem gyűjt adatot, nincs fiók, nincs hálózati kommunikáció.
```

Gyakori HealthKit-es elbukási okok, amiket az app már kezel:
- [x] `NSHealthShareUsageDescription` és `NSHealthUpdateUsageDescription` meg
      van adva értelmes szöveggel (`Info.plist`).
- [x] HealthKit entitlement beállítva.
- [x] Van adatvédelmi tájékoztató (Guideline 5.1.1 / 5.1.3 elvárja).
- [x] Az egészségügyi adatot nem használjuk hirdetésre és nem osztjuk meg.

---

## 8. Beküldés

- [ ] **Add for Review** → **Submit**.
- [ ] Export Compliance: nincs titkosítás → **No** (lásd listing doc).
- [ ] Válaszd a kézi vagy automatikus megjelenést (Release).
- [ ] Várd meg a review-t (általában 24–48 óra). Elutasítás esetén a Resolution
      Center üzenete alapján javíts, növeld a Build számot, tölts fel újra.

---

## 9. (Opcionális) TestFlight béta

- [ ] A feltöltött build a TestFlight fülön elérhető.
- [ ] Belső tesztelőket (a csapatból) azonnal meghívhatsz, külső tesztelőkhöz
      rövid béta-review kell.
- [ ] Jó módja élesítés előtt igazi órán, több csuklóméreten kipróbálni.

---

## Verzió-emelés a jövőben

Új kiadásnál:
1. Növeld a **Build**-et (és szükség szerint a **Version**-t) az Xcode-ban.
2. Archive → Upload.
3. App Store Connectben új verzió, töltsd ki a „What's New"-t, válaszd az új
   buildet, Submit.

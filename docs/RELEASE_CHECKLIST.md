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
      `com.kukacwap.eredmenyjelzo` (Explicit).
- [ ] Ennél az App ID-nál kapcsold be a **HealthKit** capability-t.
      > Ez kritikus: ha az App ID-n nincs bekapcsolva a HealthKit, a feltöltés
      > vagy a review elbukik. Az appban a `com.apple.developer.healthkit`
      > entitlement már be van állítva
      > (`Eredmenyjelzo Watch App/Eredmenyjelzo Watch App.entitlements`).
- [ ] Kapcsold be a **Time Sensitive Notifications** capability-t is.
      > A kapuscsere-figyelmeztetés `.timeSensitive` szintű helyi értesítést
      > küld, hogy a Fókusz módokat is áttörje. Az entitlement
      > (`com.apple.developer.usernotifications.time-sensitive`) már be van
      > állítva, de az App ID-n is engedélyezni kell, különben a signing hibát
      > dob. (Ez nem a Critical Alerts – ahhoz külön Apple-engedély kell,
      > ehhez nem.)
- [ ] (Automatic signing esetén az Xcode ezt sok esetben magától létrehozza.)

---

## 2. Signing az Xcode-ban

- [ ] Nyisd meg az `Eredmenyjelzo.xcodeproj`-t.
- [ ] Target **Eredmenyjelzo Watch App** → **Signing & Capabilities**:
  - [ ] „Automatically manage signing" bepipálva.
  - [ ] **Team**: a saját fejlesztői csapatod kiválasztva.
  - [ ] A **HealthKit** és a **Time Sensitive Notifications** capability
        szerepel a listában (ha nem, a „+ Capability" gombbal add hozzá).
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
- [ ] **Privacy Policy URL**: `https://kukacwap.github.io/eredmenyjelzo/`
      (KÖTELEZŐ – előbb kapcsold be a GitHub Pages-t, lásd lentebb az 5b pontot).
- [ ] Töltsd fel a **képernyőképeket** (lásd lentebb).

---

## 5b. GitHub Pages – adatvédelmi tájékoztató hosztolása

Az adatvédelmi tájékoztató kész HTML oldalként a `docs/index.html`-ben van. A
HealthKit miatt kötelező nyilvános URL-ről kiszolgálni. Bekapcsolás (egyszeri,
a GitHub weboldalán):

- [ ] A repo → **Settings** → bal oldalt **Pages**.
- [ ] **Source**: „Deploy from a branch".
- [ ] **Branch**: válaszd azt az ágat, amin a `docs/` mappa van (a fő ág, miután
      ez a branch beolvad – ajánlott –, vagy ideiglenesen a
      `claude/soccer-score-app-wldwq2` ág), **Folder**: `/docs` → **Save**.
- [ ] 1-2 perc múlva az oldal itt lesz elérhető:
      **`https://kukacwap.github.io/eredmenyjelzo/`**
- [ ] Nyisd meg és ellenőrizd, hogy a magyar/angol tájékoztató látszik. Ezt az
      URL-t írd az App Store Connect **Privacy Policy URL** mezőjébe.

> Megjegyzés: a `docs/.nojekyll` fájl gondoskodik róla, hogy a Pages a HTML-t
> változtatás nélkül szolgálja ki. Ha a repo privát, a GitHub Pages nyilvános
> oldalhoz a repót publikussá kell tenni, vagy a tájékoztatót máshol (pl. saját
> domain) hosztolni – a `docs/index.html` bárhol feltölthető statikus oldalként.

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

Az App Store Connect **App Review Information → Notes** mezőjébe **kötelező**
beírni – üresen hagyva a beküldés Guideline 2.1 („Information Needed") miatt
elbukik. Az alábbi szöveg mind a 7 szokásos kérdést lefedi. Mellé **csatolni
kell egy képernyőfelvételt** is fizikai eszközről (Attachment mező).

```
Eredmenyjelzo is a standalone watchOS app (no companion iOS app) that works as
a scoreboard for small-sided amateur football (5-a-side / 6-a-side) matches.
It requires no account, no login, and no network connection.

1. SCREEN RECORDING
A screen recording captured on a physical Apple Watch Ultra (watchOS 26.3) is
attached. It shows: launching the app, the HealthKit and notification
permission prompts, starting a match (which starts a Soccer workout), scoring
goals with the Digital Crown and the on-screen + button, the menu (edit score,
pause clock, halftime, settings), ending the match, and the end-of-match
summary.

2. DEVICES AND OPERATING SYSTEMS TESTED
- Apple Watch Ultra - watchOS 26.3 (physical device, paired with iPhone 13 Pro)
- Apple Watch simulators (49 mm / 46 mm / 45 mm / 41 mm) - watchOS 26, used to
  verify the layout on every screen size

3. PURPOSE AND TARGET AUDIENCE
Problem: amateur football players cannot easily keep score while playing.
Phones are in a bag and nobody wants to stop the game to update a score.
Solution: the app keeps the score on the player's wrist, readable at a glance,
with one-handed input that works while playing.
Target audience: recreational players of 5-a-side and 6-a-side football, and
anyone refereeing or organising such matches.
Value: score, match clock and goalkeeper rotation are handled on the wrist,
while the match is simultaneously recorded as a Soccer workout in the Health
app.

4. HOW TO SET UP AND USE THE APP
No login, no account, no demo credentials and no sample files are required.
- Launch the app. On first launch it asks for HealthKit permission (to record
  the match as a Soccer workout and show heart rate) and notification
  permission (for the optional goalkeeper-rotation alert). Both are optional -
  the scoreboard works if either is denied.
- Tap "Meccs inditasa" (Start match) to begin.
- To score: turn the Digital Crown UP for the green team (top number) or DOWN
  for the white team (bottom number). Several clicks are required so that
  accidental turns do not count.
- The "+" button on the left edge adds a goal for the opposing team. On
  Apple Watch Series 9 / Ultra 2 and later, Double Tap triggers the same
  action.
- The "..." button on the right edge opens the menu: edit score (+/-),
  pause/resume the clock, start halftime, toggle the running clock, choose
  your own team, set the goalkeeper rotation interval, and end the match.
- Ending the match shows a summary: final score, played time, average and
  maximum heart rate, calories, and the timeline of goals.
- On Apple Watch Ultra the Action Button can optionally be assigned to the
  "Gol" (Goal) shortcut in watch Settings; it adds a goal for the user's own
  team.
The user interface is in Hungarian only.

5. EXTERNAL SERVICES, TOOLS OR PLATFORMS
None. The app uses only Apple frameworks: SwiftUI, HealthKit (Soccer workout,
heart rate, active energy), UserNotifications (local notifications only, no
push server), App Intents (Action Button / Shortcuts) and UserDefaults for
local storage. There are no third-party SDKs, no analytics, no advertising,
no authentication service, no payment processing and no AI services. The app
makes no network requests of any kind and collects no data.

6. REGIONAL DIFFERENCES
None. The app behaves identically in every region. The user interface is
Hungarian-only in all regions. There is no region-specific content, pricing
or feature gating.

7. REGULATED INDUSTRY / PROTECTED THIRD-PARTY MATERIAL
The app does not operate in a regulated industry and contains no protected
third-party material. It reads heart rate, active energy and distance from
HealthKit solely to display them to the user during their own workout, and
writes a Soccer workout to the Health app. All health data stays on the
device: it is never transmitted, shared with anyone, or used for advertising.
The app is not a medical device and makes no health or medical claims. All
artwork and text in the app are original.

Privacy policy: https://kukacwap.github.io/eredmenyjelzo/
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

## 1.1 kiadás – teljes menetrend

> Az 1.0-s bolti bináriban az Xcode-sablon `ContentView`-ja futott („Hello,
> world!"), mert a projektcsere során kimaradt az `@main` belépési pont. Az 1.1
> ezt javítja, ezért ez a kiadás sürgős.

### A. Munkapéldány frissítése

```bash
cd ~/Documents/eredmenyjelzo-app
git checkout -- .
git pull origin claude/soccer-score-app-wldwq2
```

- [ ] `ls "eredmenyjelzo Watch App"` → szerepel benne az **`EredmenyjelzoApp.swift`**
- [ ] `grep -rln --include=*.swift "Hello, world" .` → **nem ír ki semmit** (ha igen,
      töröld a `ContentView.swift`-et; a szinkronizált mappa miatt magától fordulna)

### B. Xcode ellenőrzés

- [ ] `eredmenyjelzo Watch App` target → *Signing & Capabilities*: **HealthKit**,
      **Background Modes → Workout processing**, **Time Sensitive Notifications**
      megjelenik, piros hiba nélkül
- [ ] Mindkét targeten (watch app és konténer) **Version 1.1**, **Build 2**
- [ ] `⌘⇧K` (Clean Build Folder)

### C. Tesztelés valódi órán (szimulátorban nincs pulzus)

- [ ] Töröld le az appot az óráról, majd telepítsd Xcode-ból
- [ ] Indításkor **megjelenik a Health engedélykérés**
- [ ] A kezdőképernyő az eredményjelző, **nem „Hello World"**
- [ ] Meccs közben csuklóleengedésre az app **a képernyőn marad** (halványítva)
- [ ] Meccs végén kirajzolódik a **pulzusgörbe** a gólok jelöléseivel
- [ ] A kezdőképernyőn megjelenik a **„Meccsek (n)"** lista
- [ ] Nincs narancs **„Nincs pulzusmérés"** figyelmeztetés

### D. Archiválás és feltöltés

- [ ] Cél: **Any watchOS Device (arm64)** → *Product* → *Archive*
- [ ] Feltöltés előtti ellenőrzés:

```bash
grep -rl "Hello, world" ~/Library/Developer/Xcode/Archives/*/*.xcarchive/Products/ 2>/dev/null
```

  **Semmit nem szabad kiírnia.** Ha kiír, a sablon benne van a binárisban – ne töltsd fel.

- [ ] *Distribute App* → **App Store Connect** → **Upload**
- [ ] Export compliance kérdés már nem jön (`ITSAppUsesNonExemptEncryption = false`
      benne van a `WatchApp-Info.plist`-ben)

### E. TestFlight

- [ ] A build feldolgozása 5–30 perc, utána a *TestFlight* fülön látszik
- [ ] Telepítsd TestFlightből az órára, és fusd végig újra a **C** pontot
- [ ] Ha lehet, játssz vele egy fél meccset – a háttérbe kerülés csak valós
      használatban derül ki

### F. App Store verzió létrehozása

- [ ] App Store Connect → az app → bal oldali sáv → **„+ Version or Platform"** → **1.1**
- [ ] **What's New**: a `docs/APP_STORE_LISTING.md` „Újdonságok – 1.1" szövege
- [ ] **Build**: válaszd ki a most feltöltöttet
- [ ] Képernyőképek, leírás, kulcsszavak, korhatár, adatvédelem: az 1.0-ból
      automatikusan öröklődnek, nem kell újra kitölteni
- [ ] **App Review Information** → *Notes*: másold be újra a 7 pontos jegyzetet
      (7. fejezet) – az 1.0 emiatt kapott 2.1-es elutasítást
- [ ] **Release**: *Automatically release this version*

### G. Beküldés és gyorsítás

- [ ] **Add for Review** → **Submit**
- [ ] **Expedited review kérése**: App Store Connect → *Contact Us* → *App Review*
      → *Request Expedited Review*. Indoklás: élő appban a fő képernyő nem jelenik
      meg, minden felhasználót érint. Kritikus hibajavításnál Apple ezt általában
      megadja, és órák alatt átmegy.
- [ ] *(Opcionális, amíg tart a review)* **Pricing and Availability** →
      *Remove from Sale*, hogy ne gyűljenek az egycsillagos értékelések. A már
      letelepített példányokat nem érinti, és az 1.1 megjelenésekor vissza kell
      kapcsolni.

---

## Verzió-emelés a jövőben

Új kiadásnál:
1. Növeld a **Build**-et (és szükség szerint a **Version**-t) az Xcode-ban.
2. Archive → a fenti `grep`-es ellenőrzés → Upload.
3. App Store Connectben új verzió, töltsd ki a „What's New"-t, válaszd az új
   buildet, Submit.


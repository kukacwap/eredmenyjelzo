# App Store megjelenés – szövegek és metaadatok

Ez a fájl tartalmazza az App Store Connectben kitöltendő minden szöveget.
Másold be a megfelelő mezőkbe. A magyar (elsődleges) mellett angol változat is
található, hogy hozzáadhasd az **English (U.S.)** lokalizációt.

---

## Alapadatok

| Mező | Érték |
|------|-------|
| **Név (App Name)** | Eredményjelző |
| **Alcím (Subtitle, max 30 kar.)** | Kispályás foci eredményjelző |
| **Bundle ID** | `com.kukacwap.eredmenyjelzo.watchkitapp` |
| **SKU** | `eredmenyjelzo-watch-001` |
| **Elsődleges kategória** | Sport (Sports) |
| **Másodlagos kategória** | Egészség és fitnesz (Health & Fitness) |
| **Korhatár (Age Rating)** | 4+ |
| **Ár** | Ingyenes (0-ás ársáv) |
| **Platform** | watchOS (önálló Apple Watch app) |
| **Verzió** | 1.0 |

> Az „App Name" és „Subtitle" App Store-ban egyedi kell legyen. Ha az
> „Eredményjelző" foglalt, javaslat: „Foci Eredményjelző" vagy
> „Kispálya Eredményjelző".

---

## Kulcsszavak (Keywords, max 100 karakter, vesszővel elválasztva)

**Magyar:**
```
foci,futball,eredmény,eredményjelző,kispálya,meccs,gól,óra,sport,edzés,amatőr,scoreboard
```

**Angol:**
```
soccer,football,score,scoreboard,futsal,match,goal,timer,sport,workout,amateur,referee
```

---

## Promóciós szöveg (Promotional Text, max 170 kar. – bármikor módosítható)

**HU:**
> Vezesd a kispályás meccs eredményét egyenesen az órádról. A Digital Crown
> tekerésével adhatsz gólt, közben megy a labdarúgás edzés a háttérben.

**EN:**
> Keep score of your small-sided football match right from your wrist. Turn the
> Digital Crown to add a goal while a soccer workout runs in the background.

---

## Leírás (Description)

### Magyar

```
Az Eredményjelző egy egyszerű, egykezes eredményjelző kispályás (5+5, 6+6)
amatőr focimeccsekhez – közvetlenül az Apple Watch képernyőjén.

Nincs telefon, nincs bíbelődés: felteszed az órát, elindítod a meccset, és a
90 perc alatt végig látod az állást.

MŰKÖDÉS
• Nagy, jól látható eredmény: fent a zöld csapat, lent a fehér csapat gólja.
• A számok minden Apple Watch méreten automatikusan a lehető legnagyobbak.
• Gólszerzés a Digital Crownnal: felfelé tekerve a zöld, lefelé tekerve a
  fehér csapat kap egy gólt. Külön rezgés jelzi, melyik csapat szerzett.
• A véletlen tekerés nem számít: néhány kattanás kell egy gólhoz, és gól után
  rövid ideig nem fogad újabbat.

MENÜ
• Eredmény kézi szerkesztése (+/–), téves gól javítása, nullázás.
• Futó meccsóra ki- és bekapcsolása.
• Meccs befejezése egy koppintással.

EDZÉS INTEGRÁCIÓ
• A meccs indításakor labdarúgás edzés indul: megy a pulzus- és
  kalóriamérés, a meccs pedig elmentődik az Egészség appba.
• Az app a háttérben is aktív marad a teljes meccs alatt.

Az Eredményjelző kizárólag az órán fut, nem igényel iPhone-os társalkalmazást.
Nincs regisztráció, nincs reklám, nincs adatgyűjtés.
```

### English

```
Eredményjelző (Scoreboard) is a dead-simple, one-handed scoreboard for
small-sided (5-a-side, 6-a-side) amateur football matches – right on your
Apple Watch.

No phone, no fuss: strap on your watch, start the match, and see the score
for the full 90 minutes.

HOW IT WORKS
• Big, glanceable score: the green team on top, the white team below.
• The numbers scale to be as large as possible on every Apple Watch size.
• Score with the Digital Crown: turn up for the green team, turn down for the
  white team. A distinct haptic tells you which side scored.
• Accidental turns don't count: a goal needs a few clicks, and there's a
  short cooldown after each goal.

MENU
• Edit the score manually (+/–), fix a mistaken goal, or reset.
• Toggle the running match clock on or off.
• End the match with a single tap.

WORKOUT INTEGRATION
• Starting a match starts a Soccer workout: heart rate and calories are
  tracked, and the match is saved to the Health app.
• The app stays active in the background for the whole match.

Eredményjelző runs entirely on the watch – no companion iPhone app required.
No sign-up, no ads, no data collection.
```

---

## Újdonságok (What's New in This Version – 1.0)

**HU:**
```
Első kiadás. 🎉
• Eredményjelzés kispályás focihoz az Apple Watchon
• Gólszerzés a Digital Crownnal
• Labdarúgás edzés integráció, pulzusméréssel
```

**EN:**
```
First release. 🎉
• Football scoreboard for your Apple Watch
• Score goals with the Digital Crown
• Soccer workout integration with heart rate tracking
```

---

## URL-ek (kötelező mezők)

| Mező | Érték |
|------|-------|
| **Support URL** (kötelező) | pl. `https://github.com/kukacwap/eredmenyjelzo` |
| **Marketing URL** (opcionális) | ugyanaz vagy egy landing page |
| **Privacy Policy URL** (HealthKit miatt KÖTELEZŐ) | lásd `PRIVACY_POLICY.md`, hosztolva |

> A Privacy Policy URL-nek nyilvánosan elérhető weboldalra kell mutatnia.
> Legegyszerűbb: a `docs/PRIVACY_POLICY.md` tartalmát tedd ki GitHub Pages-re,
> vagy a repo README-jébe, és arra hivatkozz.

---

## App Privacy („adatvédelmi címke") – App Store Connect kérdőív

Az app **nem gyűjt semmilyen adatot**. A kérdőívben ezt válaszd:

- **Data Collection:** „**No, we do not collect data from this app**"
  (Nem gyűjtünk adatot ebből az appból.)

Indoklás, ha kérdeznék: az egészségügyi adatok (pulzus, kalória, edzés) csak
az eszközön, a HealthKiten keresztül jelennek meg, nem hagyják el az órát, nem
kerülnek szerverre, és harmadik féllel sincsenek megosztva. Nincs analytics,
nincs hálózati hívás, nincs fiók.

---

## Export megfelelőség (Export Compliance)

- Használ-e titkosítást? **Nem** (nincs hálózati kommunikáció, nincs saját
  titkosítás). Válasz: **No** → nincs szükség további ITSAppUsesNonExemptEncryption
  bejegyzésre, illetve az `Info.plist`-be tehető
  `ITSAppUsesNonExemptEncryption = NO`, hogy a kérdést átugorja a rendszer.

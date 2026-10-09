# My webpage

Horváth Gábor személyes és portfólió weboldala, a gaborhorvath.eu (WordPress + Elementor) statikus, kétnyelvű (EN + HU) újraépítése sima HTML, CSS és JavaScript használatával.

## Döntések
- **Technológia:** sima HTML + CSS + JS, build-lépés nélkül. Később átállhat Astróra.
- **Nyelvek:** angol az alap (`/`), magyar a `/hu/` alatt, mint az eredeti oldalon.
- **Tartalom:** az eredeti oldal minden oldala és cikke (4 oldal + 4 cikk, mindkét nyelven).
- **Tárolás:** helyben fut, a GitHubon privát tárolóban él.

## Reszponzivitás (alapszabály minden oldalra)
**A mobil az elsődleges platform**, a desktop és a tablet másodlagos: minden új funkciót, animációt és hover-effektet előbb telefonon (érintéssel, 390 px) kell megtervezni és ellenőrizni, és csak utána asztalon. Ami csak `:hover`-rel működik, annak érintéses megfelelője is kell (`.is-touched` osztály, lásd `main.js`).

Minden oldal desktopra, tabletre és mobilra is optimalizált, az **eredeti oldal elrendezését** követve:
- **Töréspontok:** asztali ≥ 1025 px, tablet 768–1024 px, mobil ≤ 767 px; a hamburger-menü és a statikus fekete fejléc 921 px alatt lép be.
- **Hero betűméret:** 100/76 px (asztali), 65/45 px (tablet), 40/30 px (mobil); a gombok 20/40 px, mobilon 16/28 px.
- **Tablet:** a hero két oszlopban marad (64% / 36%), a galéria 2×2, a karusszel 2 kártyát mutat, a bal oszlop ~25% széles.
- **Mobil:** egy oszlop, a portré középen, a galéria egymás alatt, a karusszel 1 kártya, a videó teljes szélességű.
- Érintési felületek legalább 44 px-esek; a hover-effektek (pl. portré-forgatás) érintőképernyőn nem ragadnak be.
- Ellenőrzés új oldalnál: 360, 390, 768, 1024, 1280, 1440 px — nincs vízszintes túlcsordulás.

## UI-fejlesztések (2026-10-06, `ui-fejlesztes` ág)
Mobil-első csomag (CSS 23. szakasz, `main.js` 3b–3e blokkok): emoji helyett SVG-ikonok (`tools/update-ui.ps1`), nyomásvisszajelzés érintésre (`:active`), tablet ikonsor egy sorban, cikk-igazítás, „Röviden / In short” doboz a cikkekben (`tools/update-tldr.ps1`), felfutó kulcsszámok, tanúsítványok telefonon csúsztatható sávban (+ pontok), fotósáv 2×2, idővonal `<details>`-szel, gyártói logók 2 oszlopban, lépcsőzött belépő animációk, új mobilmenü (takaró, X-ikon).
**Hero és fénycsík (2026-10-07, a WP-oldal 6.42 szakaszával egyezően; CSS 23. szakasz vége):** a főoldali közösségi ikonsor balra, a cím és a gombok bal szélére igazítva; a vonalrajz-illusztráció asztalon és tableten halvány vízjel a portré oszlopának alján (dekoratív, `alt=""`), telefonon rejtett és nem töltődik be (a hero ~320 px-rel rövidebb); arany fénycsík a portrén (betöltéskor egyszer, majd hoverre / koppintásra) és a kártyákon (hoverre; telefonon a cikkkártyákon egyszer, amikor a nézetbe úsznak); mozgáscsökkentésnél kikapcsolva. Visszaállítási pont: címke `elotte-hero-feny`.
**Magyar címek (2026-10-09, `magyar-cimek` ág):** a magyar oldalakon a címek (h1–h3, `<title>`, `og:title`) mondatszerűek: csak az első betű nagy, a tulajdonnevek (Horváth Gábor, városok, Suprema BioStation 3 Max) és az angol kurzusnevek (pl. „Advanced SQL") változatlanok. Új magyar címnél ezt kövesd. A „csupa nagybetűs" kis feliratok (kategória-címke, dátumsor) CSS-ből jönnek, szándékosak. Az `og:title` a `tools/seo.ps1`-ből jön (a `<title>`-ből), de a szkript újrafuttatása mellékhatásként a sitemap `lastmod` dátumait és az SEO-blokk üres sorait is átírja, ezért futtatás után a nem érintett fájlokat vissza kell állítani. Visszaállítási pont: címke `elotte-magyar-cimek`.
**Korábbi visszaállítás:** a változások a `ui-fejlesztes` ágon vannak; az előző állapot a `elotte-ui-fejlesztes` címke (a `main` ág is érintetlen). Ha nem tetszik: `git switch main` (és az ág törölhető: `git branch -D ui-fejlesztes`). Ha már a `main`-be került, a visszaállítás egy új commit: `git revert <commit>`. Az élő oldal előző csomagja: `..\hostinger-feltoltes\site-ELES-804e563-biztonsagi-masolat.zip`.

## Kapcsolati űrlap (PHP, Hostinger)
Az űrlap (`contact.html`, `hu/kapcsolat.html`) a `https://gaborhorvath.eu/api/contact.php` címre küld adatot, ami e-mailt küld a `gabor@gaborhorvath.eu` címre.
**A Hostingerre csak az `api` mappa kerül** (a jelenlegi WordPress oldal változatlanul marad); a statikus oldal másutt is futhat (helyi Live Server, később bármilyen tárhely) — a szkript a `config.php`-ban felsorolt hosztokról fogad kérést (CORS), és azokra irányít vissza.

**Üzembe helyezés:**
1. hPanel → Fájlkezelő → `public_html` → új mappa: `api` → ide töltsd fel: `contact.php`, `.htaccess`, `config.php` (a `config.example.php` nem kell).
2. A `config.php` NEM kerül a GitHubra (`.gitignore`), csak a gépeden (`api/config.php`) és a szerveren él: `to`, `from` (létező postafiók), `allowed_hosts`, `rate_salt`.
3. PHP-verzió: legalább 8.1 (hPanel → Speciális → PHP-konfiguráció).
4. Ellenőrzés: `https://gaborhorvath.eu/api/contact.php` → „Method Not Allowed”; `.../api/config.php` → 403; majd űrlap-próba a helyi oldalról, és nézd meg a Spam mappát is.
5. Az SPF és DKIM legyen beállítva a domainhez (hPanel → E-mailek), különben a levelek spamnak minősülhetnek.

**Védelmek:** csak POST; Origin/Referer-ellenőrzés (pontos hosztnév és http/https séma); honeypot mező; időcsapda (3 s); IP-nkénti sebességkorlát (5/óra); bemenet-ellenőrzés és fejléc-injektálás elleni védelem; a titkok nem a tárolóban vannak.

## Cikkek és kategóriák
- Cikkek: `blog/*.html` (EN) és `hu/blog/*.html` (HU), az eredeti slugokkal; kategóriák: `category/*.html` és `hu/kategoria/*.html`.
- Az eredeti Astra-sablon mért értékei a `style.css` 16. (cikk) és 17. (kategória) szakaszában; a cikkoldalak EB Garamond betűt is töltenek.
- Olvasási idő (cikkoldal, kategória- és főoldali kártyák) és „Kapcsolódó cikkek” blokk (2 kártya, azonos kategória előre) a cikkek alján: `powershell -ExecutionPolicy Bypass -File .\tools\update-articles.ps1` építi (idempotens; új cikk vagy szövegmódosítás után futtasd újra, utána `tools\bump-assets.ps1`). A szkript a főoldali cikkkártyákból veszi a címet, kivonatot, képet és dátumot.
- Az előző/következő cikk csak a négy valódi cikk között lapoz (az eredeti utazós „bejegyzései” csak egy fotót tartalmazó, noindex oldalak: a Rólam oldal galériája mutatja őket).
- Az eredeti oldalsávjának keresőmezője a 404-es oldalra visz, ezért kimaradt; a Travel/Utazás kategória sincs (nincs mit listázni).
- SEO: a canonical, hreflang és Open Graph blokkot, valamint a `robots.txt`-t és `sitemap.xml`-t a `tools/seo.ps1` generálja (domain: `https://site.gaborhorvath.eu`, a szkript elején egy helyen cserélhető; újrafuttatható, ha új oldal készül: a `$pairs` listába kell felvenni).
- Sütibanner és mérés: `assets/js/consent.js` (az új GA4 mérőazonosító a fájl elején, `GA_ID`; a Google csak elfogadás UTÁN töltődik be, és csak a `site.gaborhorvath.eu` címen), a lábléc „Süti-beállítások” hivatkozásával visszavonható; a `tools/add-consent.ps1` új oldalra is felteszi.
- Hostinger-feltöltés: `powershell -ExecutionPolicy Bypass -File .\tools\make-upload-zip.ps1` elkészíti a `hostinger-feltoltes\site.zip` csomagot **és** ugyanennek a tartalomnak a kicsomagolt mását a `hostinger-feltoltes\site-mappa` mappába. 1. mód: hPanel → Fájlkezelő → aldomain mappa (előbb üres, a rejtett fájlokkal együtt) → `site.zip` feltöltése → Kicsomagolás. 2. mód (ha a szerveroldali kicsomagolás 500-as hibát ad, 2026-10-06-án ez történt): a `site-mappa` tartalmát (Ctrl+A, rejtett elemekkel együtt) a böngészőablakba húzni. A `?v=` cache-azonosító sorvégződés-független (CRLF/LF), így a git `autocrlf` beállítása nem változtatja.
- Automatikus nyelvválasztás: `assets/js/lang.js` (angol oldalról a magyar böngészőt a magyar párra irányítja, ha a látogató még nem választott nyelvet; a választást a `gh_lang` megjegyzi); új oldalra a `tools/add-lang.ps1` teszi fel.
- A betűtípusok helyben vannak (`assets/fonts`, OFL licenc), a látogató böngészője nem keresi fel a Google-t.
- A lábléc asztali nézete (922 px fölött) az eredeti mért értékeit követi; alatta egyoszlopos, 44 px-es érintési felületekkel.

## Tervezett mappaszerkezet
```
My webpage/
├── index.html        angol főoldal
├── hu/               magyar oldalak
├── assets/
│   ├── css/          közös stíluslap (színek, betűk, komponensek)
│   ├── js/           közös szkriptek
│   └── img/          képek
└── README.md
```

## Helyi futtatás
Lásd a későbbi `serve.ps1` vagy a VS Code „Live Server” bővítmény leírását.

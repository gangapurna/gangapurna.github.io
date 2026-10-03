# My webpage

Horváth Gábor személyes és portfólió weboldala, a gaborhorvath.eu (WordPress + Elementor) statikus, kétnyelvű (EN + HU) újraépítése sima HTML, CSS és JavaScript használatával.

## Döntések
- **Technológia:** sima HTML + CSS + JS, build-lépés nélkül. Később átállhat Astróra.
- **Nyelvek:** angol az alap (`/`), magyar a `/hu/` alatt, mint az eredeti oldalon.
- **Tartalom:** az eredeti oldal minden oldala és cikke (4 oldal + 4 cikk, mindkét nyelven).
- **Tárolás:** helyben fut, a GitHubon privát tárolóban él.

## Reszponzivitás (alapszabály minden oldalra)
Minden oldal desktopra, tabletre és mobilra is optimalizált, az **eredeti oldal elrendezését** követve:
- **Töréspontok:** asztali ≥ 1025 px, tablet 768–1024 px, mobil ≤ 767 px; a hamburger-menü és a statikus fekete fejléc 921 px alatt lép be.
- **Hero betűméret:** 100/76 px (asztali), 65/45 px (tablet), 40/30 px (mobil); a gombok 20/40 px, mobilon 16/28 px.
- **Tablet:** a hero két oszlopban marad (64% / 36%), a galéria 2×2, a karusszel 2 kártyát mutat, a bal oszlop ~25% széles.
- **Mobil:** egy oszlop, a portré középen, a galéria egymás alatt, a karusszel 1 kártya, a videó teljes szélességű.
- Érintési felületek legalább 44 px-esek; a hover-effektek (pl. portré-forgatás) érintőképernyőn nem ragadnak be.
- Ellenőrzés új oldalnál: 360, 390, 768, 1024, 1280, 1440 px — nincs vízszintes túlcsordulás.

## Kapcsolati űrlap (PHP, Hostinger)
Az űrlap (`contact.html`, `hu/kapcsolat.html`) az `api/contact.php`-nak küld adatot, ami e-mailt küld a `gabor@gaborhorvath.eu` címre.
Az éles oldalon (Hostinger) működik; a helyi előnézetben (Live Server) nincs PHP, ott az űrlap hibaüzenetet mutat.

**Üzembe helyezés:**
1. hPanel → Fájlkezelő → a `public_html` mappába töltsd fel az egész projektet (az `api` mappával együtt).
2. Az `api` mappában másold le a `config.example.php`-t `config.php` néven, és írd át: `to`, `from` (a saját domain egy címe), `rate_salt` (hosszú véletlen szöveg).
   A `config.php` NEM kerül a GitHubra (`.gitignore`), csak a szerveren él.
3. hPanel → E-mailek: legyen beállítva az SPF és DKIM a domainhez (a Hostinger általában automatikusan megteszi), különben a levelek spamnak minősülhetnek.
4. Próba: küldj magadnak egy üzenetet az éles oldalról.

**Védelmek:** csak POST; Origin/Referer-ellenőrzés; honeypot mező; időcsapda (3 s); IP-nkénti sebességkorlát (5/óra); bemenet-ellenőrzés és fejléc-injektálás elleni védelem; a titkok nem a tárolóban vannak.

## Cikkek és kategóriák
- Cikkek: `blog/*.html` (EN) és `hu/blog/*.html` (HU), az eredeti slugokkal; kategóriák: `category/*.html` és `hu/kategoria/*.html`.
- Az eredeti Astra-sablon mért értékei a `style.css` 16. (cikk) és 17. (kategória) szakaszában; a cikkoldalak EB Garamond betűt is töltenek.
- Az előző/következő cikk csak a négy valódi cikk között lapoz (az eredeti utazós „bejegyzései” csak egy fotót tartalmazó, noindex oldalak: a Rólam oldal galériája mutatja őket).
- Az eredeti oldalsávjának keresőmezője a 404-es oldalra visz, ezért kimaradt; a Travel/Utazás kategória sincs (nincs mit listázni).
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

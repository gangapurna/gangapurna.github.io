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

<?php
/**
 * Beállítások a kapcsolati űrlaphoz (SABLON).
 *
 * HASZNÁLAT:
 *  1. Másold le ezt a fájlt "config.php" néven ugyanebbe a mappába (api/).
 *  2. Írd át az értékeket a sajátodra.
 *  3. A config.php-t a Hostingerre töltsd fel (hPanel → Fájlkezelő), de NE a GitHubra:
 *     a .gitignore már kizárja, így véletlenül sem kerül fel.
 *
 * Ez a sablon (config.example.php) feltölthető a GitHubra, mert nem tartalmaz titkot.
 */

return [
    // Ide érkeznek az üzenetek (a Hostingeren létező postafiók).
    'to' => 'gabor@gaborhorvath.eu',

    // A levél feladója: a SAJÁT domained egy címe (ez kell az SPF/DKIM-hez, különben spamnek minősülhet).
    // Nem kell, hogy külön postafiók legyen, de a domainhez tartozzon.
    'from' => 'weboldal@gaborhorvath.eu',
    'from_name' => 'gaborhorvath.eu',

    // Mely oldalakról fogadunk űrlapot (az Origin/Referer fejléc hosztneve). Éles oldalon csak a saját domain.
    'allowed_hosts' => ['gaborhorvath.eu', 'www.gaborhorvath.eu'],
    // Fejlesztéshez / előnézethez hozzáadható: 'localhost', '127.0.0.1', 'gangapurna.github.io' (a GitHub Pages előnézet)

    // Sebességkorlát: legfeljebb ennyi üzenet ennyi másodpercen belül egy IP-címről.
    'rate_limit_max' => 5,
    'rate_limit_window' => 3600,

    // Véletlen szöveg az IP-lenyomathoz. Cseréld le egy saját, hosszú, véletlen karakterláncra.
    'rate_salt' => 'CSERELD-LE-EGY-HOSSZU-VELETLEN-SZOVEGRE',
];

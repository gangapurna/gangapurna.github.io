<?php
/**
 * Kapcsolati űrlap feldolgozása – a Hostingeren futó PHP-szkript.
 *
 * Mit csinál: az űrlap adatait ellenőrzi, majd e-mailt küld a config.php-ban megadott címre.
 * Nem tárol semmit (nincs adatbázis, nincs naplófájl az üzenetekről).
 *
 * Védelmek (röviden, hogy később is érthető legyen):
 *  1. Csak POST kérést fogad el.
 *  2. Ellenőrzi, hogy a kérés a saját oldalról érkezik-e (Origin / Referer).
 *  3. "Méz-csapda" (honeypot) mező: a robotok kitöltik, az emberek nem látják.
 *  4. Időcsapda: az emberek legalább pár másodpercig töltik ki az űrlapot.
 *  5. Sebességkorlát IP-nként (néhány üzenet óránként).
 *  6. Minden bemenetet ellenőriz és megtisztít (különösen az e-mail fejléc-injektálás ellen:
 *     soremelés a névben vagy az e-mail-címben tiltott).
 *  7. A titkos beállítások (cím, jelszó) a config.php-ban vannak, amit NEM töltünk fel a GitHubra.
 */

declare(strict_types=1);

// ---------------------------------------------------------------------------------------------
// 0. Alapok
// ---------------------------------------------------------------------------------------------
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');
mb_internal_encoding('UTF-8');

$configFile = __DIR__ . '/config.php';
if (!is_file($configFile)) {
    http_response_code(500);
    error_log('[contact.php] Hiányzik az api/config.php. Másold le a config.example.php-t config.php néven.');
    exit('Server configuration error.');
}
/** @var array<string,mixed> $config */
$config = require $configFile;

// Nyelvfüggő szövegek (a "lang" mező alapján; minden más érték magyarra esik vissza az angol kivételével)
const MESSAGES = [
    'en' => [
        'ok'       => 'Thank you, your message has been sent! I’ll get back to you as soon as I can.',
        'error'    => 'Something went wrong while sending your message. Please try again, or write to me at %s.',
        'invalid'  => 'Please check the highlighted fields and try again.',
        'required' => 'This field is required.',
        'email'    => 'Please enter a valid e-mail address.',
        'toolong'  => 'This text is too long.',
        'rate'     => 'Too many messages in a short time. Please try again later.',
        'subject'  => 'New message from the website',
    ],
    'hu' => [
        'ok'       => 'Köszönöm, az üzeneted megérkezett! Amint tudok, válaszolok.',
        'error'    => 'Hiba történt az üzenet elküldésekor. Kérlek, próbáld újra, vagy írj a(z) %s címre.',
        'invalid'  => 'Kérlek, ellenőrizd a jelölt mezőket, és próbáld újra.',
        'required' => 'Ez a mező kötelező.',
        'email'    => 'Kérlek, adj meg érvényes e-mail-címet.',
        'toolong'  => 'Ez a szöveg túl hosszú.',
        'rate'     => 'Rövid idő alatt túl sok üzenet érkezett. Kérlek, próbáld meg később.',
        'subject'  => 'Új üzenet a weboldalról',
    ],
];

$lang = (($_POST['lang'] ?? '') === 'hu') ? 'hu' : 'en';
$t = MESSAGES[$lang];

// Az űrlap oldala (a sima, JavaScript nélküli visszairányításhoz)
$backPage = $lang === 'hu' ? '/hu/kapcsolat.html' : '/contact.html';

/** JSON-választ ad, ha a böngésző JavaScripttel kérte (Accept: application/json); különben visszairányít az űrlapra. */
function respond(int $status, string $state, string $message, array $errors = []): never
{
    global $backPage;
    $wantsJson = stripos($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json') !== false;
    if ($wantsJson) {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['status' => $state, 'message' => $message, 'errors' => $errors], JSON_UNESCAPED_UNICODE);
    } else {
        header('Location: ' . $backPage . '?status=' . rawurlencode($state) . '#drop-message', true, 303);
    }
    exit;
}

// ---------------------------------------------------------------------------------------------
// 1. Csak POST
// ---------------------------------------------------------------------------------------------
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit('Method Not Allowed');
}

// ---------------------------------------------------------------------------------------------
// 2. Honnan érkezik a kérés? (Origin / Referer ellenőrzés)
// ---------------------------------------------------------------------------------------------
$allowedHosts = (array)($config['allowed_hosts'] ?? []);
$source = $_SERVER['HTTP_ORIGIN'] ?? $_SERVER['HTTP_REFERER'] ?? '';
$sourceHost = $source !== '' ? (string)parse_url($source, PHP_URL_HOST) : '';
if ($sourceHost === '' || !in_array(strtolower($sourceHost), array_map('strtolower', $allowedHosts), true)) {
    http_response_code(403);
    exit('Forbidden');
}

// ---------------------------------------------------------------------------------------------
// 3. Bemenet beolvasása és megtisztítása
// ---------------------------------------------------------------------------------------------
$read = static function (string $key): string {
    $v = $_POST[$key] ?? '';
    return is_string($v) ? trim($v) : '';
};
$name    = $read('name');
$email   = $read('email');
$message = str_replace(["\r\n", "\r"], "\n", $read('message'));

// 3a. Méz-csapda: ha ez a rejtett mező ki van töltve, robot küldte → "sikert" mutatunk, de nem küldünk semmit.
if ($read('website') !== '') {
    respond(200, 'ok', $t['ok']);
}

// 3b. Időcsapda: az űrlap betöltése óta eltelt idő (ezredmásodpercben, a böngésző állítja be).
$loadedAt = (int)$read('t');
$nowMs = (int)(microtime(true) * 1000);
$elapsed = $nowMs - $loadedAt;
if ($loadedAt <= 0 || $elapsed < 3000 || $elapsed > 24 * 3600 * 1000) {
    // túl gyors (robot) vagy érvénytelen időbélyeg: ugyanúgy "sikert" mutatunk, de nem küldünk
    respond(200, 'ok', $t['ok']);
}

// 3c. Mezők ellenőrzése
$errors = [];
if ($name === '') {
    $errors['name'] = $t['required'];
} elseif (mb_strlen($name) > 100) {
    $errors['name'] = $t['toolong'];
} elseif (preg_match('/[\r\n\0]/', $name)) {
    $errors['name'] = $t['invalid'];          // soremelés = e-mail fejléc-injektálási kísérlet
}

if ($email === '') {
    $errors['email'] = $t['required'];
} elseif (mb_strlen($email) > 254 || preg_match('/[\r\n\0,;<>]/', $email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors['email'] = $t['email'];
}

if ($message === '') {
    $errors['message'] = $t['required'];
} elseif (mb_strlen($message) > 5000) {
    $errors['message'] = $t['toolong'];
} elseif (str_contains($message, "\0")) {
    $errors['message'] = $t['invalid'];
}

if ($errors) {
    respond(422, 'invalid', $t['invalid'], $errors);
}

// ---------------------------------------------------------------------------------------------
// 4. Sebességkorlát IP-címenként (fájl az ideiglenes mappában, nem a weboldal mappájában)
//    Az IP-címet nem tároljuk nyersen, csak egy visszafejthetetlen lenyomatot.
// ---------------------------------------------------------------------------------------------
$limitMax = (int)($config['rate_limit_max'] ?? 5);
$limitWindow = (int)($config['rate_limit_window'] ?? 3600);
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$bucket = sys_get_temp_dir() . '/contact-rate-' . hash('sha256', $ip . '|' . ($config['rate_salt'] ?? 'salt')) . '.json';
$now = time();
$hits = [];
$fh = @fopen($bucket, 'c+');
if ($fh !== false && flock($fh, LOCK_EX)) {
    $raw = stream_get_contents($fh);
    $decoded = $raw !== '' && $raw !== false ? json_decode($raw, true) : [];
    $hits = array_values(array_filter(is_array($decoded) ? $decoded : [], static fn ($ts) => is_int($ts) && $ts > $now - $limitWindow));
    if (count($hits) >= $limitMax) {
        flock($fh, LOCK_UN);
        fclose($fh);
        respond(429, 'rate', $t['rate']);
    }
    $hits[] = $now;
    ftruncate($fh, 0);
    rewind($fh);
    fwrite($fh, json_encode($hits));
    fflush($fh);
    flock($fh, LOCK_UN);
    fclose($fh);
}

// ---------------------------------------------------------------------------------------------
// 5. Levél összeállítása és elküldése
// ---------------------------------------------------------------------------------------------
$to      = (string)$config['to'];
$from    = (string)$config['from'];          // a saját domain egyik címe (SPF/DKIM miatt)
$fromName = (string)($config['from_name'] ?? 'Website');

/** E-mail fejlécben szereplő szöveg: soremelés nélkül, UTF-8 szerint kódolva. */
$headerText = static fn (string $s): string => '=?UTF-8?B?' . base64_encode(preg_replace('/[\r\n]+/', ' ', $s)) . '?=';

$subject = $t['subject'] . ': ' . mb_substr($name, 0, 60);
$body = "Név / Name: {$name}\n"
      . "E-mail: {$email}\n"
      . "Nyelv / Language: " . strtoupper($lang) . "\n"
      . "Időpont / Time: " . date('Y-m-d H:i:s') . ' (' . date_default_timezone_get() . ")\n"
      . str_repeat('-', 40) . "\n\n"
      . $message . "\n";

$headers = [
    'From: ' . $headerText($fromName) . ' <' . $from . '>',
    'Reply-To: ' . $headerText($name) . ' <' . $email . '>',   // a "Válasz" gomb a látogatónak válaszol
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
    'X-Mailer: gaborhorvath.eu contact form',
];

// A 5. paraméter (-f) a borítékcímet állítja be, hogy a levél a saját domainről menjen
$sent = @mail($to, $headerText($subject), $body, implode("\r\n", $headers), '-f' . $from);

if (!$sent) {
    // Személyes adatot nem naplózunk, csak azt, hogy a küldés nem sikerült.
    error_log('[contact.php] A mail() hívás sikertelen.');
    respond(500, 'error', sprintf($t['error'], $to));
}

respond(200, 'ok', $t['ok']);

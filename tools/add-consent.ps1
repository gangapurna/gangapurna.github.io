# Minden HTML-oldalra felteszi a suti-hozzajarulas szkriptet es a lablec "Suti-beallitasok" hivatkozasat. Idempotens.
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
$huText = 'S' + [char]0xFC + 'ti-be' + [char]0xE1 + 'll' + [char]0xED + 't' + [char]0xE1 + 's' + 'ok'
$n = 0
Get-ChildItem $root -Recurse -Filter *.html | ForEach-Object {
  $x = [IO.File]::ReadAllText($_.FullName, $utf8)
  $orig = $x
  if ($x -notmatch 'consent\.js') {
    $x = [regex]::Replace($x, '([ \t]*)<script src="([^"]*)assets/js/main\.js"></script>', { param($m) $m.Value + "`n" + $m.Groups[1].Value + '<script src="' + $m.Groups[2].Value + 'assets/js/consent.js"></script>' })
  }
  if ($x -notmatch 'data-cookie-open') {
    $label = if ($x -match '<html lang="hu"') { $huText } else { 'Cookie Preferences' }
    $x = [regex]::Replace($x, '(<p class="site-footer__copy container">.*?</a>)(</p>)', { param($m) $m.Groups[1].Value + ' &middot; <button type="button" class="link-btn" data-cookie-open>' + $label + '</button>' + $m.Groups[2].Value })
  }
  if ($x -ne $orig) { [IO.File]::WriteAllText($_.FullName, $x, $utf8); $n++ }
}
"$n fajl frissitve"

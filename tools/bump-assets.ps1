# Cache-busting: minden HTML-oldalon a style.css / main.js / consent.js / lang.js hivatkozasa utan beirja a fajl
# tartalmabol szamolt rovid ujegyet (pl. style.css?v=3fa9c1d2). Ha a fajl valtozik, a "v" is valtozik, igy a
# Hostinger CDN-je es a latogatok bongeszoje (7 napos gyorsitotar) azonnal az uj fajlt toltik le.
# Idempotens: ha semmi sem valtozott, semmit nem ir at. A make-upload-zip.ps1 automatikusan lefuttatja.
# Kezi futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\bump-assets.ps1
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)

$hash = @{}
foreach ($rel in 'assets/css/style.css', 'assets/js/main.js', 'assets/js/consent.js', 'assets/js/lang.js') {
  $raw = [IO.File]::ReadAllBytes((Join-Path $root ($rel -replace '/', '\')))
  # sorvegzodes-fuggetlen ujegy: a CRLF-et LF-nek vesszuk (a git "autocrlf" a munkafaban CRLF-re alakithatja a fajlokat,
  # ettol nem szabad valtoznia a hash-nek, mert a ?v= ertek bekerul az osszes HTML-be)
  $ms = New-Object IO.MemoryStream
  for ($i = 0; $i -lt $raw.Length; $i++) { if ($raw[$i] -eq 13 -and $i + 1 -lt $raw.Length -and $raw[$i + 1] -eq 10) { continue }; $ms.WriteByte($raw[$i]) }
  $bytes = $ms.ToArray()
  $sha = [Security.Cryptography.SHA1]::Create()
  $hash[$rel] = (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 8)
}

$pattern = '((?:href|src)="[^"]*?)(assets/(?:css/style\.css|js/(?:main|consent|lang)\.js))(\?v=[0-9a-f]+)?(")'
$changed = 0
Get-ChildItem $root -Recurse -Filter *.html | Where-Object { $_.FullName -notmatch '\\(\.git|tools|api)\\' } | ForEach-Object {
  $text = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
  $new = [regex]::Replace($text, $pattern, { param($m) $m.Groups[1].Value + $m.Groups[2].Value + '?v=' + $hash[$m.Groups[2].Value] + $m.Groups[4].Value })
  if ($new -ne $text) { [IO.File]::WriteAllText($_.FullName, $new, $utf8); $changed++ }
}
Write-Host "bump-assets: $changed oldal frissitve. style.css?v=$($hash['assets/css/style.css'])  main.js?v=$($hash['assets/js/main.js'])"

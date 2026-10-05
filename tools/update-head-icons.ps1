# Minden HTML-oldal <head>-jeben az ikon-hivatkozasok egy helyen: favicon.ico, SVG favicon, apple-touch-icon, web app manifest.
# Idempotens (a korabbi icon / apple-touch-icon / manifest sorokat lecsereli). Az utvonal-elotagot (../, ../../ vagy /) a
# meglevo ikon-hivatkozasbol veszi. A kepeket a tools\make-icons.ps1 gyartja.
# Futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\update-head-icons.ps1
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
$changed = 0
Get-ChildItem $root -Recurse -Filter *.html | Where-Object { $_.FullName -notmatch '\\(\.git|tools|api)\\' } | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
  $m = [regex]::Match($t, 'href="((?:\.\./)*|/)(?:assets/img/logo-gh-kicsi\.png|favicon\.ico)"')
  if (-not $m.Success) { throw "Nem talalhato az ikon-hivatkozas: $($_.FullName)" }
  $p = $m.Groups[1].Value
  $rx = '[ \t]*<link rel="(?:icon|apple-touch-icon|manifest)"[^>]*>\r?\n?'
  $first = [regex]::Match($t, $rx)
  $block = '  <link rel="icon" href="' + $p + 'favicon.ico" sizes="32x32">' + "`n" +
           '  <link rel="icon" href="' + $p + 'assets/img/icons/favicon.svg" type="image/svg+xml">' + "`n" +
           '  <link rel="apple-touch-icon" href="' + $p + 'assets/img/icons/apple-touch-icon.png">' + "`n" +
           '  <link rel="manifest" href="' + $p + 'site.webmanifest">' + "`n"
  $without = [regex]::Replace($t, $rx, '')
  $new = $without.Insert($first.Index, $block)
  if ($new -ne $t) { [IO.File]::WriteAllText($_.FullName, $new, $utf8); $changed++ }
}
Write-Host "update-head-icons: $changed oldal frissitve."

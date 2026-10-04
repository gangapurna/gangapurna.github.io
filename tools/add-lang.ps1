# Minden HTML-oldal <head>-jebe beteszi az automatikus nyelvvalaszto szkriptet (a stiluslap elé). Idempotens.
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
$n = 0
Get-ChildItem $root -Recurse -Filter *.html | ForEach-Object {
  $x = [IO.File]::ReadAllText($_.FullName, $utf8)
  if ($x -match 'assets/js/lang\.js') { return }
  $x = [regex]::Replace($x, '([ \t]*)(<link rel="preload" href="([^"]*)assets/fonts/aclonica-latin\.woff2")', { param($m) $m.Groups[1].Value + '<script src="' + $m.Groups[3].Value + 'assets/js/lang.js"></script>' + "`n" + $m.Groups[1].Value + $m.Groups[2].Value }, 'None')
  [IO.File]::WriteAllText($_.FullName, $x, $utf8)
  $n++
}
"$n fajl frissitve"

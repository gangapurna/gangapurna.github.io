# Portfolio-idovonal: minden allasnal az elso 2 felsorolas latszik, a tobbi <details class="tl-more"> mezoben
# ("Tovabb" / "Kevesebb", EN: "More" / "Less"), a WP-oldal gh-more mintajara. Idempotens (az ujrafuttatas nem valtoztat).
# Futtatas: powershell -ExecutionPolicy Bypass -File .\tools\update-timeline.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$keep = 2    # ennyi felsorolas latszik a gomb elott

$pages = @(
  @{ file = 'portfolio.html';    on = 'More';                          off = 'Less' },
  @{ file = 'hu\portfolio.html'; on = ('Tov' + [char]0xE1 + 'bb');    off = 'Kevesebb' }
)

foreach ($pg in $pages) {
  $path = Join-Path $root $pg.file
  $t = [IO.File]::ReadAllText($path, $utf8)
  if ($t -match '</ul>\s*<details class="tl-more">') { "$($pg.file): mar atalakitva"; continue }
  $nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
  $n = 0

  $t = [regex]::Replace($t, '(?s)<article class="tl-item reveal">.*?</article>', {
    param($m)
    $a = $m.Value
    if ($a -match 'tl-head--inline') { return $a }
    # a felsorolas helye: vagy mar <details> kozott (2-4. allas), vagy sima <ul> (1. allas)
    $rx = '(?s)<details class="tl-more"><summary class="tl-more__sum">.*?</summary><ul class="tl-list">(.*?)</ul></details>'
    $mm = [regex]::Match($a, $rx)
    if (-not $mm.Success) { $mm = [regex]::Match($a, '(?s)<ul class="tl-list">(.*?)</ul>') }
    if (-not $mm.Success) { return $a }
    $lis = [regex]::Matches($mm.Groups[1].Value, '(?s)<li>.*?</li>') | ForEach-Object { $_.Value }
    if ($lis.Count -le $keep) { return $a }
    $first = ($lis | Select-Object -First $keep) -join ($nl + '                ')
    $rest  = ($lis | Select-Object -Skip $keep)  -join ($nl + '                ')
    $new = '<ul class="tl-list">' + $nl + '                ' + $first + $nl + '              </ul>' + $nl +
           '              <details class="tl-more"><summary class="tl-more__sum"><span class="tl-more__open">' + $pg.on +
           '</span><span class="tl-more__close">' + $pg.off + '</span></summary><ul class="tl-list">' + $nl +
           '                ' + $rest + $nl + '              </ul></details>'
    $script:n++
    return $a.Substring(0, $mm.Index) + $new + $a.Substring($mm.Index + $mm.Length)
  })

  [IO.File]::WriteAllText($path, $t, $utf8)
  "$($pg.file): $n allas atalakitva"
}

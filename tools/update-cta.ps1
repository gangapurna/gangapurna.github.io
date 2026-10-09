# Cikkek vege: kapcsolatfelvételi felhivas ("Kerdesed van?" / "Questions?") a szerzoi doboz elott.
# Idempotens (ha mar van post-cta, nem nyul a fajlhoz). Futtatas: powershell -ExecutionPolicy Bypass -File .\tools\update-cta.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
function U($s) { [regex]::Unescape($s) }

$en = @{
  title = 'Questions, or an idea to talk through?'
  text  = 'Whether it is a security system, the IT network behind it or just a thought on this article, I am happy to hear from you.'
  btn   = 'Get in touch'
  href  = '../contact.html'
}
$hu = @{
  title = (U 'Kérdésed van, vagy átbeszélnéd valamelyik témát?')
  text  = (U 'Legyen szó biztonsági rendszerről, a mögötte lévő informatikai hálózatról vagy egy gondolatról ezekből a cikkekből, szívesen meghallgatlak.')
  btn   = (U 'Kapcsolatfelvétel')
  href  = '../kapcsolat.html'
}

$files = @(Get-ChildItem (Join-Path $root 'blog') -Filter *.html) + @(Get-ChildItem (Join-Path $root 'hu\blog') -Filter *.html)
$changed = 0
foreach ($f in $files) {
  $t = [IO.File]::ReadAllText($f.FullName, $utf8)
  if ($t -match 'class="post-cta"') { continue }
  if ($t -notmatch '<section class="author"') { "kihagyva (nincs szerzoi doboz): $($f.Name)"; continue }
  $c = if ($f.FullName -like '*\hu\blog\*') { $hu } else { $en }
  $nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
  $ind = '            '
  $block = $ind + '<section class="post-cta" aria-labelledby="cta-title">' + $nl +
           $ind + '  <h2 class="post-cta__title" id="cta-title">' + $c.title + '</h2>' + $nl +
           $ind + '  <p class="post-cta__text">' + $c.text + '</p>' + $nl +
           $ind + '  <a class="post-cta__btn" href="' + $c.href + '"><svg aria-hidden="true"><use href="#contact"/></svg>' + $c.btn + '</a>' + $nl +
           $ind + '</section>' + $nl + $nl
  $marker = $ind + '<section class="author"'
  $i = $t.IndexOf($marker)
  if ($i -lt 0) { "kihagyva (jelolo nem talalhato): $($f.Name)"; continue }
  $t = $t.Insert($i, $block)
  [IO.File]::WriteAllText($f.FullName, $t, $utf8)
  $changed++
}
"update-cta: $changed cikk frissitve"

# Cikkek: becsult olvasasi ido (a cikkoldal meta-soraban, a kategoria-kartyakon, a fooldali cikkkartyakon) es
# "Kapcsolodo cikkek" blokk a cikkek vegen (azonos kategoria elore, aztan a legujabbak; legfeljebb 2 kartya).
# Idempotens: a korabbi beszurasokat eltavolitja, majd ujra felepiti. Uj cikk utan futtasd ujra.
# Az olvasasi ido a cikk szovegebol szamolodik (EN: 200 szo/perc, HU: 180 szo/perc, felfele kerekitve, legalabb 1 perc).
# A fooldali cikkkartyak (index.html, hu/index.html) adjak a cimet, kivonatot, kepet es datumot.
# Futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\update-articles.ps1
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
function ReadU($p) { [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }
function WriteU($p, $t) { [IO.File]::WriteAllText($p, $t, $utf8) }

$langs = @(
  @{ code = 'en'; home = 'index.html'; blog = 'blog'; cat = 'category'; up = '../'; wpm = 200
     related = 'Related articles'; read = 'min read' },
  @{ code = 'hu'; home = 'hu\index.html'; blog = 'hu\blog'; cat = 'hu\kategoria'; up = '../../'; wpm = 180
     related = ('Kapcsol' + [char]0xF3 + 'd' + [char]0xF3 + ' cikkek'); read = ('perc olvas' + [char]0xE1 + 's') }
)

foreach ($L in $langs) {
  # 1) a fooldali kartyak: cim, kivonat, kep, datum
  $homeHtml = ReadU (Join-Path $root $L.home)
  $homeHtml = [regex]::Replace($homeHtml, '<div class="post-card__meta">(<time[^>]*>[^<]*</time>)<span class="post-card__read">[^<]*</span></div>', '$1')
  $rx = '(?s)<li class="post-card[^"]*">\s*<a class="post-card__img" href="blog/([^"]+)"[^>]*><img src="(?:\.\./)?(assets/img/[^"]+)"[^>]*></a>\s*<div class="post-card__body">\s*<time class="post-card__date" datetime="([^"]+)">([^<]*)</time>\s*<h3 class="post-card__title"><a href="[^"]*">(.*?)</a></h3>\s*<p class="post-card__excerpt">(.*?)</p>'
  $info = @{}
  foreach ($m in [regex]::Matches($homeHtml, $rx)) {
    $info[$m.Groups[1].Value] = @{ slug = $m.Groups[1].Value; img = $m.Groups[2].Value; dt = $m.Groups[3].Value; date = $m.Groups[4].Value; title = $m.Groups[5].Value; excerpt = $m.Groups[6].Value }
  }
  if ($info.Count -lt 2) { throw "Nem talalhatok fooldali cikkkartyak: $($L.home)" }

  # 2) olvasasi ido es kategoria a cikkoldalakbol
  $blogDir = Join-Path $root $L.blog
  foreach ($slug in @($info.Keys)) {
    $t = ReadU (Join-Path $blogDir $slug)
    $content = [regex]::Match($t, '(?s)<div class="post__content">(.*?)<section class="author"').Groups[1].Value
    $content = [regex]::Replace($content, '(?s)<aside class="post__tldr".*?</aside>', '')       # az osszefoglalo doboz nem szamit az olvasasi idobe
    $words = ([regex]::Replace($content, '<[^>]+>', ' ') -split '\s+' | Where-Object { $_ }).Count
    $info[$slug].min = [Math]::Max(1, [int][Math]::Ceiling($words / $L.wpm))
    $info[$slug].cat = [regex]::Match($t, '(?s)class="post__meta">.*?<a href="[^"]*category[^"]*"[^>]*>(.*?)</a>').Groups[1].Value
    if (-not $info[$slug].cat) { $info[$slug].cat = [regex]::Match($t, '(?s)class="post__meta">.*?<a href="[^"]*kategoria[^"]*"[^>]*>(.*?)</a>').Groups[1].Value }
  }

  # 3) cikkoldalak: meta + kapcsolodo cikkek
  foreach ($slug in @($info.Keys)) {
    $path = Join-Path $blogDir $slug
    $t = ReadU $path
    $t = [regex]::Replace($t, ' / <span class="post__read">[^<]*</span>', '')
    $t = [regex]::Replace($t, '(?s)\s*<section class="related".*?</section>', '')
    $t = [regex]::Replace($t, '(?s)(<p class="post__meta">.*?)(</p>)', ('$1 / <span class="post__read">' + $info[$slug].min + ' ' + $L.read + '</span>$2'), 1)
    $others = $info.Values | Where-Object { $_.slug -ne $slug }
    $sorted = @($others | Sort-Object @{ Expression = { if ($_.cat -eq $info[$slug].cat) { 0 } else { 1 } } }, @{ Expression = { $_.dt }; Descending = $true })
    $pick = $sorted | Select-Object -First 2
    $cards = foreach ($r in $pick) {
      '          <article class="related-card">' + "`n" +
      '            <a class="related-card__img" href="' + $r.slug + '" tabindex="-1" aria-hidden="true"><img src="' + $L.up + $r.img + '" width="768" height="512" loading="lazy" alt=""></a>' + "`n" +
      '            <h3 class="related-card__title"><a href="' + $r.slug + '">' + $r.title + '</a></h3>' + "`n" +
      '            <p class="related-card__meta"><time datetime="' + $r.dt + '">' + $r.date + '</time> / <span>' + $r.min + ' ' + $L.read + '</span></p>' + "`n" +
      '            <p class="related-card__text">' + $r.excerpt + '</p>' + "`n" +
      '          </article>'
    }
    $block = "`n" + '        <section class="related" aria-labelledby="related-title">' + "`n" +
             '          <h2 class="related__title" id="related-title">' + $L.related + '</h2>' + "`n" +
             '          <div class="related__grid">' + "`n" + ($cards -join "`n") + "`n" + '          </div>' + "`n" +
             '        </section>'
    $t2 = [regex]::Replace($t, '(?s)(<nav class="post-nav".*?</nav>)', ('$1' + $block.Replace('$', '$$')), 1)
    if ($t2 -eq $t) { throw "Nem talalhato a post-nav: $path" }
    WriteU $path $t2
  }

  # 4) kategoria-kartyak: olvasasi ido a meta-sorban
  foreach ($f in Get-ChildItem (Join-Path $root $L.cat) -Filter *.html) {
    $t = ReadU $f.FullName
    $t = [regex]::Replace($t, ' / <span class="arch-card__read">[^<]*</span>', '')
    $t = [regex]::Replace($t, '(?s)(<article class="arch-card">.*?<h2 class="arch-card__title"><a href="\.\./blog/([^"]+)">.*?<p class="arch-card__meta">)(.*?)(</p>)', {
      param($m) $s = $m.Groups[2].Value; if ($info.ContainsKey($s)) { $m.Groups[1].Value + $m.Groups[3].Value + ' / <span class="arch-card__read">' + $info[$s].min + ' ' + $L.read + '</span>' + $m.Groups[4].Value } else { $m.Value } })
    WriteU $f.FullName $t
  }

  # 5) fooldali kartyak: olvasasi ido a datum mellett
  $homeHtml = ReadU (Join-Path $root $L.home)
  $homeHtml = [regex]::Replace($homeHtml, '<div class="post-card__meta">(<time[^>]*>[^<]*</time>)<span class="post-card__read">[^<]*</span></div>', '$1')
  $homeHtml = [regex]::Replace($homeHtml, '(?s)(<a class="post-card__img" href="blog/([^"]+)".*?)(<time class="post-card__date"[^>]*>[^<]*</time>)', {
    param($m) $s = $m.Groups[2].Value; if ($info.ContainsKey($s)) { $m.Groups[1].Value + '<div class="post-card__meta">' + $m.Groups[3].Value + '<span class="post-card__read">' + $info[$s].min + ' ' + $L.read + '</span></div>' } else { $m.Value } })
  WriteU (Join-Path $root $L.home) $homeHtml
  Write-Host ("update-articles [" + $L.code + "]: " + (($info.Values | Sort-Object dt | ForEach-Object { $_.slug + '=' + $_.min + 'p' }) -join ', '))
}

param([string]$Base = 'https://site.gaborhorvath.eu')
# Idempotens: a canonical / hreflang / Open Graph blokkot es a robots.txt + sitemap.xml-t allitja elo.
# Ujrafuttathato barmikor (pl. oldal-ujragenealas utan); a Base parameterrel a domain egy helyen cserelheto.
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
Set-Location $root

$og = @{
  'en'        = @('assets/img/og/og-kep-en.jpg', 1200, 630)
  'hu'        = @('assets/img/og/og-kep-hu.jpg', 1200, 630)
  'cyber'     = @('assets/img/og/og-cyber-physical.jpg', 1536, 1024)
  'video'     = @('assets/img/og/og-video-evidence.jpg', 1920, 800)
  'camera'    = @('assets/img/og/og-ip-camera.jpg', 1920, 800)
  'genai'     = @('assets/img/og/og-generative-ai.jpg', 1920, 800)
}

# [en-fajl, hu-fajl, og-kulcs-en, og-kulcs-hu, tipus, datum]
$pairs = @(
  @('index.html', 'hu/index.html', 'en', 'hu', 'website', ''),
  @('portfolio.html', 'hu/portfolio.html', 'en', 'hu', 'website', ''),
  @('about.html', 'hu/rolam.html', 'en', 'hu', 'website', ''),
  @('contact.html', 'hu/kapcsolat.html', 'en', 'hu', 'website', ''),
  @('blog/cyber-physical-security-convergence.html', 'hu/blog/kiber-es-fizikai-biztonsag-osszefonodasa.html', 'cyber', 'cyber', 'article', '2026-10-02'),
  @('blog/video-evidence-camera-to-courtroom.html', 'hu/blog/videobizonyitek-kameratol-a-targyaloteremig.html', 'video', 'video', 'article', '2026-09-26'),
  @('blog/ip-camera-network-security.html', 'hu/blog/ip-kamera-halozati-biztonsag.html', 'camera', 'camera', 'article', '2026-09-20'),
  @('blog/generative-ai-in-security-engineering.html', 'hu/blog/generativ-ai-a-biztonsagtechnikaban.html', 'genai', 'genai', 'article', '2026-09-14'),
  @('category/security-engineering.html', 'hu/kategoria/biztonsagtechnika.html', 'en', 'hu', 'website', ''),
  @('category/generative-ai.html', 'hu/kategoria/generativ-ai.html', 'en', 'hu', 'website', '')
)

function UrlOf($file) {
  if ($file -eq 'index.html') { return "$Base/" }
  if ($file -eq 'hu/index.html') { return "$Base/hu/" }
  "$Base/$file"
}

$smItems = @()
foreach ($p in $pairs) {
  $enUrl = UrlOf $p[0]; $huUrl = UrlOf $p[1]
  foreach ($side in 0, 1) {
    $file = $p[$side]; $lang = @('en', 'hu')[$side]; $self = @($enUrl, $huUrl)[$side]
    $x = [IO.File]::ReadAllText("$root\$file", $utf8)
    $title = [regex]::Match($x, '<title>(.*?)</title>').Groups[1].Value
    $descM = [regex]::Match($x, '<meta name="description" content="([^"]*)"')
    $ogk = $og[$p[2 + $side]]
    $img = "$Base/$($ogk[0])"
    $loc = if ($lang -eq 'en') { 'en_US' } else { 'hu_HU' }
    $loc2 = if ($lang -eq 'en') { 'hu_HU' } else { 'en_US' }
    $L = @()
    $L += '  <!-- SEO:start (a tools/seo.ps1 generalja, kezzel ne szerkeszd) -->'
    $L += "  <link rel=`"canonical`" href=`"$self`">"
    $L += "  <link rel=`"alternate`" hreflang=`"en`" href=`"$enUrl`">"
    $L += "  <link rel=`"alternate`" hreflang=`"hu`" href=`"$huUrl`">"
    $L += "  <link rel=`"alternate`" hreflang=`"x-default`" href=`"$enUrl`">"
    $L += "  <meta property=`"og:type`" content=`"$($p[4])`">"
    $L += "  <meta property=`"og:site_name`" content=`"$(if ($lang -eq 'en') { 'Gabor Horvath' } else { 'Horv' + [char]0xE1 + 'th G' + [char]0xE1 + 'bor' })`">"
    $L += "  <meta property=`"og:title`" content=`"$title`">"
    if ($descM.Success) { $L += "  <meta property=`"og:description`" content=`"$($descM.Groups[1].Value)`">" }
    $L += "  <meta property=`"og:url`" content=`"$self`">"
    $L += "  <meta property=`"og:image`" content=`"$img`">"
    $L += "  <meta property=`"og:image:width`" content=`"$($ogk[1])`">"
    $L += "  <meta property=`"og:image:height`" content=`"$($ogk[2])`">"
    $L += "  <meta property=`"og:locale`" content=`"$loc`">"
    $L += "  <meta property=`"og:locale:alternate`" content=`"$loc2`">"
    if ($p[4] -eq 'article') { $L += "  <meta property=`"article:published_time`" content=`"$($p[5])`">" }
    $L += '  <meta name="twitter:card" content="summary_large_image">'
    $L += '  <!-- SEO:end -->'
    $block = ($L -join "`n")
    # regi blokk + regi (relativ) hreflang sorok torlese
    $x = [regex]::Replace($x, '(?s)[ \t]*<!-- SEO:start.*?<!-- SEO:end -->\r?\n?', '')
    $x = [regex]::Replace($x, '[ \t]*<link rel="alternate" hreflang="[^"]*" href="[^"]*">\r?\n', '')
    $x = [regex]::Replace($x, '(  <meta name="theme-color"[^>]*>\r?\n)', { param($m) $m.Groups[1].Value + $block + "`n" })
    $x = [regex]::Replace($x, '(\r?\n){3,}', "`n`n")
    [IO.File]::WriteAllText("$root\$file", $x, $utf8)
  }
  $smItems += , @($p[0], $p[1], $enUrl, $huUrl)
}

# sitemap.xml (hreflang-parokkal)
$sm = New-Object System.Text.StringBuilder
[void]$sm.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sm.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">')
foreach ($it in $smItems) {
  foreach ($side in 0, 1) {
    $file = $it[$side]
    $last = (& git log -1 --format=%cs -- $file).Trim()
    if (-not $last) { $last = (Get-Date -Format 'yyyy-MM-dd') }
    [void]$sm.AppendLine('  <url>')
    [void]$sm.AppendLine("    <loc>$($it[2 + $side])</loc>")
    [void]$sm.AppendLine("    <lastmod>$last</lastmod>")
    [void]$sm.AppendLine("    <xhtml:link rel=`"alternate`" hreflang=`"en`" href=`"$($it[2])`"/>")
    [void]$sm.AppendLine("    <xhtml:link rel=`"alternate`" hreflang=`"hu`" href=`"$($it[3])`"/>")
    [void]$sm.AppendLine("    <xhtml:link rel=`"alternate`" hreflang=`"x-default`" href=`"$($it[2])`"/>")
    [void]$sm.AppendLine('  </url>')
  }
}
[void]$sm.AppendLine('</urlset>')
[IO.File]::WriteAllText("$root\sitemap.xml", $sm.ToString(), $utf8)

$robots = "User-agent: *`nAllow: /`nDisallow: /api/`n`nSitemap: $Base/sitemap.xml`n"
[IO.File]::WriteAllText("$root\robots.txt", $robots, $utf8)
"kesz: $($smItems.Count * 2) oldal, sitemap.xml, robots.txt ($Base)"

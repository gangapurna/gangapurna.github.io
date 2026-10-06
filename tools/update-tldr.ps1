# "Röviden" / "In short" összefoglaló doboz a cikkekben (a bevezető után, az első alcím előtt). Idempotens: a meglévő dobozt lecseréli.
# A szöveg a cikkből készült (3-3 pont cikkenként és nyelvenként); új cikknél vagy szövegmódosításnál itt kell frissíteni.
# Futtatás:   powershell -ExecutionPolicy Bypass -File .\tools\update-tldr.ps1   (utána: tools\update-articles.ps1, tools\bump-assets.ps1)
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)

$data = @(
  @{ file = 'blog\cyber-physical-security-convergence.html'; title = 'In short'; points = @(
      'Cyber and physical security have converged: security professionals increasingly have to think like IT security people.',
      'Networked surveillance and access control systems must not become a vulnerable point in the IT infrastructure.',
      'When intelligence moves to the network edge (for example the Suprema BioStation 3 Max), well-protected endpoints are a must; this is where Zero Trust becomes physical reality.') },
  @{ file = 'hu\blog\kiber-es-fizikai-biztonsag-osszefonodasa.html'; title = 'Röviden'; points = @(
      'A kiber- és a fizikai biztonság összeért: a biztonságtechnikai szakembereknek egyre inkább informatikai biztonsági módon is kell gondolkodniuk.',
      'A hálózatra kötött megfigyelő- és beléptetőrendszerek nem válhatnak sérülékeny ponttá az IT-infrastruktúrában.',
      'Ahol az intelligencia a hálózat peremére kerül (például a Suprema BioStation 3 Max esetében), ott a végpontok védelme alapkövetelmény; itt válik kézzelfogható fizikai valósággá a Zero Trust.') },

  @{ file = 'blog\video-evidence-camera-to-courtroom.html'; title = 'In short'; points = @(
      'The trustworthiness of a recording can break at four points: creation in the camera, storage, access and release.',
      'In Boston the chain broke at access: the manufacturer switched on nationwide lookup “in error”, although the contract prohibited sharing.',
      'The evidential value of footage depends on the weakest link, so all four points of its journey have to be designed in advance.') },
  @{ file = 'hu\blog\videobizonyitek-kameratol-a-targyaloteremig.html'; title = 'Röviden'; points = @(
      'A videofelvétel hitelessége négy ponton törhet meg: a keletkezésnél a kamerában, a tárolásnál, a hozzáférésnél és a kiadásnál.',
      'Bostonban a lánc a hozzáférésnél szakadt el: a gyártó „tévedésből” bekapcsolta az országos keresést, pedig a szerződés tiltotta a megosztást.',
      'A felvétel bizonyító ereje a leggyengébb láncszemen múlik, ezért a felvétel útjának mind a négy pontját előre végig kell gondolni.') },

  @{ file = 'blog\ip-camera-network-security.html'; title = 'In short'; points = @(
      'A modern IP camera or recorder is a fully fledged computer: it can be attacked like any server, from the network or physically.',
      'Two September cases showed both sides: a recorder that can be taken over from the local network, and a camera taken down from its pole with its keys extracted.',
      'The countermeasures are well established: a separate network, VPN-only remote access, unique passwords, 802.1X, firmware lifecycle management and as little data as possible on the device.') },
  @{ file = 'hu\blog\ip-kamera-halozati-biztonsag.html'; title = 'Röviden'; points = @(
      'A modern IP-kamera vagy rögzítő teljes értékű számítógép: ugyanúgy támadható, mint bármelyik szerver, akár a hálózat felől, akár fizikailag.',
      'Két szeptemberi eset mutatta mindkét oldalt: egy rögzítő, amelyet a helyi hálózatról át lehet venni, és egy kamera, amelyet leszereltek az oszlopról, és kinyerték belőle a kulcsokat.',
      'Az ellenintézkedések régóta ismertek: külön hálózat, távoli elérés csak VPN-en, egyedi jelszavak, 802.1X, firmware-életciklus és minél kevesebb adat az eszközön.') },

  @{ file = 'blog\generative-ai-in-security-engineering.html'; title = 'In short'; points = @(
      'A language model calculates the most likely continuation of a text, with no intent and no verification behind it: it is confidently wrong, so every technical figure has to be checked.',
      'It genuinely speeds up documentation, quotations, data analysis and development; the professional content and the responsibility stay with the engineer.',
      'Confidential client data does not go into a public AI service, and engineering responsibility cannot be delegated.') },
  @{ file = 'hu\blog\generativ-ai-a-biztonsagtechnikaban.html'; title = 'Röviden'; points = @(
      'A nyelvi modell a szöveg legvalószínűbb folytatását számolja ki, szándék és ellenőrzés nélkül: magabiztosan téved, ezért minden műszaki adatot ellenőrizni kell.',
      'Valóban gyorsítja a dokumentációt, az árajánlatok szövegezését, az adatelemzést és a fejlesztést; a szakmai tartalom és a felelősség a mérnöké marad.',
      'Bizalmas ügyféladat nem kerül nyilvános AI-szolgáltatásba, és a mérnöki felelősség nem delegálható.') }
)

$changed = 0
foreach ($d in $data) {
  $f = Join-Path $root $d.file
  $t = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)
  $o = $t
  $t = [regex]::Replace($t, '(?s)[ \t]*<aside class="post__tldr".*?</aside>\s*', '            ')
  $start = $t.IndexOf('<div class="post__content">')
  if ($start -lt 0) { throw "Nincs post__content: $f" }
  $h2 = $t.IndexOf('<h2>', $start)
  if ($h2 -lt 0) { throw "Nincs alcim: $f" }
  $lis = ($d.points | ForEach-Object { '<li>' + $_ + '</li>' }) -join "`n                "
  $box = '<aside class="post__tldr" aria-label="' + $d.title + '">' + "`n" +
         '              <p class="post__tldr-title" aria-hidden="true">' + $d.title + '</p>' + "`n" +
         '              <ul>' + "`n" + '                ' + $lis + "`n" + '              </ul>' + "`n" +
         '            </aside>' + "`n`n" + '            '
  $t = $t.Insert($h2, $box)
  if ($t -ne $o) { [IO.File]::WriteAllText($f, $t, $utf8); $changed++ }
}
Write-Host "update-tldr: $changed cikk frissitve."

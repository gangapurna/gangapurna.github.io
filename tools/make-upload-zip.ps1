# Egy paranccsal elkészíti a Hostinger-feltöltő csomagot: ..\hostinger-feltoltes\site.zip
# Futtatás (VS Code terminál, a projekt mappájában):   powershell -ExecutionPolicy Bypass -File .\tools\make-upload-zip.ps1
# (A Windows alapból tiltja a szkriptek futtatását; az -ExecutionPolicy Bypass csak erre az egy futtatásra oldja fel.)
# A csomagba az oldal fájljai kerülnek; NEM kerül bele: api (az a fő domainen van), tools, README, .git.
$root = Split-Path -Parent $PSScriptRoot
# a gyorsítótár-azonosítók (?v=...) frissítése, hogy a CDN és a böngészők az új CSS/JS-t töltsék le
& (Join-Path $PSScriptRoot 'bump-assets.ps1')
$out = Join-Path (Split-Path -Parent $root) 'hostinger-feltoltes'
New-Item -ItemType Directory -Force $out | Out-Null
$zip = Join-Path $out 'site.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Set-Location $root
$items = @('index.html', '404.html', 'about.html', 'portfolio.html', 'contact.html', 'robots.txt', 'sitemap.xml', 'favicon.ico', 'site.webmanifest', '.htaccess', 'assets', 'blog', 'category', 'hu')
# a Windows beépített tar.exe-je helyes (előre perjeles) útvonalakkal készít zipet, a Compress-Archive nem
& "$env:SystemRoot\System32\tar.exe" -a -c -f $zip @items
$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Kesz: $zip ($mb MB)"

# Ugyanennek a tartalomnak a kicsomagolt valtozata is: ..\hostinger-feltoltes\site-mappa
# (a Hostinger szerveroldali kicsomagolasa egyszer ismetelten 500-as hibaval megszakadt; ilyenkor a mappa tartalma kozvetlenul feltoltheto).
# A robocopy /MIR tukrozi a forrast: az ujat masolja, a regi, mar nem letezo fajlokat torli a site-mappabol.
$dir = Join-Path $out 'site-mappa'
New-Item -ItemType Directory -Force $dir | Out-Null
foreach ($it in $items) {
  $src = Join-Path $root $it
  if (Test-Path $src -PathType Container) {
    & robocopy $src (Join-Path $dir $it) /MIR /NJH /NJS /NDL /NP /NFL | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy hiba ($LASTEXITCODE): $it" }
  } else {
    Copy-Item $src (Join-Path $dir $it) -Force
  }
}
# a gyokerben maradt, mar nem a csomaghoz tartozo fajlok eltavolitasa
Get-ChildItem $dir -File -Force | Where-Object { $items -notcontains $_.Name } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
$cnt = (Get-ChildItem $dir -Recurse -File -Force | Measure-Object).Count
Write-Host "Kesz: $dir ($cnt fajl, ugyanaz a tartalom, mint a zipben)"

Write-Host ""
Write-Host "Feltoltes a Hostingerre (hPanel -> Fajlkezelo -> public_html/site):"
Write-Host "  1. mod: site.zip feltoltese, majd Kicsomagolas (a mappa elotte legyen ures, a rejtett fajlokkal egyutt)."
Write-Host "  2. mod (ha a kicsomagolas 500-as hibat ad): a site-mappa TARTALMANAK (Ctrl+A, a rejtett elemek megjelenitesevel) huzasa a bongeszoablakba."
Start-Process explorer.exe $out

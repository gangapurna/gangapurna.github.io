# Egy paranccsal elkészíti a Hostinger-feltöltő csomagot: ..\hostinger-feltoltes\site.zip
# Futtatás (VS Code terminál, a projekt mappájában):   powershell -ExecutionPolicy Bypass -File .\tools\make-upload-zip.ps1
# (A Windows alapból tiltja a szkriptek futtatását; az -ExecutionPolicy Bypass csak erre az egy futtatásra oldja fel.)
# A csomagba az oldal fájljai kerülnek; NEM kerül bele: api (az a fő domainen van), tools, README, .git.
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path (Split-Path -Parent $root) 'hostinger-feltoltes'
New-Item -ItemType Directory -Force $out | Out-Null
$zip = Join-Path $out 'site.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Set-Location $root
$items = @('index.html', '404.html', 'about.html', 'portfolio.html', 'contact.html', 'robots.txt', 'sitemap.xml', '.htaccess', 'assets', 'blog', 'category', 'hu')
# a Windows beépített tar.exe-je helyes (előre perjeles) útvonalakkal készít zipet, a Compress-Archive nem
& "$env:SystemRoot\System32\tar.exe" -a -c -f $zip @items
$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Kesz: $zip ($mb MB)"
Write-Host "Kovetkezo lepes: hPanel -> Fajlkezelo -> public_html/site -> Feltoltes -> Kicsomagolas (felulirja a regi fajlokat)."
Start-Process explorer.exe $out

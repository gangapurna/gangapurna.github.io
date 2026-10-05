# Az SVG-logobol (assets/img/icons/favicon.svg) legyartja a PNG/ICO ikonokat Chrome (headless) segitsegevel:
#   favicon-16.png, favicon-32.png, favicon-48.png (atlatszo hatter), favicon.ico (16+32+48, a gyokerbe),
#   apple-touch-icon.png (180x180), icon-192.png, icon-512.png (fekete csempe, a kor a 80%-a: a "maskable" biztonsagi zonaban)
# Futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\make-icons.ps1      (csak akkor kell, ha a logo/SVG valtozik)
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root 'assets\img\icons'
$svg = [IO.File]::ReadAllBytes((Join-Path $dir 'favicon.svg'))
$b64 = [Convert]::ToBase64String($svg)
. (Join-Path (Split-Path -Parent $root) 'eszkozok\cdp-lib.ps1')
Start-Cdp 9651
$items = @(
  @{ name = 'favicon-16.png'; size = 16; tile = $false },
  @{ name = 'favicon-32.png'; size = 32; tile = $false },
  @{ name = 'favicon-48.png'; size = 48; tile = $false },
  @{ name = 'apple-touch-icon.png'; size = 180; tile = $true },
  @{ name = 'icon-192.png'; size = 192; tile = $true },
  @{ name = 'icon-512.png'; size = 512; tile = $true }
)
try {
  Send-Cdp 'Page.enable' | Out-Null
  foreach ($it in $items) {
    $s = $it.size
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $s; height = $s; deviceScaleFactor = 1; mobile = $false } | Out-Null
    if ($it.tile) {
      Send-Cdp 'Emulation.setDefaultBackgroundColorOverride' @{ color = @{ r = 11; g = 11; b = 11; a = 1 } } | Out-Null
      $img = [int]($s * 0.8); $off = [int](($s - $img) / 2)
      $html = "<html><body style='margin:0;background:#0B0B0B'><img src='data:image/svg+xml;base64,$b64' style='position:absolute;left:${off}px;top:${off}px;width:${img}px;height:${img}px'></body></html>"
    } else {
      Send-Cdp 'Emulation.setDefaultBackgroundColorOverride' @{ color = @{ r = 0; g = 0; b = 0; a = 0 } } | Out-Null
      $html = "<html><body style='margin:0;background:transparent'><img src='data:image/svg+xml;base64,$b64' style='position:absolute;left:0;top:0;width:${s}px;height:${s}px'></body></html>"
    }
    $tmp = Join-Path $env:TEMP 'icon-src.html'
    [IO.File]::WriteAllText($tmp, $html)
    Send-Cdp 'Page.navigate' @{ url = ('file:///' + ($tmp -replace '\\', '/')) } | Out-Null
    Pump 900
    $shot = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true }
    [IO.File]::WriteAllBytes((Join-Path $dir $it.name), [Convert]::FromBase64String($shot.data))
  }
} finally { Stop-Cdp }

# favicon.ico: a 16, 32 es 48 px-es PNG-k egy ICO-taroloban (a gyokerbe, mert a bongeszok ezt keresik elsokent)
$pngs = @('favicon-16.png', 'favicon-32.png', 'favicon-48.png') | ForEach-Object { , [IO.File]::ReadAllBytes((Join-Path $dir $_)) }
$sizes = 16, 32, 48
$ms = New-Object IO.MemoryStream
$bw = New-Object IO.BinaryWriter($ms)
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$pngs.Count)
$offset = 6 + 16 * $pngs.Count
for ($i = 0; $i -lt $pngs.Count; $i++) {
  $bw.Write([byte]$sizes[$i]); $bw.Write([byte]$sizes[$i]); $bw.Write([byte]0); $bw.Write([byte]0)
  $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
  $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Flush()
[IO.File]::WriteAllBytes((Join-Path $root 'favicon.ico'), $ms.ToArray())
Write-Host 'make-icons: kesz (assets/img/icons/*, favicon.ico)'

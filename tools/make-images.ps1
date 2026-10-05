# Megjelenitesi meretu kepvaltozatok az eredetikbol (az eredetik valtozatlanul megmaradnak; a nagyitoablak es a nagy kepek
# tovabbra is azokat hasznalhatjak). Szukseges: ffmpeg a PATH-on. Ujrafuttathato; csak a hianyzo kimeneteket gyartja le
# (-Force-szal mindet ujra).
# Futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\make-images.ps1 [-Force]
param([switch]$Force)
$root = Split-Path -Parent $PSScriptRoot
$img = Join-Path $root 'assets\img'
$jobs = @(
  # kimenet                                  forras                                   szelesseg  minoseg
  @('linkedin-profilkep-400.webp',           'linkedin-profilkep.jpg',                 400, 80),
  @('rolam/van-gogh-640.webp',               'rolam\van-gogh.webp',                    640, 80),
  @('rolam-portre-760.webp',                 'rolam-portre.webp',                      760, 80)
)
foreach ($n in 'ai-agents', 'ai-data-analysis', 'ai-power-bi', 'azure', 'canva', 'cloud-databases', 'copilot-sharepoint', 'data-visualization', 'wordpress') {
  $src = Get-ChildItem $img -Filter "karusszel-$n.*" | Where-Object { $_.Name -notmatch '-800\.' } | Select-Object -First 1
  if ($src) { $jobs += , @("karusszel-$n-800.webp", $src.Name, 800, 80) }
}
foreach ($j in $jobs) {
  $out = Join-Path $img ($j[0] -replace '/', '\'); $in = Join-Path $img ($j[1] -replace '/', '\')
  if ((Test-Path $out) -and -not $Force) { continue }
  & ffmpeg -v error -y -i $in -vf ("scale=" + $j[2] + ":-2") -c:v libwebp -quality $j[3] -compression_level 6 $out
  $d = (& ffprobe -v error -show_entries stream=width,height -of csv=p=0 $out)
  Write-Host ("{0,-44} {1}  {2} KB  (eredeti {3} KB)" -f $j[0], $d, [int]((Get-Item $out).Length / 1KB), [int]((Get-Item $in).Length / 1KB))
}

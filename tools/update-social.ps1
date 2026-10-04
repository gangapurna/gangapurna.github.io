# A kozossegi ikonok sorrendje es keszlete egy helyen, MINDEN oldal lablecében es a Kapcsolat oldalon.
# Sorrend: LinkedIn, Gravatar, GitHub, Facebook, Instagram, WordPress, WhatsApp (nincs YouTube, nincs Pinterest).
# Idempotens: a mar meglevo <li> elemeket (pl. a nyelvenkent kulonbozo WhatsApp-uzenetet) megtartja, ujrarendezi,
# a hianyzo GitHub / WordPress ikont felveszi, a sprite-ba beteszi a hianyzo szimbolumokat, a feleslegeseket torli.
# Futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\update-social.ps1
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)

$order = 'linkedin', 'gravatar', 'github', 'facebook', 'instagram', 'wordpress', 'whatsapp'
$new = @{
  github    = '<li><a href="https://github.com/gangapurna" aria-label="GitHub"><svg aria-hidden="true"><use href="#github"/></svg></a></li>'
  wordpress = '<li><a href="https://profiles.wordpress.org/gangapurna/" aria-label="WordPress"><svg aria-hidden="true"><use href="#wordpress"/></svg></a></li>'
}
$symbols = @{
  github    = '<symbol id="github" viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></symbol>'
}
# a WordPress-szimbolumot a Kapcsolat oldal mar tartalmazza: onnan vesszuk
$contact = [IO.File]::ReadAllText((Join-Path $root 'contact.html'), [Text.Encoding]::UTF8)
$m = [regex]::Match($contact, '<symbol id="wordpress".*?</symbol>', 'Singleline')
if (-not $m.Success) { throw 'A contact.html nem tartalmaz wordpress szimbolumot.' }
$symbols['wordpress'] = $m.Value

$ulPattern = '(<ul class="(?:footer-social|ct-social)[^"]*"[^>]*>)(.*?)(</ul>)'
$changed = 0
Get-ChildItem $root -Recurse -Filter *.html | Where-Object { $_.FullName -notmatch '\\(\.git|tools|api)\\' } | ForEach-Object {
  $text = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
  $out = [regex]::Replace($text, $ulPattern, {
    param($mm)
    $inner = $mm.Groups[2].Value
    $indent = [regex]::Match($inner, '\r?\n([ \t]*)<li>').Groups[1].Value
    $tail = [regex]::Match($inner, '([ \t]*)$').Groups[1].Value
    $items = @{}
    foreach ($li in [regex]::Matches($inner, '<li>.*?</li>', 'Singleline')) {
      $id = [regex]::Match($li.Value, 'href="#([a-z-]+)"').Groups[1].Value
      $items[$id] = $li.Value
    }
    $lines = foreach ($id in $order) { if ($items.ContainsKey($id)) { $items[$id] } elseif ($new.ContainsKey($id)) { $new[$id] } else { throw "Hianyzo ikon: $id" } }
    $mm.Groups[1].Value + "`n" + $indent + ($lines -join ("`n" + $indent)) + "`n" + $tail + $mm.Groups[3].Value
  }, 'Singleline')
  # sprite: hianyzo szimbolumok felvetele a gravatar elé, felesleges (mar nem hasznalt) szimbolumok torlese
  foreach ($id in 'github', 'wordpress') {
    if ($out -notmatch ('<symbol id="' + $id + '"')) { $out = $out.Replace('<symbol id="gravatar"', $symbols[$id] + "`n  " + '<symbol id="gravatar"') }
  }
  foreach ($id in 'youtube', 'pinterest') {
    if ($out -notmatch ('href="#' + $id + '"')) { $out = [regex]::Replace($out, '[ \t]*<symbol id="' + $id + '".*?</symbol>\r?\n?', '', 'Singleline') }
  }
  if ($out -ne $text) { [IO.File]::WriteAllText($_.FullName, $out, $utf8); $changed++ }
}
Write-Host "update-social: $changed oldal frissitve."

# UI-fejlesztes (2026-10-06): a HTML-oldalak kozos / ismetlodo reszeinek frissitese. Idempotens (tobbszor futtatva sem duplikal).
#  1. uj ikonok az SVG-spriteba: book, mail, check-circle, smile (az emoji-k helyett)
#  2. emoji-k (book, mail, check, smile) lecserelese arany vonalas SVG-ikonra
#  3. portfolio: a 2-4. munkahely listaja <details class="tl-more"> lenyilo mezoben (az 1. nyitva marad)
#  4. hamburger-ikon: harom kulon vonal (nyitaskor X-e alakulhat)
# Futtatas:   powershell -ExecutionPolicy Bypass -File .\tools\update-ui.ps1
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
function ReadU($f) { [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8) }
function CodePt($n) { [char]::ConvertFromUtf32($n) }

$eBook = CodePt 0x1F4D6; $eMail = CodePt 0x1F4E7; $eSmile = CodePt 0x1F60A; $eCheck = [string][char]0x2705
if (-not $eBook -or -not $eMail -or -not $eSmile) { throw 'Az emoji-karakterek nem jottek letre.' }

$symbols = @'

  <!-- 2026-10-06: az emoji-k helyett arany vonalas ikonok -->
  <symbol id="book" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M12 5.500C10.200 4.200 7.800 3.500 4.500 3.500H3a1 1 0 0 0-1 1v13a1 1 0 0 0 1 1h1.500c2.900 0 5 .5 7.500 2 2.500-1.500 4.600-2 7.500-2H21a1 1 0 0 0 1-1v-13a1 1 0 0 0-1-1h-1.500C16.200 3.500 13.800 4.200 12 5.500zM11 7.900C9.300 6.900 7.500 6.400 5 6.300v10.100c2.400.1 4.300.5 6 1.400V7.900zm2 0v9.900c1.700-.9 3.600-1.300 6-1.400V6.300c-2.500.1-4.300.6-6 1.600z"/></symbol>
  <symbol id="mail" viewBox="0 0 24 24"><path d="M3 5h18a1 1 0 0 1 1 1v.4l-10 6.200L2 6.400V6a1 1 0 0 1 1-1zM2 8.700l10 6.200 10-6.200V18a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V8.700z"/></symbol>
  <symbol id="check-circle" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm-1.100 14.400L6 11.500l1.500-1.500 3.400 3.400 6.100-6.100 1.500 1.500-7.600 7.600z"/></symbol>
  <symbol id="smile" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zM8.500 8.600a1.400 1.400 0 1 1 0 2.800 1.400 1.400 0 0 1 0-2.800zm7 0a1.400 1.400 0 1 1 0 2.800 1.400 1.400 0 0 1 0-2.800zM12 18c-2.500 0-4.500-1.400-5.300-3.600h1.900c.7 1.200 1.900 1.900 3.400 1.900s2.700-.7 3.400-1.900h1.900C16.500 16.600 14.500 18 12 18z"/></symbol>
'@

$iconBook = '<svg aria-hidden="true"><use href="#book"/></svg>'
$iconMail = '<svg aria-hidden="true"><use href="#mail"/></svg>'
$inlSmile = '<svg class="inl-ico" aria-hidden="true"><use href="#smile"/></svg>'
$ptBook = '<svg class="pf-point__ico" aria-hidden="true"><use href="#book"/></svg>'
$ptCheck = '<svg class="pf-point__ico" aria-hidden="true"><use href="#check-circle"/></svg>'

$oldBurger = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 6h18v2H3zM3 11h18v2H3zM3 16h18v2H3z"/></svg>'
$newBurger = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path class="nav-toggle__b1" d="M3 6h18v2H3z"/><path class="nav-toggle__b2" d="M3 11h18v2H3z"/><path class="nav-toggle__b3" d="M3 16h18v2H3z"/></svg>'

$changed = 0
Get-ChildItem $root -Recurse -Filter *.html | Where-Object { $_.FullName -notmatch '\\(\.git|tools|api)\\' } | ForEach-Object {
  $t = ReadU $_.FullName
  $o = $t
  $hu = $t -match '<html lang="hu"'

  # 1. sprite
  if ($t -notmatch '<symbol id="book"') {
    $m = [regex]::Match($t, '<symbol id="language"[^>]*>.*?</symbol>', 'Singleline')
    if (-not $m.Success) { throw "Nincs language szimbolum: $($_.FullName)" }
    $t = $t.Insert($m.Index + $m.Length, $symbols)
  }

  # 2. emoji -> SVG
  # portfolio bevezeto: a kiemelt bekezdesek (akasztott ikon + szoveg) - ELOBB, mert a gombos csere is "<p>"-vel kezdodo emoji-ra illene
  $t = [regex]::Replace($t, '<p>' + $eBook + ' (.*?) ' + $eBook + '</p>', { param($mm) '<p class="pf-point">' + $ptBook + '<span>' + $mm.Groups[1].Value + '</span></p>' }, 'Singleline')
  $t = [regex]::Replace($t, '<p>' + $eCheck + ' (.*?)</p>', { param($mm) '<p class="pf-point">' + $ptCheck + '<span>' + $mm.Groups[1].Value + '</span></p>' }, 'Singleline')
  # gombok es e-mail hivatkozas (csak <a ...> elejen)
  $t = [regex]::Replace($t, '(<a [^>]*>)' + $eBook + ' ', { param($mm) $mm.Groups[1].Value + $iconBook })
  $t = [regex]::Replace($t, '(<a [^>]*>)' + $eMail + ' ', { param($mm) $mm.Groups[1].Value + $iconMail })
  $t = $t.Replace(' ' + $eSmile + ' ', ' ' + $inlSmile + ' ')
  $t = $t.Replace('>&#128231; ', '>' + $iconMail)                            # a 404-es oldalak entitaskent irt level-emoji-ja

  # 3. idovonal: a 2-4. allas reszletei lenyilo mezoben
  $lblOpen = if ($hu) { 'R' + [char]0xE9 + 'szletek megjelen' + [char]0xED + 't' + [char]0xE9 + 'se' } else { 'Show details' }
  $lblClose = if ($hu) { 'R' + [char]0xE9 + 'szletek elrejt' + [char]0xE9 + 'se' } else { 'Hide details' }
  $ms = [regex]::Matches($t, '<ul class="tl-list">.*?</ul>', 'Singleline')
  for ($i = $ms.Count - 1; $i -ge 1; $i--) {
    $m = $ms[$i]
    $before = $t.Substring([math]::Max(0, $m.Index - 220), [math]::Min(220, $m.Index))
    if ($before -match '<details class="tl-more">') { continue }
    $wrapped = '<details class="tl-more"><summary class="tl-more__sum"><span class="tl-more__open">' + $lblOpen + '</span><span class="tl-more__close">' + $lblClose + '</span></summary>' + $m.Value + '</details>'
    $t = $t.Remove($m.Index, $m.Length).Insert($m.Index, $wrapped)
  }

  # 4. hamburger
  $t = $t.Replace($oldBurger, $newBurger)

  if ($t -ne $o) { [IO.File]::WriteAllText($_.FullName, $t, $utf8); $changed++ }
}
Write-Host "update-ui: $changed oldal frissitve."

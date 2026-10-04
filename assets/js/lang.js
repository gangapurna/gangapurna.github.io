/* Automatikus nyelvválasztás
   -----------------------------------------------------------------------------------------------
   - Ha valaki angol oldalt nyit meg, de a böngészője magyar nyelvű, a szkript a magyar párra irányítja (az oldal
     <link rel="alternate" hreflang="hu"> címe alapján, így a pontos párra ugrik, pl. cikkről cikkre).
   - Csak akkor, ha a látogató még nem választott nyelvet kézzel: bármelyik nyelvváltó hivatkozásra (English / Magyar)
     kattintva a választás megmarad a böngészőben (localStorage, "gh_lang"), és többé nem irányít át.
   - A böngésző nyelvlistájából az első angol vagy magyar nyelv dönt (pl. ["en-US", "hu"] → angol marad).
   - Keresőrobotoknak (nincs magyar böngészőnyelvük) és JavaScript nélkül nincs átirányítás; a hreflang jelölés gondoskodik róluk.
   - Csak angolról magyarra irányít, fordítva nem (a magyar linket kapó külföldi se kerüljön véletlenül máshová).
   Ez egy funkcionális beállítás (nem követés), ezért nem kell hozzá külön süti-hozzájárulás. */
(function () {
  'use strict';
  var KEY = 'gh_lang';
  function stored() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function remember(v) { try { localStorage.setItem(KEY, v); } catch (e) { /* privát mód: nem megőrizhető */ } }

  var current = (document.documentElement.lang || 'en').slice(0, 2).toLowerCase();

  if (current === 'en' && !stored()) {
    var langs = (navigator.languages && navigator.languages.length) ? navigator.languages : [navigator.language || ''];
    var wanted = null;
    for (var i = 0; i < langs.length; i++) {
      var l = String(langs[i]).slice(0, 2).toLowerCase();
      if (l === 'hu' || l === 'en') { wanted = l; break; }
    }
    if (wanted === 'hu') {
      var alt = document.querySelector('link[rel="alternate"][hreflang="hu"]');
      if (alt) {
        var path = new URL(alt.getAttribute('href'), location.href).pathname;   // a gazdagép marad (éles, előnézet, helyi)
        location.replace(path + location.search + location.hash);
      }
    }
  }

  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[hreflang]');
    if (a) remember((a.getAttribute('hreflang') || '').slice(0, 2).toLowerCase());
  });
})();

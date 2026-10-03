/* Süti-hozzájárulás és látogatottság-mérés (Google Analytics 4)
   -----------------------------------------------------------------------------------------------
   Működés röviden:
   - A mérőkód (Google Analytics) csak akkor töltődik be, ha a látogató megnyomta az „Elfogadom” gombot.
     Addig a Google felé semmilyen kérés nem megy, süti nem keletkezik.
   - A döntés a böngésző helyi tárolójában (localStorage) van, 180 napig érvényes, utána újra rákérdez.
   - A mérő csak a lent megadott éles címen töltődik be, így a helyi előnézet és a GitHub Pages nem szennyezi a statisztikát.
   - A lábléc „Süti-beállítások” hivatkozása bármikor újra megnyitja a beállításokat (visszavonás is lehetséges).
   Beállítás: a GA_ID-ba az új GA4 mérőazonosító kerül (analytics.google.com → Admin → Adatfolyamok → Mérőazonosító). */
(function () {
  'use strict';

  var GA_ID = 'G-7T0P6ST7FZ';                        // ← ide jön az új GA4 mérőazonosító (G-...)
  var ANALYTICS_HOSTS = ['site.gaborhorvath.eu'];    // csak ezeken a címeken mérünk
  var KEY = 'gh_consent';
  var MAX_AGE_DAYS = 180;

  var isHu = (document.documentElement.lang || 'en').slice(0, 2) === 'hu';
  var TXT = isHu ? {
    title: 'Sütik és adatvédelem',
    text: 'Anonim látogatottsági statisztikához Google Analytics sütiket használnék. Ezek csak a beleegyezésed után kerülnek a böngésződbe; elutasítás esetén az oldal ugyanúgy működik.',
    privacy: 'Adatkezelési tájékoztató',
    reject: 'Elutasítom', accept: 'Elfogadom', prefs: 'Beállítások',
    dTitle: 'Süti-beállítások',
    close: 'Bezárás',
    necTitle: 'Szükséges tárolás', necText: 'Az oldal működéséhez kell (pl. a süti-döntésed megjegyzése), ezért mindig be van kapcsolva; személyes adatot nem gyűjt.',
    anTitle: 'Látogatottság-mérés (Google Analytics)', anText: 'Névtelen statisztika arról, mely oldalakat olvassák; ez segít az oldal fejlesztésében. Bármikor visszavonhatod.',
    save: 'Mentés', acceptAll: 'Mindent elfogadok',
    on: 'Be', off: 'Ki'
  } : {
    title: 'Cookies and privacy',
    text: 'I would like to use Google Analytics cookies for anonymous visitor statistics. They are only placed in your browser after you agree; if you decline, the site works exactly the same.',
    privacy: 'Privacy notice',
    reject: 'Reject', accept: 'Accept', prefs: 'Preferences',
    dTitle: 'Cookie preferences',
    close: 'Close',
    necTitle: 'Necessary storage', necText: 'Needed for the site to work (e.g. remembering your cookie choice), so it is always on; it collects no personal data.',
    anTitle: 'Visitor statistics (Google Analytics)', anText: 'Anonymous statistics about which pages are read, which helps me improve the site. You can withdraw at any time.',
    save: 'Save', acceptAll: 'Accept all',
    on: 'On', off: 'Off'
  };

  var idIsReal = /^G-[A-Z0-9]{6,}$/.test(GA_ID) && !/X{5,}/.test(GA_ID);
  var mayTrack = idIsReal && ANALYTICS_HOSTS.indexOf(location.hostname) !== -1;

  /* ---- tárolás ---- */
  function readChoice() {
    try {
      var c = JSON.parse(localStorage.getItem(KEY) || 'null');
      if (!c || typeof c.analytics !== 'boolean' || !c.ts) return null;
      if (Date.now() - c.ts > MAX_AGE_DAYS * 864e5) return null;
      return c;
    } catch (e) { return null; }
  }
  function saveChoice(analytics) {
    try { localStorage.setItem(KEY, JSON.stringify({ v: 1, analytics: analytics, ts: Date.now() })); } catch (e) { /* privát mód: a döntés csak az oldal bezárásáig él */ }
  }

  /* ---- Google Analytics be- és kikapcsolása ---- */
  var gaLoaded = false;
  function loadGA() {
    if (!mayTrack || gaLoaded) return;
    gaLoaded = true;
    window['ga-disable-' + GA_ID] = false;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', GA_ID, { anonymize_ip: true });
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(GA_ID);
    document.head.appendChild(s);
  }
  function stopGA() {
    window['ga-disable-' + GA_ID] = true;
    var parts = location.hostname.split('.');
    var domains = ['', location.hostname, '.' + location.hostname];
    for (var i = 1; i < parts.length - 1; i++) domains.push('.' + parts.slice(i).join('.'));
    document.cookie.split(';').forEach(function (c) {
      var name = c.split('=')[0].trim();
      if (name === '_ga' || name.indexOf('_ga_') === 0 || name === '_gid') {
        domains.forEach(function (d) {
          document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/' + (d ? '; domain=' + d : '');
        });
      }
    });
  }
  function apply(analytics) { if (analytics) loadGA(); else stopGA(); }

  /* ---- felület ---- */
  function el(tag, cls, html) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html != null) e.innerHTML = html;
    return e;
  }
  var privacyLink = document.querySelector('.site-footer__copy a');
  var privacyHref = privacyLink ? privacyLink.getAttribute('href') : '#';

  var banner = null, dialog = null, backdrop = null, lastFocus = null;

  function closeBanner() { if (banner) { banner.remove(); banner = null; } }

  function showBanner() {
    if (banner) return;
    banner = el('section', 'cc');
    banner.setAttribute('role', 'region');
    banner.setAttribute('aria-label', TXT.title);
    banner.innerHTML =
      '<div class="cc__box">' +
        '<p class="cc__title">' + TXT.title + '</p>' +
        '<p class="cc__text">' + TXT.text + ' <a href="' + privacyHref + '">' + TXT.privacy + '</a></p>' +
        '<div class="cc__actions">' +
          '<button type="button" class="btn cc__btn" data-cc="reject">' + TXT.reject + '</button>' +
          '<button type="button" class="btn cc__btn" data-cc="accept">' + TXT.accept + '</button>' +
          '<button type="button" class="cc__more" data-cc="prefs">' + TXT.prefs + '</button>' +
        '</div>' +
      '</div>';
    document.body.insertBefore(banner, document.body.firstChild);
    banner.addEventListener('click', function (e) {
      var b = e.target.closest('[data-cc]');
      if (!b) return;
      var a = b.getAttribute('data-cc');
      if (a === 'accept') decide(true);
      else if (a === 'reject') decide(false);
      else openDialog(b);
    });
  }

  function decide(analytics) {
    saveChoice(analytics);
    apply(analytics);
    closeBanner();
    closeDialog();
  }

  function openDialog(opener) {
    if (dialog) return;
    lastFocus = opener || document.activeElement;
    var cur = readChoice();
    var on = cur ? cur.analytics : false;
    backdrop = el('div', 'cc-backdrop');
    dialog = el('div', 'cc-dialog');
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');
    dialog.setAttribute('aria-labelledby', 'cc-dtitle');
    dialog.innerHTML =
      '<div class="cc-dialog__head"><h2 id="cc-dtitle" class="cc-dialog__title">' + TXT.dTitle + '</h2>' +
      '<button type="button" class="cc-dialog__x" data-cc="close" aria-label="' + TXT.close + '">&times;</button></div>' +
      '<div class="cc-row"><div><h3 class="cc-row__title">' + TXT.necTitle + '</h3><p class="cc-row__text">' + TXT.necText + '</p></div>' +
      '<span class="cc-row__fixed">' + TXT.on + '</span></div>' +
      '<div class="cc-row"><div><h3 class="cc-row__title" id="cc-an">' + TXT.anTitle + '</h3><p class="cc-row__text">' + TXT.anText + '</p></div>' +
      '<label class="cc-switch"><input type="checkbox" role="switch" id="cc-analytics" aria-labelledby="cc-an"' + (on ? ' checked' : '') + '><span class="cc-switch__track" aria-hidden="true"></span></label></div>' +
      '<div class="cc-dialog__actions">' +
        '<button type="button" class="btn cc__btn" data-cc="save">' + TXT.save + '</button>' +
        '<button type="button" class="btn cc__btn" data-cc="acceptall">' + TXT.acceptAll + '</button>' +
      '</div>' +
      '<p class="cc-dialog__link"><a href="' + privacyHref + '">' + TXT.privacy + '</a></p>';
    document.body.appendChild(backdrop);
    document.body.appendChild(dialog);
    var first = dialog.querySelector('#cc-analytics');
    if (first) first.focus();

    dialog.addEventListener('click', function (e) {
      var b = e.target.closest('[data-cc]');
      if (!b) return;
      var a = b.getAttribute('data-cc');
      if (a === 'close') closeDialog();
      else if (a === 'save') decide(!!dialog.querySelector('#cc-analytics').checked);
      else if (a === 'acceptall') decide(true);
    });
    backdrop.addEventListener('click', closeDialog);
    document.addEventListener('keydown', dialogKeys);
  }

  function closeDialog() {
    if (!dialog) return;
    dialog.remove(); backdrop.remove();
    dialog = null; backdrop = null;
    document.removeEventListener('keydown', dialogKeys);
    if (lastFocus && document.contains(lastFocus)) lastFocus.focus();
  }

  function dialogKeys(e) {
    if (!dialog) return;
    if (e.key === 'Escape') { closeDialog(); return; }
    if (e.key !== 'Tab') return;
    var f = dialog.querySelectorAll('button, input, a[href]');
    if (!f.length) return;
    var first = f[0], last = f[f.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }

  /* ---- indulás ---- */
  document.addEventListener('click', function (e) {
    var o = e.target.closest('[data-cookie-open]');
    if (o) { e.preventDefault(); openDialog(o); }
  });

  var choice = readChoice();
  if (choice) apply(choice.analytics);
  else showBanner();
})();

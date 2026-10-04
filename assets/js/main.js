/* My webpage – közös szkript
   Minden funkció külön, kis blokkban van, hogy könnyű legyen követni. */

(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* jelzés a CSS-nek: a szkript fut, innentől elrejthetők a belépő animációra váró elemek */
  document.documentElement.classList.add('js-ready');

  /* 1. Mobil menü: a hamburger gomb nyitja/zárja a listát */
  var toggle = document.querySelector('.nav-toggle');
  var list = document.querySelector('.nav__list');
  if (toggle && list) {
    toggle.addEventListener('click', function () {
      var open = list.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && list.classList.contains('is-open')) {
        list.classList.remove('is-open');
        toggle.setAttribute('aria-expanded', 'false');
        toggle.focus();
      }
    });
  }

  /* 2. Görgetés-jelző csík az oldal tetején */
  var bar = document.querySelector('.progress');
  if (bar) {
    var ticking = false;
    var update = function () {
      var h = document.documentElement;
      var max = h.scrollHeight - h.clientHeight;
      bar.style.transform = 'scaleX(' + (max > 0 ? h.scrollTop / max : 0) + ')';
      ticking = false;
    };
    window.addEventListener('scroll', function () {
      if (!ticking) { ticking = true; requestAnimationFrame(update); }
    }, { passive: true });
    update();
  }

  /* 3. Belépő animáció: az elemek láthatóvá válnak, ahogy a nézetbe érnek */
  var reveals = document.querySelectorAll('.reveal, .fade-up');
  if ('IntersectionObserver' in window && !reduceMotion) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('is-visible'); io.unobserve(en.target); }
      });
    }, { threshold: 0.12 });
    reveals.forEach(function (el) { io.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add('is-visible'); });
  }

  /* 4. Karusszel: végtelen, magától fut, nyíllal és ujjal is görgethető.
     A trükk: a diákat háromszor tesszük egymás mellé (másolat | eredeti | másolat).
     Ha a görgetés megáll valamelyik másolatnál, észrevétlenül visszaugrunk az
     eredeti sorra – a három sor egyforma, ezért a szem nem lát ugrást. */
  document.querySelectorAll('.carousel').forEach(function (c) {
    var track = c.querySelector('.carousel__track');
    var prev = c.querySelector('.carousel__btn--prev');
    var next = c.querySelector('.carousel__btn--next');
    if (!track || !prev || !next) return;

    var originals = Array.prototype.slice.call(track.children);
    var clone = function (li) {
      var copy = li.cloneNode(true);
      copy.setAttribute('aria-hidden', 'true');                  // a képernyőolvasó ne olvassa kétszer
      copy.querySelectorAll('a').forEach(function (a) { a.tabIndex = -1; });
      return copy;
    };
    var before = document.createDocumentFragment();
    var after = document.createDocumentFragment();
    originals.forEach(function (li) { before.appendChild(clone(li)); after.appendChild(clone(li)); });
    track.insertBefore(before, track.firstChild);
    track.appendChild(after);

    var gap = function () { return parseFloat(getComputedStyle(track).columnGap) || 0; };
    var step = function () { return originals[0].getBoundingClientRect().width + gap(); };
    var setWidth = function () { return originals.length * step(); };   // egy teljes sor szélessége
    var home = function () { return setWidth(); };                     // az eredeti sor kezdete

    var jump = function (left) {                                       // ugrás animáció nélkül
      track.style.scrollSnapType = 'none';
      track.scrollLeft = left;
      track.style.scrollSnapType = '';
    };
    var recentre = function () {
      var w = setWidth();
      if (track.scrollLeft < w * 0.5) jump(track.scrollLeft + w);
      else if (track.scrollLeft > w * 1.5) jump(track.scrollLeft - w);
    };
    var go = function (dir) {
      track.scrollBy({ left: dir * step(), behavior: reduceMotion ? 'auto' : 'smooth' });
    };

    jump(home());
    window.addEventListener('resize', function () { jump(home()); });

    var settle;                                                        // a görgetés végén igazítunk
    track.addEventListener('scroll', function () {
      clearTimeout(settle);
      settle = setTimeout(recentre, 140);
    }, { passive: true });

    prev.addEventListener('click', function () { go(-1); });
    next.addEventListener('click', function () { go(1); });

    /* automatikus léptetés: megáll, ha rámutatsz, megérinted, fókuszban van,
       kilóg a képernyőről vagy a lap háttérben van; nincs, ha a mozgás ki van kapcsolva */
    if (reduceMotion) return;
    var paused = false, visible = false, timer = null;
    var tick = function () { if (!paused && visible && !document.hidden) go(1); };
    var pause = function () { paused = true; };
    var resume = function () { paused = false; };
    c.addEventListener('mouseenter', pause);
    c.addEventListener('mouseleave', resume);
    c.addEventListener('focusin', pause);
    c.addEventListener('focusout', resume);
    track.addEventListener('touchstart', pause, { passive: true });
    track.addEventListener('touchend', function () { setTimeout(resume, 2500); }, { passive: true });

    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) { visible = entries[0].isIntersecting; }, { threshold: 0.3 }).observe(c);
    } else { visible = true; }
    timer = setInterval(tick, 3200);
  });

  /* 5. Videó: az oldal megnyitásakor csak az előnézeti kép (poster) látszik, a videófájl NEM töltődik le (a forrás a
     data-src-ben van). Amikor a látogató a közelébe görget (kb. 300 px-re), a forrás bekerül, és a (néma) videó
     magától elindul; ha eltávolodik, megáll. Asztalon, tableten és telefonon ugyanígy működik. */
  var video = document.querySelector('.lazy-video');
  if (video) {
    var loadVideo = function () { if (!video.getAttribute('src')) video.src = video.getAttribute('data-src'); };
    if (!('IntersectionObserver' in window)) {
      loadVideo(); video.controls = true;
    } else if (reduceMotion) {
      video.controls = true;          // mozgáscsökkentés: nincs automatikus lejátszás, a látogató indítja
      var near = new IntersectionObserver(function (entries) {
        if (entries[0].isIntersecting) { loadVideo(); near.disconnect(); }
      }, { rootMargin: '300px 0px' });
      near.observe(video);
    } else {
      new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting) { loadVideo(); var p = video.play(); if (p && p.catch) p.catch(function () {}); }
          else video.pause();
        });
      }, { rootMargin: '300px 0px' }).observe(video);
    }
  }

  /* Kapcsolati űrlap: ellenőrzés, beküldés a háttérben (az oldal nem töltődik újra) és visszajelzés.
     A szövegek az űrlap data-msg-* attribútumaiból jönnek, így nyelvenként más és más.
     JavaScript nélkül az űrlap sima POST-ként megy az api/contact.php-nak, ami visszairányít az oldalra. */
  var form = document.querySelector('.ct-form');
  if (form) {
    var statusBox = form.querySelector('.ct-status');
    var submitBtn = form.querySelector('.ct-submit');
    var msg = function (key) { return form.getAttribute('data-msg-' + key) || ''; };
    var setStatus = function (state, text) {
      statusBox.textContent = text || '';
      if (text) { statusBox.setAttribute('data-state', state); } else { statusBox.removeAttribute('data-state'); }
    };
    var fieldError = function (input, text) {
      var err = form.querySelector('#' + input.id + '-error');
      if (err) err.textContent = text || '';
      if (text) { input.setAttribute('aria-invalid', 'true'); } else { input.removeAttribute('aria-invalid'); }
    };
    var inputs = Array.prototype.slice.call(form.querySelectorAll('.ct-input'));
    var emailOk = function (v) { return /^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$/.test(v); };
    /* Egy mező hibaszövege: üres kötelező mező → "kötelező"; hibás e-mail → "érvényes e-mailt adj meg"; különben nincs hiba. */
    var problem = function (input) {
      var v = input.value.trim();
      if (!v) return msg('required');
      if (input.type === 'email' && !emailOk(v)) return msg('email');
      return '';
    };
    var validate = function () {                           // beküldéskor MINDEN mezőt ellenőrzünk; az elsőt adja vissza, ahol hiba van
      var firstBad = null;
      inputs.forEach(function (input) {
        var text = problem(input);
        fieldError(input, text);
        if (text && !firstBad) firstBad = input;
      });
      return firstBad;
    };

    var stamp = form.querySelector('[name="t"]');
    if (stamp) stamp.value = String(Date.now());          // időcsapda: mikor töltődött be az űrlap
    form.noValidate = true;                                // a saját, nyelvfüggő üzeneteinket mutatjuk

    /* Az eredeti oldal (SureForms) viselkedése:
       - a mezőből való kilépéskor (blur) jelzi, ha üres vagy hibás (nem betöltéskor);
       - gépelés közben a hiba azonnal eltűnik; az e-mail mezőnél gépelés közben is jelzi, ha érvénytelen;
       - beküldéskor minden hibás mezőt jelez, és az elsőre ugrik, külön összesítő doboz nélkül. */
    inputs.forEach(function (input) {
      input.addEventListener('blur', function () { fieldError(input, problem(input)); });
      input.addEventListener('input', function () {
        var v = input.value.trim();
        if (!v) return;                                    // a kitörölt mező hibája majd kilépéskor jön
        fieldError(input, input.type === 'email' && !emailOk(v) ? msg('email') : '');
      });
    });

    form.addEventListener('submit', function (e) {
      var bad = validate();
      if (bad) { e.preventDefault(); setStatus('', ''); bad.focus(); return; }
      if (!window.fetch || !window.FormData) return;       // régi böngésző: sima beküldés
      e.preventDefault();
      setStatus('', '');
      submitBtn.disabled = true;
      fetch(form.action, { method: 'POST', body: new FormData(form), headers: { 'Accept': 'application/json' }, credentials: 'same-origin' })
        .then(function (res) { return res.json().catch(function () { return { status: 'error' }; }).then(function (data) { return { res: res, data: data }; }); })
        .then(function (out) {
          var d = out.data || {};
          if (d.status === 'ok') {
            setStatus('ok', d.message || msg('ok'));
            form.reset();
            if (stamp) stamp.value = String(Date.now());
            inputs.forEach(function (i) { fieldError(i, ''); });
          } else if (d.status === 'invalid' && d.errors) {
            inputs.forEach(function (i) { fieldError(i, d.errors[i.name] || ''); });   // a szerver is mezőnként jelez
          } else {
            setStatus(d.status === 'rate' ? 'rate' : 'error', d.message || msg('error'));
          }
        })
        .catch(function () { setStatus('error', msg('error')); })
        .then(function () { submitBtn.disabled = false; });
    });

    // JavaScript nélküli beküldés után a PHP visszairányít ?status=ok|error|invalid|rate paraméterrel
    var qs = new URLSearchParams(window.location.search).get('status');
    if (qs === 'ok') setStatus('ok', msg('ok'));
    else if (qs === 'error' || qs === 'invalid' || qs === 'rate') setStatus(qs, msg(qs === 'rate' ? 'rate' : qs));
  }

  /* Véletlen sorrend: a data-shuffle jelű listák elemei minden betöltésnél más sorrendben jelennek meg
     (az eredeti Rólam oldal első galériája is így működik). Ha a szkript nem fut, marad az alapsorrend. */
  document.querySelectorAll('[data-shuffle]').forEach(function (list) {
    var kids = Array.prototype.slice.call(list.children);
    for (var i = kids.length - 1; i > 0; i--) {            // Fisher–Yates keverés
      var j = Math.floor(Math.random() * (i + 1));
      var tmp = kids[i]; kids[i] = kids[j]; kids[j] = tmp;
    }
    kids.forEach(function (k) { list.appendChild(k); });
  });

  /* Egyenletes sormagasságú ("justified") galéria. A képek a képarányuk szerint kerülnek sorokba:
     egy sor addig telik, amíg a cél-magasságon (--row) kitöltené a szélességet, utána a sor magassága
     úgy módosul, hogy pontosan kitöltse. Az utolsó, nem teljes sor nem nyúlik szét túlzottan. */
  var galleries = Array.prototype.slice.call(document.querySelectorAll('.jg'));
  var justify = function justify(g) {
    var items = Array.prototype.slice.call(g.children);
    if (!items.length) return;
    var cs = getComputedStyle(g);
    var gap = parseFloat(cs.columnGap) || 3;
    /* A pontos (törtszámú) szélességből indulunk, nem a kerekített clientWidth-ből: böngészőnagyításnál
       vagy 125–150%-os képernyőskálánál a kerekítés miatt egy sor utolsó képe 1 px-lel nem férne el,
       és a következő sorba csúszna (ettől maradtak üres helyek). Alatta 1 px biztonsági tartalék. */
    var box = g.getBoundingClientRect();
    var width = box.width - (parseFloat(cs.borderLeftWidth) || 0) - (parseFloat(cs.borderRightWidth) || 0)
                - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight) - 1 - (g._jgShrink || 0);
    var row = parseFloat(cs.getPropertyValue('--row')) || 200;
    var ar = function (li) { return parseFloat(li.style.getPropertyValue('--ar')) || 1; };
    /* Sortörések: a képek sorrendje marad, de a sorhatárokat dinamikus programozással választjuk meg,
       hogy MINDEN sor (az utolsó is) pontosan kitöltse a szélességet, és a sormagasságok minél közelebb
       legyenek a cél-magassághoz. Így nem maradnak üres rések. */
    var n = items.length;
    var ars = items.map(ar);
    var heightFor = function (a, b) {                                  // az a..b-1 képekből álló sor kitöltő magassága
      var s = 0; for (var k = a; k < b; k++) s += ars[k];
      return (width - gap * (b - a - 1)) / s;
    };
    var best = new Array(n + 1), next = new Array(n + 1);
    best[n] = 0;
    for (var a = n - 1; a >= 0; a--) {
      best[a] = Infinity;
      for (var b = a + 1; b <= n; b++) {
        var hh = heightFor(a, b);
        if (hh > row * 3) continue;                                     // túl magas, 1–2 képes sort nem engedünk
        var cost = Math.pow(hh - row, 2) + best[b];
        if (cost < best[a]) { best[a] = cost; next[a] = b; }
      }
      if (best[a] === Infinity) { best[a] = 1e12; next[a] = a + 1; }     // végső tartalék: egy kép egy sorban
    }
    var rowCount = 0;
    for (var i = 0; i < n; i = next[i]) {
      var j = next[i], h = heightFor(i, j);
      rowCount++;
      for (var k = i; k < j; k++) {
        items[k].style.width = Math.floor(ars[k] * h * 100) / 100 + 'px';
        items[k].style.height = Math.floor(h * 100) / 100 + 'px';
      }
    }
    g.classList.add('is-justified');

    /* Ellenőrzés: ha a böngésző mégis több sorba törte az elemeket, mint amennyit kiosztottunk, kicsit
       szűkítünk és újraszámolunk (legfeljebb néhányszor). */
    var tops = {}; items.forEach(function (li) { tops[Math.round(li.getBoundingClientRect().top)] = 1; });
    if (Object.keys(tops).length > rowCount && (g._jgShrink || 0) < 12) {
      g._jgShrink = (g._jgShrink || 0) + 2;
      justify(g);
    } else {
      g._jgShrink = 0;
    }
  };
  var justifyAll = function () { galleries.forEach(justify); };
  if (galleries.length) {
    justifyAll();
    var resizeTimer;
    window.addEventListener('resize', function () { clearTimeout(resizeTimer); resizeTimer = setTimeout(justifyAll, 120); });
  }

  /* Lightbox: a galéria képeire kattintva nagyban nyílnak meg, és lapozhatók:
     nyíllal, a billentyűzet bal/jobb nyilával és ujjal húzva is. A sor körbeér. */
  var box = document.querySelector('.lightbox');
  if (box) {
    var boxImg = box.querySelector('img');
    var boxCap = box.querySelector('figcaption');
    var prevBtn = box.querySelector('.lightbox__nav--prev');
    var nextBtn = box.querySelector('.lightbox__nav--next');
    var all = Array.prototype.slice.call(document.querySelectorAll('[data-lightbox]'));
    var items = all;                                         // az aktuális csoport képei
    var current = 0;
    var lastFocus = null;

    var show = function (i, dir) {
      current = (i + items.length) % items.length;
      var btn = items[current];
      var caption = btn.getAttribute('data-caption') || '';
      boxImg.src = btn.getAttribute('data-lightbox');
      boxImg.alt = caption;
      boxCap.textContent = '';
      boxCap.appendChild(document.createTextNode(caption));
      var count = document.createElement('span');
      count.className = 'lightbox__count';
      count.textContent = (current + 1) + ' / ' + items.length;
      boxCap.appendChild(count);

      boxImg.classList.remove('slide-next', 'slide-prev');   // a csúszó átmenet újraindítása
      if (dir) { void boxImg.offsetWidth; boxImg.classList.add(dir > 0 ? 'slide-next' : 'slide-prev'); }

      var neighbour = new Image();                             // a szomszéd képet előre betöltjük
      neighbour.src = items[(current + 1) % items.length].getAttribute('data-lightbox');
    };
    var close = function () {
      box.classList.remove('is-open');
      boxImg.removeAttribute('src');
      if (lastFocus) lastFocus.focus();
    };

    all.forEach(function (btn) {
      btn.addEventListener('click', function () {
        lastFocus = btn;
        var group = btn.getAttribute('data-lightbox-group');   // csak az azonos csoportbeli képek között lapozunk
        items = all.filter(function (b) { return b.getAttribute('data-lightbox-group') === group; });
        show(items.indexOf(btn), 0);
        box.classList.add('is-open');
        box.querySelector('.lightbox__close').focus();
      });
    });
    prevBtn.addEventListener('click', function () { show(current - 1, -1); });
    nextBtn.addEventListener('click', function () { show(current + 1, 1); });
    box.addEventListener('click', function (e) { if (e.target === box || e.target.closest('.lightbox__close')) close(); });

    document.addEventListener('keydown', function (e) {
      if (!box.classList.contains('is-open')) return;
      if (e.key === 'Escape') close();
      else if (e.key === 'ArrowLeft') show(current - 1, -1);
      else if (e.key === 'ArrowRight') show(current + 1, 1);
    });

    /* ujjal húzás: elég egy rövid, főleg vízszintes mozdulat */
    var startX = null, startY = null;
    box.addEventListener('touchstart', function (e) {
      startX = e.touches[0].clientX; startY = e.touches[0].clientY;
    }, { passive: true });
    box.addEventListener('touchend', function (e) {
      if (startX === null) return;
      var dx = e.changedTouches[0].clientX - startX;
      var dy = e.changedTouches[0].clientY - startY;
      startX = null;
      if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy) * 1.5) show(current + (dx < 0 ? 1 : -1), dx < 0 ? 1 : -1);
    }, { passive: true });
  }

  /* Galériaképek és útikártyák érintőképernyőn (telefon, tablet): amíg az ujjunk a képen van, ugyanaz a hatás látszik,
     mint egérrel hoverre (elsötétülés, zoom, felirat; lásd .is-touched a CSS-ben). Görgetéskor (az ujj elmozdul) a hatás megszűnik,
     koppintásra a lightbox a megszokott módon megnyílik. */
  var touchSel = '.strip__item, .travel__img';
  var touchOn = null, touchX = 0, touchY = 0, touchTimer;
  var touchOff = function (delay) {
    clearTimeout(touchTimer);
    var el = touchOn; touchOn = null;
    if (el) touchTimer = setTimeout(function () { el.classList.remove('is-touched'); }, delay);
  };
  document.addEventListener('touchstart', function (e) {
    var el = e.target.closest && e.target.closest(touchSel);
    if (touchOn && touchOn !== el) touchOn.classList.remove('is-touched');
    clearTimeout(touchTimer);
    touchOn = el;
    if (el) { touchX = e.touches[0].clientX; touchY = e.touches[0].clientY; el.classList.add('is-touched'); }
  }, { passive: true });
  document.addEventListener('touchmove', function (e) {
    if (touchOn && (Math.abs(e.touches[0].clientX - touchX) > 12 || Math.abs(e.touches[0].clientY - touchY) > 12)) touchOff(0);
  }, { passive: true });
  document.addEventListener('touchend', function () { touchOff(500); }, { passive: true });
  document.addEventListener('touchcancel', function () { touchOff(0); }, { passive: true });

  /* Főoldali portré: egérrel hoverre, érintőképernyőn (telefon, tablet) érintésre nagyobb lesz és 5 fokkal elfordul.
     Újabb érintésre, vagy máshová koppintva visszaáll. (A hoverhez nincs szükség erre: azt a CSS intézi.) */
  var portrait = document.querySelector('.portrait-wrap');
  if (portrait && window.matchMedia && window.matchMedia('(hover: none)').matches) {
    portrait.addEventListener('click', function () { portrait.classList.toggle('is-tilted'); });
    document.addEventListener('click', function (e) {
      if (!portrait.contains(e.target)) portrait.classList.remove('is-tilted');
    });
  }
})();

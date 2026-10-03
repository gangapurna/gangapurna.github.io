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

  /* 5. Videó: csak akkor indul, amikor a nézetbe ér (és megáll, ha kiment) */
  var video = document.querySelector('.lazy-video');
  if (video) {
    if (reduceMotion) {
      video.controls = true;          // mozgáscsökkentés: nincs automatikus lejátszás
    } else if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting) { var p = video.play(); if (p && p.catch) p.catch(function () {}); }
          else video.pause();
        });
      }, { threshold: 0.35 }).observe(video);
    }
  }

  /* 6. Lightbox: a galéria képeire kattintva nagyban nyílnak meg, és lapozhatók:
     nyíllal, a billentyűzet bal/jobb nyilával és ujjal húzva is. A sor körbeér. */
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
  var justify = function (g) {
    var items = Array.prototype.slice.call(g.children);
    if (!items.length) return;
    var cs = getComputedStyle(g);
    var gap = parseFloat(cs.columnGap) || 3;
    var width = g.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
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
    for (var i = 0; i < n; i = next[i]) {
      var j = next[i], h = heightFor(i, j);
      for (var k = i; k < j; k++) {
        items[k].style.width = Math.floor(ars[k] * h * 100) / 100 + 'px';
        items[k].style.height = Math.floor(h * 100) / 100 + 'px';
      }
    }
    g.classList.add('is-justified');
  };
  var justifyAll = function () { galleries.forEach(justify); };
  if (galleries.length) {
    justifyAll();
    var resizeTimer;
    window.addEventListener('resize', function () { clearTimeout(resizeTimer); resizeTimer = setTimeout(justifyAll, 120); });
  }

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
})();

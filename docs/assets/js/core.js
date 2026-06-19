/* Agentic DevOps — shared helpers: data loading, theme, nav, badges, scroll-reveal. */
(function () {
  'use strict';

  const FP = (window.FP = window.FP || {});

  /* ─────────────────────────── Data ─────────────────────────────── */
  FP.dataUrl = 'assets/data/platform.json';

  FP.loadData = async function () {
    if (FP._cache) return FP._cache;
    const res = await fetch(FP.dataUrl, { cache: 'no-cache' });
    if (!res.ok) throw new Error('Could not load platform data (' + res.status + ')');
    FP._cache = await res.json();
    return FP._cache;
  };

  /* Module accent CSS variable resolving */
  FP.moduleColor = function (moduleId) {
    const map = {
      ghec: 'var(--c-ghec)',
      ghas: 'var(--c-ghas)',
      ghaw: 'var(--c-ghaw)',
      'agentic-devops': 'var(--c-agentic)',
    };
    return map[moduleId] || 'var(--c-gold)';
  };

  FP.moduleName = function (moduleId, modules) {
    const m = (modules || []).find((x) => x.id === moduleId);
    return m ? m.name : moduleId;
  };

  FP.applyModuleColor = function (el, moduleId) {
    el.style.setProperty('--mod-color', FP.moduleColor(moduleId));
    el.classList.add('mod-' + moduleId);
  };

  /* ─────────────────────────── Escape ───────────────────────────── */
  FP.esc = function (s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])
    );
  };

  /* ─────────────────────────── Badges ───────────────────────────── */
  FP.diffBadge = function (diff) {
    diff = (diff || 'beginner').toLowerCase();
    return `<span class="badge badge-difficulty-${FP.esc(diff)}">${FP.esc(diff)}</span>`;
  };

  FP.durBadge = function (mins) {
    if (!mins) return '';
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    const label = h && m ? `${h}h ${m}m` : h ? `${h}h` : `${m}m`;
    return `<span class="badge badge-duration">⏱ ${label}</span>`;
  };

  FP.emuBadge = function (compat) {
    if (compat === false) return '<span class="badge badge-emu-no">⚠ EMU N/A</span>';
    if (compat === true)  return '<span class="badge badge-emu">✓ EMU</span>';
    return '';
  };

  FP.tagBadges = function (tags, limit) {
    if (!Array.isArray(tags) || !tags.length) return '';
    const show = limit ? tags.slice(0, limit) : tags;
    return show.map((t) => `<span class="badge badge-tag">${FP.esc(t)}</span>`).join('');
  };

  /* ─────────────────────────── URL helpers ───────────────────────── */
  FP.challengeUrl = function (id) {
    return 'challenge.html?id=' + encodeURIComponent(id);
  };
  FP.moduleUrl = function (id) {
    return 'module.html?m=' + encodeURIComponent(id);
  };

  /* ─────────────────────────── Query params ─────────────────────── */
  FP.qp = function (name) {
    return new URLSearchParams(window.location.search).get(name);
  };

  /* ─────────────────────── Kiosk / curated set ───────────────────── */
  /* A coach-built set lives entirely in the URL. `set.html` uses ?ids=…,
     challenge pages opened from a set carry ?set=… so the locked view
     persists. When either is present, kiosk mode hides outbound navigation
     and shows a small "Exit view" button. */

  FP.kioskParams = function () {
    const raw = FP.qp('ids') || FP.qp('set');
    if (!raw) return null;
    const ids = raw.split(',').map((s) => s.trim()).filter(Boolean);
    if (!ids.length) return null;
    return { ids, name: FP.qp('name') || '' };
  };

  FP.isKiosk = function () {
    return !!FP.kioskParams();
  };

  /* URL of the curated set landing page */
  FP.setUrl = function (ids, name) {
    const q = new URLSearchParams();
    q.set('ids', (ids || []).join(','));
    if (name) q.set('name', name);
    return 'set.html?' + q.toString();
  };

  /* Challenge URL that keeps the kiosk state attached */
  FP.kioskChallengeUrl = function (id, params) {
    const q = new URLSearchParams();
    q.set('id', id);
    q.set('set', (params.ids || []).join(','));
    if (params.name) q.set('name', params.name);
    return 'challenge.html?' + q.toString();
  };

  FP.applyKiosk = function () {
    const params = FP.kioskParams();
    if (!params) return null;
    document.documentElement.setAttribute('data-kiosk', 'true');
    if (document.body) document.body.setAttribute('data-kiosk', 'true');
    _injectExitButton();
    return params;
  };

  function _injectExitButton() {
    if (document.getElementById('kioskExitBtn')) return;
    const btn = document.createElement('a');
    btn.id = 'kioskExitBtn';
    btn.className = 'kiosk-exit';
    btn.href = 'index.html';
    btn.textContent = 'Exit view';
    btn.setAttribute('aria-label', 'Exit curated view and return to the full site');
    const actions = document.querySelector('.nav-actions');
    if (actions) actions.insertBefore(btn, actions.firstChild);
    else document.body.appendChild(btn);
  }

  /* ─────────────────────────── Theme ────────────────────────────── */
  const THEME_KEY = 'fp-theme';

  FP.initTheme = function () {
    const saved = localStorage.getItem(THEME_KEY);
    const pref = window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
    const theme = saved || pref;
    document.documentElement.setAttribute('data-theme', theme);

    const btn = document.getElementById('themeBtn');
    if (!btn) return;

    const sync = () => {
      const t = document.documentElement.getAttribute('data-theme');
      btn.innerHTML = t === 'light' ? _moonIcon() : _sunIcon();
      btn.setAttribute('aria-label', t === 'light' ? 'Switch to dark theme' : 'Switch to light theme');
    };
    sync();

    btn.addEventListener('click', () => {
      const cur = document.documentElement.getAttribute('data-theme');
      const next = cur === 'light' ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem(THEME_KEY, next);
      sync();
    });
  };

  function _sunIcon() {
    return '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M18.4 5.6L17 7M6.9 17.1L5.6 18.4"/></svg>';
  }
  function _moonIcon() {
    return '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>';
  }

  /* ─────────────────────────── Nav ──────────────────────────────── */
  FP.initNav = function () {
    const toggle = document.querySelector('.nav-toggle');
    const links  = document.querySelector('.nav-links');
    if (toggle && links) {
      toggle.addEventListener('click', () => {
        const open = links.classList.toggle('open');
        toggle.setAttribute('aria-expanded', String(open));
      });
      // Close on Esc
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && links.classList.contains('open')) {
          links.classList.remove('open');
          toggle.setAttribute('aria-expanded', 'false');
        }
      });
    }
  };

  /* ─────────────────────────── Reveal ───────────────────────────── */
  FP.initReveal = function () {
    if (!('IntersectionObserver' in window)) {
      document.querySelectorAll('.reveal').forEach((el) => el.classList.add('visible'));
      return;
    }
    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); }
        });
      },
      { threshold: 0.08 }
    );
    document.querySelectorAll('.reveal').forEach((el) => obs.observe(el));
  };

  /* ─────────────────────────── Error rendering ───────────────────── */
  FP.renderError = function (container, msg) {
    if (typeof container === 'string') container = document.getElementById(container);
    if (!container) return;
    container.innerHTML = `<div class="empty" role="alert"><strong>Could not load data.</strong><br>${FP.esc(msg)}</div>`;
  };

  /* ─────────────────────────── Markdown ─────────────────────────── */
  FP.renderMd = function (rawMd, targetEl) {
    if (!rawMd) { targetEl.innerHTML = '<p class="text-dim">No content.</p>'; return; }
    if (window.marked) {
      targetEl.innerHTML = window.marked.parse(rawMd, { breaks: false, gfm: true });
    } else {
      // Fallback: wrap in <pre> if marked not available
      const pre = document.createElement('pre');
      pre.textContent = rawMd;
      pre.style.whiteSpace = 'pre-wrap';
      targetEl.innerHTML = '';
      targetEl.appendChild(pre);
    }
  };

  FP.renderInlineMd = function (rawMd) {
    if (rawMd == null || rawMd === '') return '';
    if (!window.marked || typeof window.marked.parseInline !== 'function') return FP.esc(rawMd);

    try {
      return _sanitizeInlineHtml(window.marked.parseInline(String(rawMd), { breaks: false, gfm: true }));
    } catch (e) {
      return FP.esc(rawMd);
    }
  };

  function _sanitizeInlineHtml(html) {
    const template = document.createElement('template');
    template.innerHTML = html;

    const out = document.createElement('span');
    Array.from(template.content.childNodes).forEach((node) => {
      out.appendChild(_sanitizeInlineNode(node));
    });
    return out.innerHTML;
  }

  function _sanitizeInlineNode(node) {
    if (node.nodeType === 3) return document.createTextNode(node.textContent || '');
    if (node.nodeType !== 1) return document.createTextNode('');

    const tag = node.tagName.toLowerCase();
    if (!['a', 'strong', 'em', 'code', 'del', 'br'].includes(tag)) {
      return _sanitizeInlineChildren(node);
    }

    if (tag === 'br') return document.createElement('br');

    if (tag === 'a') {
      const href = node.getAttribute('href') || '';
      if (!_isSafeInlineHref(href)) return _sanitizeInlineChildren(node);

      const a = document.createElement('a');
      a.setAttribute('href', href);
      const title = node.getAttribute('title');
      if (title) a.setAttribute('title', title);
      Array.from(node.childNodes).forEach((child) => a.appendChild(_sanitizeInlineNode(child)));
      return a;
    }

    const el = document.createElement(tag);
    Array.from(node.childNodes).forEach((child) => el.appendChild(_sanitizeInlineNode(child)));
    return el;
  }

  function _sanitizeInlineChildren(node) {
    const frag = document.createDocumentFragment();
    Array.from(node.childNodes).forEach((child) => frag.appendChild(_sanitizeInlineNode(child)));
    return frag;
  }

  function _isSafeInlineHref(href) {
    const trimmed = String(href || '').trim();
    if (!trimmed) return false;
    if (/[\u0000-\u001F\u007F]/.test(trimmed)) return false;
    if (!/^[a-z][a-z0-9+.-]*:/i.test(trimmed) && !trimmed.startsWith('//')) return true;
    try {
      return ['http:', 'https:', 'mailto:'].includes(new URL(trimmed, window.location.href).protocol);
    } catch (e) {
      return false;
    }
  }

  /* ─────────────────────────── Init ─────────────────────────────── */
  document.addEventListener('DOMContentLoaded', () => {
    FP.initTheme();
    FP.initNav();
    FP.applyKiosk();
    FP.initReveal();
  });

})();

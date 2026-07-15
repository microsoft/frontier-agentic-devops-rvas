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
      'sre-agent': 'var(--c-agentic)',
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
  FP.catalogOutcomeUrl = function (id) {
    return 'catalog.html?outcome=' + encodeURIComponent(id);
  };
  FP.outcomeName = function (outcomeId, outcomes) {
    const o = (outcomes || []).find((x) => x.id === outcomeId);
    return o ? o.name : outcomeId;
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

  /* ─────────────────────────── Theme (light only) ───────────────── */
  FP.initTheme = function () {
    document.documentElement.setAttribute('data-theme', 'light');
  };

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
  // GitHub-style alert banners (> [!IMPORTANT] etc.). marked.js has no native
  // support, so we post-process the parsed DOM: any blockquote whose first line
  // is a recognised marker becomes a styled .md-alert banner with an icon + label.
  var MD_ALERT_TYPES = {
    note:      { label: 'Note',      icon: 'M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8Zm8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13ZM6.5 7.75A.75.75 0 0 1 7.25 7h1a.75.75 0 0 1 .75.75v2.75h.25a.75.75 0 0 1 0 1.5h-2a.75.75 0 0 1 0-1.5h.25v-2h-.25a.75.75 0 0 1-.75-.75ZM8 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z' },
    tip:       { label: 'Tip',       icon: 'M8 1.5c-2.363 0-4 1.69-4 3.75 0 .984.424 1.625.984 2.304l.214.253c.223.264.47.556.673.848.284.411.537.896.621 1.49a.75.75 0 0 1-1.484.211c-.04-.282-.163-.547-.37-.847a8.456 8.456 0 0 0-.542-.68c-.084-.1-.173-.205-.268-.32C3.201 7.75 2.5 6.766 2.5 5.25 2.5 2.31 4.863 0 8 0s5.5 2.31 5.5 5.25c0 1.516-.701 2.5-1.328 3.259-.095.115-.184.22-.268.319-.207.245-.383.453-.541.681-.208.3-.33.565-.37.847a.751.751 0 0 1-1.485-.212c.084-.593.337-1.078.621-1.489.203-.292.45-.584.673-.848.075-.088.147-.173.213-.253.561-.679.985-1.32.985-2.304 0-2.06-1.637-3.75-4-3.75ZM5.75 12h4.5a.75.75 0 0 1 0 1.5h-4.5a.75.75 0 0 1 0-1.5ZM6 15.25a.75.75 0 0 1 .75-.75h2.5a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1-.75-.75Z' },
    important: { label: 'Important', icon: 'M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784 16 1.75v9.5A1.75 1.75 0 0 1 14.25 13H8.06l-2.573 2.573A1.458 1.458 0 0 1 3 14.543V13H1.75A1.75 1.75 0 0 1 0 11.25Zm1.75-.25a.25.25 0 0 0-.25.25v9.5c0 .138.112.25.25.25h2a.75.75 0 0 1 .75.75v2.19l2.72-2.72a.749.749 0 0 1 .53-.22h6.5a.25.25 0 0 0 .25-.25v-9.5a.25.25 0 0 0-.25-.25Zm7 2.25v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 9a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z' },
    warning:   { label: 'Warning',   icon: 'M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0 1 14.082 15H1.918a1.75 1.75 0 0 1-1.543-2.575Zm1.763.707a.25.25 0 0 0-.44 0L1.698 13.132a.25.25 0 0 0 .22.368h12.164a.25.25 0 0 0 .22-.368Zm.53 3.996v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 11a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z' },
    caution:   { label: 'Caution',   icon: 'M4.47.22A.749.749 0 0 1 5 0h6c.199 0 .389.079.53.22l4.25 4.25c.141.14.22.331.22.53v6a.749.749 0 0 1-.22.53l-4.25 4.25A.749.749 0 0 1 11 16H5a.749.749 0 0 1-.53-.22L.22 11.53A.749.749 0 0 1 0 11V5c0-.199.079-.389.22-.53Zm.84 1.28L1.5 5.31v5.38l3.81 3.81h5.38l3.81-3.81V5.31L10.69 1.5ZM8 4a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z' },
  };
  var MD_ALERT_RE = /^\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*/;

  function decorateAlerts(root) {
    var quotes = root.querySelectorAll('blockquote');
    for (var i = 0; i < quotes.length; i++) {
      var bq = quotes[i];
      var first = bq.querySelector('p');
      if (!first) continue;
      var m = (first.textContent || '').match(MD_ALERT_RE);
      if (!m) continue;
      var type = m[1].toLowerCase();
      var spec = MD_ALERT_TYPES[type];
      if (!spec) continue;

      // Strip the "[!TYPE]" marker (and a following <br> or newline) from the first paragraph.
      first.innerHTML = first.innerHTML.replace(/^\s*\[!(?:NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(?:<br\s*\/?>)?\s*/i, '');
      if (!first.textContent.trim() && !first.querySelector('*')) {
        first.parentNode.removeChild(first);
      }

      bq.classList.add('md-alert', 'md-alert-' + type);
      var head = document.createElement('p');
      head.className = 'md-alert-title';
      head.innerHTML =
        '<svg class="md-alert-icon" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor"><path d="' +
        spec.icon + '"></path></svg><span>' + spec.label + '</span>';
      bq.insertBefore(head, bq.firstChild);
    }
  }

  FP.renderMd = function (rawMd, targetEl) {
    if (!rawMd) { targetEl.innerHTML = '<p class="text-dim">No content.</p>'; return; }
    if (window.marked) {
      targetEl.innerHTML = window.marked.parse(rawMd, { breaks: false, gfm: true });
      try { decorateAlerts(targetEl); } catch (e) { /* non-fatal */ }
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

/* Agentic DevOps — catalog page: filterable + searchable cross-module grid */
(function () {
  'use strict';

  let _all = [];
  let _modules = [];
  let _outcomes = [];
  let _activeOutcome = null;
  let _activeModule = null;
  let _activeDiff = null;
  let _activeTrack = null;
  let _query = '';

  async function init() {
    let data;
    try { data = await FP.loadData(); }
    catch (e) { FP.renderError('grid', e.message); return; }

    _all = data.challenges || [];
    _modules = data.modules || [];
    _outcomes = data.outcomes || [];

    buildOutcomeChips();
    buildModuleChips();
    buildDiffChips();
    initSearch();
    applyUrlState();
    render();
  }

  const DIFFS = ['beginner', 'intermediate', 'advanced'];

  /* Seed filter state from the URL query string (?module=&difficulty=&q=) and
     reflect it on the chips + search input before the first render. Invalid
     values are ignored rather than applied. */
  function applyUrlState() {
    const mod = FP.qp('module');
    if (mod && _modules.some((m) => m.id === mod)) _activeModule = mod;

    const outcome = FP.qp('outcome');
    if (outcome && _outcomes.some((o) => o.id === outcome)) _activeOutcome = outcome;

    const diff = FP.qp('difficulty');
    if (diff && DIFFS.indexOf(diff) !== -1) _activeDiff = diff;

    const q = (FP.qp('q') || '').trim();
    if (q) {
      _query = q.toLowerCase();
      const input = document.getElementById('searchInput');
      if (input) input.value = q;
    }

    syncChipState();
    syncUrl();
  }

  /* Reflect _activeModule / _activeDiff onto the rendered chips. */
  function syncChipState() {
    document.querySelectorAll('#moduleChips .chip').forEach((b) => {
      const on = b.dataset.module === _activeModule;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
    document.querySelectorAll('#outcomeChips .chip').forEach((b) => {
      const on = b.dataset.outcome === _activeOutcome;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
    document.querySelectorAll('#diffChips .chip').forEach((b) => {
      const on = b.dataset.diff === _activeDiff;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
  }

  /* Keep the address bar in sync with the active filters so the view is
     shareable. replaceState avoids polluting back/forward history. */
  function syncUrl() {
    const q = new URLSearchParams();
    if (_activeModule) q.set('module', _activeModule);
    if (_activeOutcome) q.set('outcome', _activeOutcome);
    if (_activeDiff) q.set('difficulty', _activeDiff);
    if (_query) q.set('q', _query);
    const qs = q.toString();
    const url = window.location.pathname + (qs ? '?' + qs : '');
    window.history.replaceState(null, '', url);
  }

  function buildModuleChips() {
    const container = document.getElementById('moduleChips');
    if (!container) return;

    container.innerHTML = _modules.map((m) =>
      `<button class="chip" data-module="${FP.esc(m.id)}"
         aria-pressed="false" type="button"
         style="--mod-color:${FP.moduleColor(m.id)}">
         ${FP.esc(m.name.replace('GitHub ', ''))}
       </button>`
    ).join('');

    container.querySelectorAll('.chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.module;
        _activeModule = _activeModule === id ? null : id;
        container.querySelectorAll('.chip').forEach((b) => {
          b.classList.toggle('active', b.dataset.module === _activeModule);
          b.setAttribute('aria-pressed', String(b.dataset.module === _activeModule));
        });
        syncUrl();
        render();
      });
    });
  }

  function buildOutcomeChips() {
    const container = document.getElementById('outcomeChips');
    if (!container) return;
    container.innerHTML = _outcomes.map((o) =>
      `<button class="chip chip-outcome" data-outcome="${FP.esc(o.id)}"
         aria-pressed="false" type="button">
         ${FP.esc(o.name)}
       </button>`
    ).join('');

    container.querySelectorAll('.chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.outcome;
        _activeOutcome = _activeOutcome === id ? null : id;
        syncChipState();
        syncUrl();
        render();
      });
    });
  }

  function buildDiffChips() {
    const container = document.getElementById('diffChips');
    if (!container) return;
    const diffs = ['beginner', 'intermediate', 'advanced'];
    container.innerHTML = diffs.map((d) =>
      `<button class="chip" data-diff="${d}" aria-pressed="false" type="button">${d}</button>`
    ).join('');

    container.querySelectorAll('.chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        const d = btn.dataset.diff;
        _activeDiff = _activeDiff === d ? null : d;
        container.querySelectorAll('.chip').forEach((b) => {
          b.classList.toggle('active', b.dataset.diff === _activeDiff);
          b.setAttribute('aria-pressed', String(b.dataset.diff === _activeDiff));
        });
        syncUrl();
        render();
      });
    });
  }

  function initSearch() {
    const input = document.getElementById('searchInput');
    if (!input) return;
    input.addEventListener('input', () => {
      _query = input.value.trim().toLowerCase();
      syncUrl();
      render();
    });

    const clearBtn = document.getElementById('clearBtn');
    if (clearBtn) {
      clearBtn.addEventListener('click', () => {
        _query = '';
        input.value = '';
        _activeOutcome = null;
        _activeModule = null;
        _activeDiff = null;
        document.querySelectorAll('.chip').forEach((b) => {
          b.classList.remove('active');
          b.setAttribute('aria-pressed', 'false');
        });
        syncUrl();
        render();
      });
    }
  }

  function filtered() {
    return _all.filter((c) => {
      if (_activeModule && c.module !== _activeModule) return false;
      if (_activeOutcome && !(c.outcomes || []).includes(_activeOutcome)) return false;
      if (_activeDiff   && c.difficulty !== _activeDiff) return false;
      if (_query) {
        const outcomeNames = (c.outcomes || []).map((id) => FP.outcomeName(id, _outcomes));
        const hay = [c.title, c.description, ...(c.tags || []), ...outcomeNames, c.module, c.track]
          .join(' ').toLowerCase();
        if (!hay.includes(_query)) return false;
      }
      return true;
    });
  }

  function render() {
    const grid = document.getElementById('grid');
    const countEl = document.getElementById('count');
    if (!grid) return;

    renderAdoptionChecklist();

    const items = filtered();

    if (countEl) countEl.textContent = items.length + ' challenge' + (items.length === 1 ? '' : 's');

    if (!items.length) {
      grid.innerHTML = '<div class="no-results">No challenges match those filters. <button class="btn btn-ghost btn-sm" id="inlineClrBtn" type="button">Clear filters</button></div>';
      const b = document.getElementById('inlineClrBtn');
      if (b) b.addEventListener('click', () => document.getElementById('clearBtn')?.click());
      return;
    }

    // Group by module
    const groups = {};
    _modules.forEach((m) => { groups[m.id] = { mod: m, items: [] }; });
    items.forEach((c) => {
      if (groups[c.module]) groups[c.module].items.push(c);
      else groups[c.module] = { mod: { id: c.module, name: c.module }, items: [c] };
    });

    let html = '';
    Object.values(groups).forEach(({ mod, items: gItems }) => {
      if (!gItems.length) return;
      const color = FP.moduleColor(mod.id);
      html += `<div class="group-head mod-${FP.esc(mod.id)}" style="--mod-color:${color}">
        <span class="group-count mod-${FP.esc(mod.id)}" style="color:${color};font-family:var(--font-mono);font-size:0.72rem;font-weight:700">${mod.id.toUpperCase()}</span>
        <h3>${FP.esc(mod.name)}</h3>
        <span class="group-count">${gItems.length} challenge${gItems.length === 1 ? '' : 's'}</span>
      </div>
      <div class="challenge-grid">`;
      html += gItems.map((c) => challengeCard(c)).join('');
      html += '</div>';
    });

    grid.innerHTML = html;
    FP.initReveal();
  }

  function challengeCard(c) {
    const color = FP.moduleColor(c.module);
    return `
      <a href="${FP.challengeUrl(c.id)}" class="ch-card mod-${FP.esc(c.module)} reveal"
         style="--mod-color:${color}">
        <div class="ch-card-top">
          <span class="ch-mod-dot"></span>
          <span class="ch-module-label">${FP.esc(c.track || c.module)}</span>
        </div>
        <div class="ch-title">${FP.esc(c.title)}</div>
        <div class="ch-desc">${FP.esc(c.description)}</div>
        <div class="ch-footer">
          ${outcomeBadge(c)}
          ${FP.diffBadge(c.difficulty)}
          ${FP.durBadge(c.duration_minutes)}
          <div class="ch-tags">${FP.tagBadges(c.tags, 3)}</div>
        </div>
      </a>`;
  }

  function outcomeBadge(c) {
    const id = (c.outcomes || [])[0];
    if (!id) return '';
    return `<span class="badge badge-outcome">${FP.esc(FP.outcomeName(id, _outcomes))}</span>`;
  }

  const OWNER_LABELS = {
    'developer': 'Developer',
    'platform-governance': 'Platform / Governance',
    'solution-architect': 'Solution Architect',
  };
  function ownerLabel(o) { return OWNER_LABELS[o] || o || ''; }

  /* Production adoption checklist — shown only when a single outcome is active. */
  function renderAdoptionChecklist() {
    const host = document.getElementById('adoptionChecklist');
    if (!host) return;
    const outcome = _activeOutcome ? _outcomes.find((o) => o.id === _activeOutcome) : null;
    const items = (outcome && outcome.take_home) || [];
    if (!outcome || !items.length) { host.innerHTML = ''; return; }

    const rows = items.map((it) => `
      <li class="adoption-item">
        <p class="adoption-item-action">${FP.renderInlineMd(it.action)}</p>
        <div class="adoption-item-meta">
          ${it.owner ? `<span class="adoption-item-owner">${FP.esc(ownerLabel(it.owner))}</span>` : ''}
          ${it.signal ? `<span class="adoption-item-signal">${FP.renderInlineMd(it.signal)}</span>` : ''}
          <a class="adoption-item-link" href="${FP.challengeUrl(it.id)}">${FP.esc(it.id)} →</a>
        </div>
      </li>`).join('');

    host.innerHTML = `
      <section class="adoption-checklist" aria-labelledby="adoptHead">
        <div class="adoption-checklist-head">
          <h2 id="adoptHead">Take it to production: ${FP.esc(outcome.name)}</h2>
          <span class="badge badge-duration">${items.length} adoption steps</span>
        </div>
        <p class="adoption-checklist-sub">Run each step in your own org or tenant. Owners and success signals are yours to assign as you roll this out.</p>
        <ol>${rows}</ol>
        <div class="adoption-checklist-actions">
          <button class="btn btn-ghost btn-sm" id="adoptCopyBtn" type="button">Copy as Markdown</button>
          <button class="btn btn-ghost btn-sm" id="adoptPrintBtn" type="button">Print / PDF</button>
        </div>
      </section>`;

    const copyBtn = document.getElementById('adoptCopyBtn');
    if (copyBtn) copyBtn.addEventListener('click', () => copyChecklistMarkdown(outcome, copyBtn));
    const printBtn = document.getElementById('adoptPrintBtn');
    if (printBtn) printBtn.addEventListener('click', () => window.print());
  }

  function checklistMarkdown(outcome) {
    const lines = [`# Take it to production — ${outcome.name}`, ''];
    (outcome.take_home || []).forEach((it, i) => {
      lines.push(`${i + 1}. **${it.action}**`);
      if (it.owner)  lines.push(`   - Owner: ${ownerLabel(it.owner)}`);
      if (it.signal) lines.push(`   - Success signal: ${it.signal}`);
      lines.push(`   - Challenge: ${it.id}`);
    });
    return lines.join('\n');
  }

  function copyChecklistMarkdown(outcome, btn) {
    const md = checklistMarkdown(outcome);
    const done = () => { const t = btn.textContent; btn.textContent = 'Copied ✓'; setTimeout(() => { btn.textContent = t; }, 1600); };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(md).then(done).catch(() => fallbackCopy(md, done));
    } else {
      fallbackCopy(md, done);
    }
  }

  function fallbackCopy(text, done) {
    const ta = document.createElement('textarea');
    ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta); ta.select();
    try { document.execCommand('copy'); done(); } catch (e) { /* noop */ }
    document.body.removeChild(ta);
  }

  document.addEventListener('DOMContentLoaded', init);
})();

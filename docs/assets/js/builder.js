/* Agentic DevSecOps — set builder: multi-select activities → shareable link */
(function () {
  'use strict';

  let _all = [];
  let _modules = [];
  let _outcomes = [];
  let _activeOutcome = null;
  let _activeModule = null;
  let _activeTrack = null;
  let _activeDiff = null;
  let _query = '';
  const _selected = new Set();

  const CHECK_SVG =
    '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#032254" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6L9 17l-5-5"/></svg>';

  async function init() {
    let data;
    try { data = await FP.loadData(); }
    catch (e) { FP.renderError('grid', e.message); return; }

    _all = data.challenges || [];
    _modules = data.modules || [];
    _outcomes = data.outcomes || [];

    buildOutcomeChips();
    buildTrackChips();
    buildModuleChips();
    buildDiffChips();
    initSearch();
    initTray();
    applyUrlState();
    render();
  }

  const DIFFS = ['beginner', 'intermediate', 'advanced'];

  function applyUrlState() {
    const outcome = FP.qp('outcome');
    if (outcome && _outcomes.some((o) => o.id === outcome)) _activeOutcome = outcome;

    const moduleId = FP.qp('module');
    if (moduleId && _modules.some((m) => m.id === moduleId)) _activeModule = moduleId;

    const track = FP.qp('track');
    if (track && _all.some((c) => c.track === track)) _activeTrack = track;

    const diff = FP.qp('difficulty');
    if (diff && DIFFS.includes(diff)) _activeDiff = diff;

    const q = (FP.qp('q') || '').trim();
    if (q) {
      _query = q.toLowerCase();
      const input = document.getElementById('searchInput');
      if (input) input.value = q;
    }

    syncChipState();
    syncUrl();
  }

  function syncChipState() {
    document.querySelectorAll('#outcomeChips .chip').forEach((b) => {
      const on = b.dataset.outcome === _activeOutcome;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
    document.querySelectorAll('#moduleChips .chip').forEach((b) => {
      const on = b.dataset.module === _activeModule;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
    document.querySelectorAll('#trackChips .chip').forEach((b) => {
      const on = b.dataset.track === _activeTrack;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
    document.querySelectorAll('#diffChips .chip').forEach((b) => {
      const on = b.dataset.diff === _activeDiff;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    });
  }

  function syncUrl() {
    const q = new URLSearchParams();
    if (_activeOutcome) q.set('outcome', _activeOutcome);
    if (_activeModule) q.set('module', _activeModule);
    if (_activeTrack) q.set('track', _activeTrack);
    if (_activeDiff) q.set('difficulty', _activeDiff);
    if (_query) q.set('q', _query);
    const qs = q.toString();
    window.history.replaceState(null, '', window.location.pathname + (qs ? '?' + qs : ''));
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
        syncChipState();
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

  function buildTrackChips() {
    const container = document.getElementById('trackChips');
    if (!container) return;

    const tracks = FP.catalogTracks(_modules);

    container.innerHTML = tracks.map((track) =>
      `<button class="chip" data-track="${FP.esc(track.id)}"
         aria-pressed="false" type="button">${FP.esc(track.name)}</button>`
    ).join('');

    container.querySelectorAll('.chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.track;
        _activeTrack = _activeTrack === id ? null : id;
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
        syncChipState();
        syncUrl();
        render();
      });
    });
  }

  function initSearch() {
    const input = document.getElementById('searchInput');
    if (input) {
      input.addEventListener('input', () => {
        _query = input.value.trim().toLowerCase();
        syncUrl();
        render();
      });
    }
    const clearBtn = document.getElementById('clearBtn');
    if (clearBtn) {
      clearBtn.addEventListener('click', () => {
        _query = '';
        if (input) input.value = '';
        _activeOutcome = null;
        _activeModule = null;
        _activeTrack = null;
        _activeDiff = null;
        document.querySelectorAll('.filters .chip').forEach((b) => {
          b.classList.remove('active');
          b.setAttribute('aria-pressed', 'false');
        });
        syncUrl();
        render();
      });
    }
  }

  function initTray() {
    document.getElementById('deselectBtn')?.addEventListener('click', () => {
      _selected.clear();
      hideLink();
      syncSelectionUI();
      render();
    });

    document.getElementById('generateBtn')?.addEventListener('click', generateLink);

    document.getElementById('copyBtn')?.addEventListener('click', async () => {
      const link = document.getElementById('setLink');
      if (!link || !link.value) return;
      try {
        await navigator.clipboard.writeText(link.value);
        flash(document.getElementById('copyBtn'), 'Copied!');
      } catch (e) {
        link.select();
        document.execCommand('copy');
        flash(document.getElementById('copyBtn'), 'Copied!');
      }
    });

    // Re-generating keeps the visible link in sync if the name changes
    document.getElementById('setName')?.addEventListener('input', () => {
      if (!document.getElementById('linkRow').hidden) generateLink();
    });

    syncSelectionUI();
  }

  function filtered() {
    return _all.filter((c) => {
      if (_activeModule && c.module !== _activeModule) return false;
      if (_activeOutcome && !(c.outcomes || []).includes(_activeOutcome)) return false;
      if (_activeTrack && c.track !== _activeTrack) return false;
      if (_activeDiff && c.difficulty !== _activeDiff) return false;
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

    const items = FP.orderActivities(filtered(), _activeOutcome, _outcomes, _modules);
    if (countEl) countEl.textContent = items.length + ' activit' + (items.length === 1 ? 'y' : 'ies');

    if (!items.length) {
      grid.innerHTML = '<div class="no-results">No activities match those filters. <button class="btn btn-ghost btn-sm" id="inlineClrBtn" type="button">Clear filters</button></div>';
      document.getElementById('inlineClrBtn')?.addEventListener('click', () => document.getElementById('clearBtn')?.click());
      return;
    }

    const groups = FP.groupActivities(items, _activeOutcome, _outcomes, _modules);

    let html = '';
    groups.forEach(({ name, description, items: gItems }) => {
      html += `<div class="group-head">
        <h3>${FP.esc(name)}</h3>
        <span class="group-count">${gItems.length} activit${gItems.length === 1 ? 'y' : 'ies'}</span>
        ${description ? `<p class="group-intro">${FP.esc(description)}</p>` : ''}
      </div>
      <div class="challenge-grid">`;
      html += gItems.map((c) => selectCard(c)).join('');
      html += '</div>';
    });

    grid.innerHTML = html;
    grid.querySelectorAll('.sel-card').forEach((card) => {
      card.addEventListener('click', () => toggle(card.dataset.id, card));
    });
  }

  function selectCard(c) {
    const color = FP.moduleColor(c.module);
    const on = _selected.has(c.id);
    return `
      <button class="sel-card mod-${FP.esc(c.module)}" type="button"
         data-id="${FP.esc(c.id)}" aria-pressed="${on}"
         style="--mod-color:${color}">
        <span class="sel-check" aria-hidden="true">${CHECK_SVG}</span>
        <div class="ch-card-top">
          <span class="ch-mod-dot"></span>
          <span class="ch-module-label">${FP.esc(FP.moduleName(c.module, _modules))}</span>
        </div>
        <div class="ch-title">${FP.esc(c.title)}</div>
        <div class="ch-desc">${FP.esc(c.description)}</div>
        <div class="ch-footer">
          ${outcomeBadge(c)}
          ${FP.diffBadge(c.difficulty)}
          ${FP.durBadge(c.duration_minutes)}
          <div class="ch-tags">${FP.tagBadges(c.tags, 3)}</div>
        </div>
      </button>`;
  }

  function outcomeBadge(c) {
    if (_activeOutcome) return '';
    const id = (c.outcomes || [])[0];
    if (!id) return '';
    return `<span class="badge badge-outcome">${FP.esc(FP.outcomeName(id, _outcomes))}</span>`;
  }

  function toggle(id, card) {
    if (_selected.has(id)) _selected.delete(id);
    else _selected.add(id);
    if (card) card.setAttribute('aria-pressed', String(_selected.has(id)));
    hideLink();
    syncSelectionUI();
  }

  function syncSelectionUI() {
    const n = _selected.size;
    const countEl = document.getElementById('setCount');
    if (countEl) countEl.innerHTML = `<strong>${n}</strong> selected`;
    const gen = document.getElementById('generateBtn');
    if (gen) gen.disabled = n === 0;
    const deselect = document.getElementById('deselectBtn');
    if (deselect) deselect.disabled = n === 0;
  }

  /* Keep a stable module-based order for shared sets. */
  function orderedIds() {
    return FP.orderActivities(_all, null, _outcomes, _modules)
      .filter((c) => _selected.has(c.id))
      .map((c) => c.id);
  }

  function generateLink() {
    const ids = orderedIds();
    if (!ids.length) return;
    const name = (document.getElementById('setName')?.value || '').trim();
    const relative = FP.setUrl(ids, name);
    const absolute = new URL(relative, window.location.href).href;

    const row = document.getElementById('linkRow');
    const link = document.getElementById('setLink');
    const open = document.getElementById('openBtn');
    if (link) link.value = absolute;
    if (open) open.href = relative;
    if (row) row.hidden = false;
  }

  function hideLink() {
    const row = document.getElementById('linkRow');
    if (row) row.hidden = true;
  }

  function flash(btn, text) {
    if (!btn) return;
    const prev = btn.textContent;
    btn.textContent = text;
    setTimeout(() => { btn.textContent = prev; }, 1400);
  }

  document.addEventListener('DOMContentLoaded', init);
})();

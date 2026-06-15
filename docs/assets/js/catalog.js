/* Agentic DevOps — catalog page: filterable + searchable cross-module grid */
(function () {
  'use strict';

  let _all = [];
  let _modules = [];
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

    buildModuleChips();
    buildDiffChips();
    initSearch();
    render();
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
        render();
      });
    });
  }

  function initSearch() {
    const input = document.getElementById('searchInput');
    if (!input) return;
    input.addEventListener('input', () => {
      _query = input.value.trim().toLowerCase();
      render();
    });

    const clearBtn = document.getElementById('clearBtn');
    if (clearBtn) {
      clearBtn.addEventListener('click', () => {
        _query = '';
        input.value = '';
        _activeModule = null;
        _activeDiff = null;
        document.querySelectorAll('.chip').forEach((b) => {
          b.classList.remove('active');
          b.setAttribute('aria-pressed', 'false');
        });
        render();
      });
    }
  }

  function filtered() {
    return _all.filter((c) => {
      if (_activeModule && c.module !== _activeModule) return false;
      if (_activeDiff   && c.difficulty !== _activeDiff) return false;
      if (_query) {
        const hay = [c.title, c.description, ...(c.tags || []), c.module, c.track]
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
          ${FP.diffBadge(c.difficulty)}
          ${FP.durBadge(c.duration_minutes)}
          <div class="ch-tags">${FP.tagBadges(c.tags, 3)}</div>
        </div>
      </a>`;
  }

  document.addEventListener('DOMContentLoaded', init);
})();

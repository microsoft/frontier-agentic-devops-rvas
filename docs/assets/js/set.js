/* Agentic DevOps — curated set view (?ids=a,b,c&name=…), opens in kiosk mode */
(function () {
  'use strict';

  async function init() {
    const params = FP.kioskParams();
    if (!params) {
      showEmpty('No activity set specified. <a href="builder.html">Build one →</a>');
      return;
    }

    let data;
    try { data = await FP.loadData(); }
    catch (e) { FP.renderError('grid', e.message); return; }

    const byId = new Map((data.challenges || []).map((c) => [c.id, c]));
    const modules = data.modules || [];
    const items = params.ids.map((id) => byId.get(id)).filter(Boolean);

    renderHeading(params.name, items.length);

    if (!items.length) {
      showEmpty('None of the activities in this set could be found.');
      return;
    }

    renderGrid(items, modules, params);
  }

  function renderHeading(name, n) {
    const title = name || 'Your activities';
    document.title = title + ' — Agentic DevOps';
    const h = document.getElementById('setHeading');
    if (h) h.textContent = name ? name : 'Your activities.';
    const intro = document.getElementById('setIntro');
    if (intro) {
      intro.textContent =
        `A focused selection of ${n} activit${n === 1 ? 'y' : 'ies'} prepared for you. ` +
        'Work through them at your own pace.';
    }
  }

  function renderGrid(items, modules, params) {
    const grid = document.getElementById('grid');
    if (!grid) return;

    const groups = {};
    modules.forEach((m) => { groups[m.id] = { mod: m, items: [] }; });
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
        <span class="group-count">${gItems.length} activit${gItems.length === 1 ? 'y' : 'ies'}</span>
      </div>
      <div class="challenge-grid">`;
      html += gItems.map((c) => card(c, params)).join('');
      html += '</div>';
    });

    grid.innerHTML = html;
    FP.initReveal();
  }

  function card(c, params) {
    const color = FP.moduleColor(c.module);
    return `
      <a href="${FP.kioskChallengeUrl(c.id, params)}" class="ch-card mod-${FP.esc(c.module)} reveal"
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

  function showEmpty(msgHtml) {
    const grid = document.getElementById('grid');
    if (grid) grid.innerHTML = `<div class="no-results">${msgHtml}</div>`;
  }

  document.addEventListener('DOMContentLoaded', init);
})();

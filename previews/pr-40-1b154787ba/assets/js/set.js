/* Agentic DevSecOps — curated set view (?ids=a,b,c&name=…), opens in kiosk mode */
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
    params.ids = FP.resolveSetIds(params.ids, data);
    const items = params.ids.map((id) => byId.get(id)).filter(Boolean);

    renderHeading(params.name, items.length);
    const missing = params.ids.filter(id => !byId.has(id));
    const intro = document.getElementById('setIntro');
    if (intro && missing.length) intro.textContent += ` Unavailable activities: ${missing.join(', ')}.`;

    if (!items.length) {
      showEmpty('None of the activities in this set could be found.');
      return;
    }

    renderGrid(items, params);
  }

  function renderHeading(name, n) {
    const title = name || 'Your activities';
    document.title = title + '. Agentic DevSecOps';
    const h = document.getElementById('setHeading');
    if (h) h.textContent = name ? name : 'Your activities.';
    const intro = document.getElementById('setIntro');
    if (intro) {
      intro.textContent =
        `Your team's set has ${n} activit${n === 1 ? 'y' : 'ies'}. ` +
        'Work through them at your own pace.';
    }
  }

  function renderGrid(items, params) {
    const grid = document.getElementById('grid');
    if (!grid) return;

    grid.innerHTML = `<div class="challenge-grid">${items.map(c => card(c, params)).join('')}</div>`;
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

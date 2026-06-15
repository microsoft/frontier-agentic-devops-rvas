/* Agentic DevOps — home page */
(function () {
  'use strict';

  async function init() {
    let data;
    try { data = await FP.loadData(); }
    catch (e) { FP.renderError('moduleGrid', e.message); return; }

    const { modules, challenges } = data;

    renderStats(modules, challenges);
    renderModuleCards(modules, challenges);
    renderFeaturedChallenge(challenges);
  }

  function renderStats(modules, challenges) {
    const totalChallenges = modules.reduce((s, m) => s + (m.challenge_count || 0), 0);
    const totalModules = modules.length;
    const totalTracks = modules.reduce((s, m) => s + (m.tracks ? m.tracks.length : 0), 0);
    const totalMins = challenges.reduce((s, c) => s + (c.duration_minutes || 0), 0);

    _setText('stat-challenges', totalChallenges);
    _setText('stat-modules', totalModules);
    _setText('stat-tracks', totalTracks);
    const h = Math.round(totalMins / 60);
    _setText('stat-hours', h + 'h');
  }

  function renderModuleCards(modules, challenges) {
    const grid = document.getElementById('moduleGrid');
    if (!grid) return;

    grid.innerHTML = modules.map((m) => {
      const challengeCount = m.challenge_count || 0;
      const trackCount = m.tracks ? m.tracks.length : 0;
      const trackPills = (m.tracks || [])
        .map((t) => `<span class="track-pill">${FP.esc(t.name)}</span>`)
        .join('');

      return `
        <a href="${FP.moduleUrl(m.id)}" class="mod-card mod-${FP.esc(m.id)}" style="--mod-color:${FP.moduleColor(m.id)}">
          <div class="mod-card-header">
            <img src="assets/img/${FP.esc(m.icon)}" class="mod-card-icon" alt="" aria-hidden="true" />
            <div class="mod-card-title-block">
              <div class="mod-card-title">${FP.esc(m.name)}</div>
              <div class="mod-card-id">${FP.esc(m.id)}</div>
            </div>
          </div>
          <div class="mod-card-body">
            <p class="mod-card-desc">${FP.esc(m.description)}</p>
            <div class="mod-card-tracks">${trackPills}</div>
            <div class="mod-card-meta">
              <div class="mod-stat"><strong>${challengeCount}</strong> challenges</div>
              <div class="mod-stat"><strong>${trackCount}</strong> tracks</div>
            </div>
          </div>
        </a>`;
    }).join('');
  }

  function renderFeaturedChallenge(challenges) {
    const el = document.getElementById('featuredChallenge');
    if (!el || !challenges.length) return;

    // Pick a beginner challenge from ghaw (most "hello world" friendly)
    const pick = challenges.find((c) => c.module === 'ghaw' && c.difficulty === 'beginner')
      || challenges[0];

    el.innerHTML = `
      <a class="ch-card mod-${FP.esc(pick.module)}" href="${FP.challengeUrl(pick.id)}" style="--mod-color:${FP.moduleColor(pick.module)};background:var(--c-700)">
        <div class="ch-card-top">
          <span class="ch-mod-dot"></span>
          <span class="ch-module-label">${FP.esc(pick.module)} · ${FP.esc(pick.track)}</span>
        </div>
        <div class="ch-title">${FP.esc(pick.title)}</div>
        <div class="ch-desc">${FP.esc(pick.description)}</div>
        <div class="ch-footer">
          ${FP.diffBadge(pick.difficulty)}
          ${FP.durBadge(pick.duration_minutes)}
          <div class="ch-tags">${FP.tagBadges(pick.tags, 3)}</div>
        </div>
      </a>
      <a class="btn btn-ghost btn-sm" href="${FP.challengeUrl(pick.id)}" style="align-self:flex-start">
        Open challenge →
      </a>`;
  }

  function _setText(id, val) {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  }

  document.addEventListener('DOMContentLoaded', init);
})();

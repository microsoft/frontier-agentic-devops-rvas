/* Agentic DevSecOps — home page */
(function () {
  'use strict';

  async function init() {
    let data;
    try { data = await FP.loadData(); }
    catch (e) { FP.renderError('moduleGrid', e.message); return; }

    const { modules, outcomes, challenges } = data;

    renderStats(modules, challenges);
    renderOutcomeCards(outcomes || [], challenges);
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

  function renderOutcomeCards(outcomes, challenges) {
    const grid = document.getElementById('outcomeGrid');
    if (!grid) return;

    if (!outcomes.length) {
      grid.innerHTML = '<div class="empty">No outcome journeys configured.</div>';
      return;
    }

    grid.innerHTML = outcomes.map((o) => {
      const count = o.challenge_count || (o.challenge_ids || []).length || 0;
      const mins = o.duration_minutes || (o.challenge_ids || []).reduce((sum, id) => {
        const c = challenges.find((x) => x.id === id);
        return sum + (c && c.duration_minutes ? c.duration_minutes : 0);
      }, 0);
      const metrics = (o.success_metrics || []).slice(0, 2)
        .map((m) => `<li>${FP.esc(m)}</li>`)
        .join('');
      return `
        <a href="${FP.catalogOutcomeUrl(o.id)}" class="outcome-card reveal">
          <div class="outcome-card-top">
            <span class="outcome-id">${FP.esc(o.id)}</span>
            <span class="badge badge-duration">${count} activities</span>
            ${FP.durBadge(mins)}
          </div>
          <h3>${FP.esc(o.name)}</h3>
          <p>${FP.esc(o.tagline || o.description || '')}</p>
          ${metrics ? `<ul class="outcome-metrics">${metrics}</ul>` : ''}
        </a>`;
    }).join('');
    FP.initReveal();
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
              <div class="mod-stat"><strong>${challengeCount}</strong> activities</div>
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
        Open activity →
      </a>`;
  }

  function _setText(id, val) {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  }

  document.addEventListener('DOMContentLoaded', init);
})();

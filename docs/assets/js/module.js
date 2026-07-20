/* Agentic DevOps — module detail page (?m=<moduleId>) */
(function () {
  'use strict';

  async function init() {
    const moduleId = FP.qp('m');
    if (!moduleId) { showError('No module specified. Try <a href="catalog.html">the catalog</a>.'); return; }

    let data;
    try { data = await FP.loadData(); }
    catch (e) { showError(e.message); return; }

    const mod = (data.modules || []).find((m) => m.id === moduleId);
    if (!mod) { showError('Module "' + moduleId + '" not found.'); return; }

    const challenges = (data.challenges || []).filter((c) => c.module === moduleId);

    document.title = mod.name + ' — Agentic DevOps';
    updateMeta(mod);
    renderHero(mod, challenges);
    renderTracks(mod, challenges);
    renderChallenges(challenges, mod);
  }

  function updateMeta(mod) {
    const desc = document.getElementById('metaDesc');
    if (desc) desc.setAttribute('content', mod.description || '');
  }

  function renderHero(mod, challenges) {
    const color = FP.moduleColor(mod.id);

    _setText('modName', mod.name);
    _setText('modId', mod.id.toUpperCase());
    _setText('modDesc', mod.description);
    _setText('modCount', mod.challenge_count || challenges.length);
    _setText('modTracks', mod.tracks ? mod.tracks.length : '—');

    const icon = document.getElementById('modIcon');
    if (icon) {
      icon.src = 'assets/img/' + (mod.icon || 'icon-' + mod.id + '.svg');
      icon.alt = mod.name + ' icon';
    }

    // Apply module color to the hero accent bar
    const bar = document.getElementById('modAccentBar');
    if (bar) bar.style.background = color;

    // Style the hero with a faint module-color radial
    const hero = document.getElementById('moduleHero');
    if (hero) {
      hero.style.setProperty('--mod-color', color);
      const glow = color.replace('var(', '').replace(')', '');
      hero.style.background =
        `radial-gradient(700px 500px at 90% 50%, color-mix(in srgb, ${color} 8%, transparent), transparent)`;
    }
  }

  function renderTracks(mod, challenges) {
    const list = document.getElementById('trackList');
    if (!list || !mod.tracks) return;
    const color = FP.moduleColor(mod.id);

    list.innerHTML = mod.tracks.map((t) => {
      const count = challenges.filter((c) => c.track === t.id).length;
      const tag = count > 0 ? 'a' : 'div';
      const href = count > 0 ? ` href="#track-${t.id}"` : '';
      return `
        <${tag} class="track-item"${href} style="--mod-color:${color}">
          <div class="track-item-dot"></div>
          <div class="track-item-info">
            <div class="track-item-name">${FP.esc(t.name)}</div>
            ${t.description ? `<div class="track-item-desc">${FP.esc(t.description)}</div>` : ''}
          </div>
          <div class="track-item-count">${count} activit${count === 1 ? 'y' : 'ies'}</div>
        </${tag}>`;
    }).join('');
  }

  function renderChallenges(challenges, mod) {
    const grid = document.getElementById('challengeGrid');
    if (!grid) return;
    const color = FP.moduleColor(mod.id);

    if (!challenges.length) {
      grid.innerHTML = '<div class="empty">No activities found for this module.</div>';
      return;
    }

    // Group by track
    const tracks = mod.tracks ? mod.tracks.map((t) => t.id) : [];
    const byTrack = {};
    challenges.forEach((c) => {
      const key = c.track || '_';
      if (!byTrack[key]) byTrack[key] = [];
      byTrack[key].push(c);
    });

    // Render tracks in order
    const order = tracks.length ? tracks : Object.keys(byTrack);
    let html = '';

    order.forEach((trackId) => {
      const items = byTrack[trackId];
      if (!items || !items.length) return;
      const trackMeta = (mod.tracks || []).find((t) => t.id === trackId);
      const trackName = trackMeta ? trackMeta.name : trackId;

      html += `
        <div class="group-head" id="track-${trackId}" style="--mod-color:${color}">
          <span class="group-count" style="color:${color};font-family:var(--font-mono);font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:0.1em">${FP.esc(trackId)}</span>
          <h3>${FP.esc(trackName)}</h3>
          <span class="group-count">${items.length} activit${items.length === 1 ? 'y' : 'ies'}</span>
        </div>
        <div class="challenge-grid">`;

      html += items.map((c) => `
        <a href="${FP.challengeUrl(c.id)}" class="ch-card reveal" style="--mod-color:${color}">
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
        </a>`).join('');

      html += '</div>';
    });

    grid.innerHTML = html;
    FP.initReveal();
  }

  function showError(msg) {
    const main = document.getElementById('mainContent');
    if (main) main.innerHTML = `<div class="wrap section"><div class="empty">${msg}</div></div>`;
  }

  function _setText(id, val) {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  }

  document.addEventListener('DOMContentLoaded', init);
})();

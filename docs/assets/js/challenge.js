/* Agentic DevOps — challenge detail page (?id=<challengeId>) */
(function () {
  'use strict';

  // Home-repo slugs (this live consolidated repo); render as plain text without a hyperlink.
  const SELF_SOURCE_REPOS = new Set([
    'microsoft/frontier-agenticdevops-hackathon',
    'microsoft/frontier-agentic-devops-hackathon',
  ]);

  let _kiosk = null;

  /* Internal challenge link that preserves kiosk state when active */
  function cUrl(id) {
    return _kiosk ? FP.kioskChallengeUrl(id, _kiosk) : FP.challengeUrl(id);
  }

  async function init() {
    const challengeId = FP.qp('id');
    if (!challengeId) { showError('No challenge ID specified.'); return; }

    _kiosk = FP.kioskParams();

    let data;
    try { data = await FP.loadData(); }
    catch (e) { showError(e.message); return; }

    const challenge = (data.challenges || []).find((c) => c.id === challengeId);
    if (!challenge) { showError('Challenge "' + challengeId + '" not found.'); return; }

    const mod = (data.modules || []).find((m) => m.id === challenge.module);
    const allChallenges = data.challenges || [];

    document.title = challenge.title + ' — Agentic DevOps';
    applyModuleColor(challenge.module);
    renderHero(challenge, mod);
    renderTakeHome(challenge);
    renderFacts(challenge, mod, allChallenges, data.outcomes || []);
    renderRelated(challenge, allChallenges);
    applyKioskLinks();
    initViewSwitch(challenge);
    loadGuide('student', challenge);
  }

  /* In kiosk mode, point the sidebar "back" link at the curated set */
  function applyKioskLinks() {
    if (!_kiosk) return;
    const back = document.querySelector('.facts-panel a[href="catalog.html"]');
    if (back) {
      back.setAttribute('href', FP.setUrl(_kiosk.ids, _kiosk.name));
      back.textContent = '← Back to set';
    }
  }

  function applyModuleColor(moduleId) {
    const color = FP.moduleColor(moduleId);
    document.documentElement.style.setProperty('--mod-color', color);
    document.querySelectorAll('[data-mod-color]').forEach((el) => {
      el.style.color = color;
    });
  }

  function renderHero(c, mod) {
    const color = FP.moduleColor(c.module);

    // Breadcrumbs
    const crumbs = document.getElementById('breadcrumbs');
    if (crumbs) {
      crumbs.innerHTML = `
        <a href="index.html">Home</a>
        <span>›</span>
        <a href="catalog.html">Catalog</a>
        <span>›</span>
        <a href="${FP.moduleUrl(c.module)}" style="color:${color}">${FP.esc(c.module.toUpperCase())}</a>
        <span>›</span>
        <span>${FP.esc(c.id)}</span>`;
    }

    _setText('challengeTitle', c.title);
    _setText('challengeId', c.id);

    const meta = document.getElementById('challengeMeta');
    if (meta) {
      meta.innerHTML = `
        ${FP.diffBadge(c.difficulty)}
        ${FP.durBadge(c.duration_minutes)}
        ${FP.emuBadge(c.emu_compatible)}
        ${c.tier && c.tier !== 'core' ? `<span class="badge badge-app">${FP.esc(c.tier)}</span>` : ''}
        ${c.app_dependency && c.app_dependency !== 'none' ? `<span class="badge badge-app">▣ ${FP.esc(c.app_dependency)}</span>` : ''}
        <span class="badge-tag badge" style="margin-left:auto;color:${color}">${FP.esc(c.module)} · ${FP.esc(c.track || '')}</span>`;
    }

    // Attribution
    const attr = document.getElementById('attribution');
    if (attr && c.source_repo) {
      if (SELF_SOURCE_REPOS.has(c.source_repo)) {
        attr.innerHTML = `Source: ${FP.esc(c.source_repo)} · ${FP.esc(c.license || 'MIT')} License`;
      } else {
        attr.innerHTML = `Source: <a href="https://github.com/${FP.esc(c.source_repo)}" target="_blank" rel="noopener">${FP.esc(c.source_repo)}</a> · ${FP.esc(c.license || 'MIT')} License`;
      }
    }
  }

  const OWNER_LABELS = {
    'developer': 'Developer',
    'platform-governance': 'Platform / Governance',
    'solution-architect': 'Solution Architect',
  };

  function renderTakeHome(c) {
    const card = document.getElementById('takeHomeCard');
    if (!card) return;
    const action = (c.take_home_action || '').trim();
    if (!action) { card.hidden = true; return; }
    card.hidden = false;

    const actionEl = document.getElementById('takeHomeAction');
    if (actionEl) actionEl.innerHTML = FP.renderInlineMd(action);

    const signal = (c.take_home_signal || '').trim();
    const signalEl = document.getElementById('takeHomeSignal');
    if (signalEl) {
      signalEl.innerHTML = signal
        ? `<span class="take-home-signal-label">You'll know it landed when</span> ${FP.renderInlineMd(signal)}`
        : '';
      signalEl.style.display = signal ? '' : 'none';
    }

    const owner = (c.take_home_owner || '').trim();
    const ownerEl = document.getElementById('takeHomeOwner');
    if (ownerEl) {
      if (owner) {
        ownerEl.textContent = OWNER_LABELS[owner] || owner;
        ownerEl.style.display = '';
      } else {
        ownerEl.style.display = 'none';
      }
    }
  }

  function renderFacts(c, mod, allChallenges, outcomes) {
    // Prerequisites    const prereqPanel = document.getElementById('prereqPanel');
    const prereqList  = document.getElementById('prereqList');
    if (prereqPanel && prereqList) {
      if (!c.prerequisites || !c.prerequisites.length) {
        prereqPanel.style.display = 'none';
      } else {
        prereqList.innerHTML = c.prerequisites.map((pid) => {
          const prereq = allChallenges.find((x) => x.id === pid);
          return `<li class="prereq-item">
            ${prereq
              ? `<a href="${cUrl(pid)}" style="color:${FP.moduleColor(prereq.module)}">${FP.esc(prereq.title)}</a>`
              : `<span class="mono">${FP.esc(pid)}</span>`}
          </li>`;
        }).join('');
      }
    }

    // Prerequisite capabilities
    const capPanel = document.getElementById('capPanel');
    const capList  = document.getElementById('capList');
    if (capPanel && capList) {
      if (!c.prerequisite_capabilities || !c.prerequisite_capabilities.length) {
        capPanel.style.display = 'none';
      } else {
        capList.innerHTML = c.prerequisite_capabilities
          .map((cap) => `<li class="cap-item">${FP.esc(cap)}</li>`)
          .join('');
      }
    }

    // Success criteria
    const criteriaList = document.getElementById('criteriaList');
    if (criteriaList) {
      criteriaList.innerHTML = (c.success_criteria || [])
        .map((s) => `<li class="criteria-item"><span>${FP.renderInlineMd(s)}</span></li>`)
        .join('') || '<li class="cap-item">See the challenge guide.</li>';
    }

    // Fact rows
    const factRows = document.getElementById('factRows');
    if (factRows) {
      const rows = [
        ['Difficulty', FP.diffBadge(c.difficulty)],
        ['Duration', FP.durBadge(c.duration_minutes) || '—'],
        ['Outcomes', outcomeLinks(c, outcomes)],
        ['Track', FP.esc(c.track || '—')],
        ['Tier', FP.esc(c.tier || 'core')],
        ['App', c.app_dependency && c.app_dependency !== 'none' ? FP.esc(c.app_dependency) : 'none'],
        ['EMU', FP.emuBadge(c.emu_compatible) || '—'],
      ];
      factRows.innerHTML = rows.map(([k, v]) =>
        `<div class="fact-row"><span class="fact-key">${k}</span><span class="fact-val">${v}</span></div>`
      ).join('');
    }

    function outcomeLinks(c, outcomes) {
      if (!c.outcomes || !c.outcomes.length) return '—';
      return c.outcomes.map((id) =>
        `<a href="${FP.catalogOutcomeUrl(id)}" class="badge badge-outcome">${FP.esc(FP.outcomeName(id, outcomes))}</a>`
      ).join(' ');
    }

    // Tags
    const tagsList = document.getElementById('tagsList');
    if (tagsList) {
      tagsList.innerHTML = (c.tags || [])
        .map((t) => `<span class="badge badge-tag">${FP.esc(t)}</span>`)
        .join('') || '<span class="text-dim" style="font-size:0.8rem">No tags</span>';
    }

    // References
    const refPanel = document.getElementById('refPanel');
    const refList  = document.getElementById('refList');
    if (refPanel && refList) {
      if (!c.references || !c.references.length) {
        refPanel.style.display = 'none';
      } else {
        refList.innerHTML = c.references.map((r) =>
          `<a href="${FP.esc(r)}" target="_blank" rel="noopener" class="attribution" style="display:block;margin-bottom:5px">${FP.esc(r.replace('https://', ''))}</a>`
        ).join('');
      }
    }
  }

  function renderRelated(c, allChallenges) {
    const relPanel = document.getElementById('relatedPanel');
    const relGrid  = document.getElementById('relatedGrid');
    if (!relPanel || !relGrid) return;

    const myTags = new Set(c.tags || []);
    const inSet = _kiosk ? new Set(_kiosk.ids) : null;
    const related = allChallenges
      .filter((x) => x.id !== c.id && (x.tags || []).some((t) => myTags.has(t)))
      .filter((x) => !inSet || inSet.has(x.id))
      .sort((a, b) => {
        const aMatch = (a.tags || []).filter((t) => myTags.has(t)).length;
        const bMatch = (b.tags || []).filter((t) => myTags.has(t)).length;
        return bMatch - aMatch;
      })
      .slice(0, 5);

    if (!related.length) { relPanel.style.display = 'none'; return; }

    relGrid.innerHTML = related.map((r) => {
      const color = FP.moduleColor(r.module);
      return `
        <a href="${cUrl(r.id)}" class="related-item">
          <span class="related-dot" style="background:${color}"></span>
          <span style="flex:1;min-width:0;font-size:0.8rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${FP.esc(r.title)}</span>
          <span class="badge badge-tag" style="color:${color};flex-shrink:0">${FP.esc(r.module)}</span>
        </a>`;
    }).join('');
  }

  function initViewSwitch(c) {
    const btns = document.querySelectorAll('.view-switch button');
    btns.forEach((btn) => {
      btn.addEventListener('click', () => {
        const view = btn.dataset.view;
        btns.forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.view === view)));
        document.body.setAttribute('data-view', view);
        loadGuide(view, c);
      });
    });
  }

  async function loadGuide(view, c) {
    const body = document.getElementById('guideBody');
    if (!body) return;

    const path = view === 'coach' ? c.coach_path : c.student_path;
    if (!path) {
      body.innerHTML = `<p class="text-dim" style="font-size:.875rem">Guide not available for this view.</p>`;
      return;
    }

    body.innerHTML = '<p class="text-dim" style="font-size:.875rem;font-family:var(--font-mono)">Loading guide…</p>';

    try {
      const res = await fetch(path, { cache: 'no-cache' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const md = await res.text();
      FP.renderMd(md, body);
    } catch (e) {
      body.innerHTML = `<p class="text-dim" style="font-size:.875rem">Could not load guide: ${FP.esc(e.message)}</p>`;
    }
  }

  function showError(msg) {
    const main = document.getElementById('mainContent');
    if (main) main.innerHTML = `<div class="wrap section"><div class="empty">${FP.esc(msg)}</div></div>`;
  }

  function _setText(id, val) {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  }

  document.addEventListener('DOMContentLoaded', init);
})();

/* Agentic DevSecOps — challenge detail page (?id=<challengeId>) */
(function () {
  'use strict';

  let _kiosk = null;
  let _sections = [];
  let _activeSection = 0;

  /* Internal challenge link that preserves kiosk state when active */
  function cUrl(id) {
    return _kiosk ? FP.kioskChallengeUrl(id, _kiosk) : FP.challengeUrl(id);
  }

  async function init() {
    const challengeId = FP.qp('id');
    if (!challengeId) { showError('No work package ID specified.'); return; }

    _kiosk = FP.kioskParams();

    let data;
    try { data = await FP.loadData(); }
    catch (e) { showError(e.message); return; }

    const challenge = (data.challenges || []).find((c) => c.id === challengeId);
    if (!challenge) { showError('Work package "' + challengeId + '" not found.'); return; }

    const mod = (data.modules || []).find((m) => m.id === challenge.module);
    const allChallenges = data.challenges || [];

    document.title = challenge.title + ' — Agentic DevSecOps';
    applyModuleColor(challenge.module);
    renderHero(challenge, mod);
    renderFacts(challenge, mod, allChallenges, data.outcomes || []);
    renderRelated(challenge, allChallenges);
    renderActivityPager(challenge, mod, allChallenges);
    applyKioskLinks();
    loadGuide(challenge);
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
        <span class="badge-tag badge" style="margin-left:auto;color:${color}">${FP.esc(c.module)} · ${FP.esc(c.track || '')}</span>`;
    }

    // Attribution
    const attr = document.getElementById('attribution');
    if (attr && c.source_repo) {
      const sourceUrl = FP.githubSourceUrl(c.source_repo);
      attr.innerHTML = `Origin: <a href="${sourceUrl}" target="_blank" rel="noopener">${FP.esc(c.source_repo)}</a>`;
    }
  }

  function renderFacts(c, mod, allChallenges, outcomes) {
    // Prerequisites
    const prereqPanel = document.getElementById('prereqPanel');
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

    // Fact rows
    const factRows = document.getElementById('factRows');
    if (factRows) {
      const rows = [
        ['Environment', environmentName(c.min_environment)],
        ['Application', c.app_dependency && c.app_dependency !== 'none' ? FP.esc(c.app_dependency) : 'None'],
        ['EMU', compatibilityBadge(c.emu_compatible)],
        ['Tier', FP.esc(c.tier || 'core')],
        ['Outcomes', outcomeLinks(c, outcomes)],
      ];
      factRows.innerHTML = rows.map(([k, v]) =>
        `<div class="fact-row"><span class="fact-key">${k}</span><span class="fact-val">${v}</span></div>`
      ).join('');
    }

    function environmentName(environment) {
      const names = {
        repo: 'Repository',
        org: 'Organization',
        enterprise: 'Enterprise',
      };
      return names[environment] || 'Not specified';
    }

    function compatibilityBadge(compatible) {
      const state = compatible === false ? 'no' : 'yes';
      const label = compatible === false ? 'Not compatible' : 'Compatible';
      return `<span class="compat-state compat-${state}"><span aria-hidden="true"></span>${label}</span>`;
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

    // Exact source file for the rendered guide.
    const sourcePanel = document.getElementById('sourcePanel');
    const sourceList = document.getElementById('sourceList');
    if (sourcePanel && sourceList) {
      const sources = [
        ['Delivery guide', c.student_source_repo, c.student_source_path],
      ].filter(([, repo, sourcePath]) => repo && sourcePath);

      if (!sources.length) {
        sourcePanel.style.display = 'none';
      } else {
        sourceList.innerHTML = sources.map(([label, repo, sourcePath]) =>
          `<a href="${FP.githubSourceUrl(repo, sourcePath, c.source_ref)}" target="_blank" rel="noopener" class="attribution" style="display:block;margin-bottom:5px">${FP.esc(label)} ↗</a>`
        ).join('');
      }
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

  function renderActivityPager(c, mod, allChallenges) {
    const pager = document.getElementById('activityPager');
    if (!pager) return;

    const ordered = _kiosk
      ? _kiosk.ids.map((id) => allChallenges.find((item) => item.id === id)).filter(Boolean)
      : FP.orderModuleActivities(
          allChallenges.filter((item) => item.module === c.module),
          mod
        );
    const index = ordered.findIndex((item) => item.id === c.id);
    if (index < 0) return;

    pager.innerHTML = [
      activityPagerCard('Previous activity', ordered[index - 1], 'previous'),
      activityPagerCard('Next activity', ordered[index + 1], 'next'),
    ].join('');
    pager.hidden = false;
  }

  function activityPagerCard(label, target, direction) {
    if (!target) {
      return `<span class="activity-pager-card is-disabled ${direction}" aria-hidden="true"></span>`;
    }

    const arrow = direction === 'previous'
      ? '<span class="activity-pager-arrow" aria-hidden="true">←</span>'
      : '<span class="activity-pager-arrow" aria-hidden="true">→</span>';
    return `
      <a class="activity-pager-card ${direction}" href="${cUrl(target.id)}">
        ${direction === 'previous' ? arrow : ''}
        <span class="activity-pager-copy">
          <span class="activity-pager-label">${label}</span>
          <strong>${FP.esc(target.title)}</strong>
          <span class="activity-pager-id">${FP.esc(target.id)} · ${FP.esc(target.track || target.module)}</span>
        </span>
        ${direction === 'next' ? arrow : ''}
      </a>`;
  }

  async function loadGuide(c) {
    const body = document.getElementById('guideBody');
    if (!body) return;

    const path = c.student_path;
    if (!path) {
      body.innerHTML = `<p class="text-dim" style="font-size:.875rem">Guide not available.</p>`;
      return;
    }

    body.innerHTML = '<p class="text-dim" style="font-size:.875rem;font-family:var(--font-mono)">Loading guide…</p>';

    try {
      const res = await fetch(path, { cache: 'no-cache' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const md = await res.text();
      FP.renderMd(md, body);
      buildGuideSections(body);
    } catch (e) {
      body.innerHTML = `<p class="text-dim" style="font-size:.875rem">Could not load guide: ${FP.esc(e.message)}</p>`;
    }
  }

  function buildGuideSections(body) {
    const children = Array.from(body.children);
    if (!children.some((node) => node.tagName === 'H2')) return;

    let definitions = [];
    let current = { title: 'Overview', nodes: [] };

    children.forEach((node) => {
      if (node.tagName === 'H2') {
        if (current.nodes.length) definitions.push(current);
        current = { title: node.textContent.trim() || 'Section', nodes: [node] };
      } else {
        current.nodes.push(node);
      }
    });
    if (current.nodes.length) definitions.push(current);
    definitions = foldIntoOverview(definitions);
    if (definitions.length < 2) return;

    const usedSlugs = new Set();
    const usedHeadingSlugs = new Set();
    body.innerHTML = '';
    _sections = definitions.map((definition, index) => {
      const slug = uniqueSlug(definition.title, index, usedSlugs);
      const section = document.createElement('section');
      section.className = 'guide-section';
      section.id = 'section-' + slug;
      section.setAttribute('role', 'tabpanel');
      section.setAttribute('aria-labelledby', 'section-tab-' + slug);
      definition.nodes.forEach((node) => section.appendChild(node));
      const aliases = Array.from(section.querySelectorAll('h1, h2')).map((heading, headingIndex) => {
        const headingSlug = uniqueSlug(heading.textContent.trim(), headingIndex, usedHeadingSlugs);
        heading.id = headingSlug;
        return headingSlug;
      });
      body.appendChild(section);
      return { title: definition.title, slug, aliases, element: section };
    });

    renderSectionRail();
    bindSectionNavigation(body);
    document.body.classList.add('has-guide-sections');

    const hash = currentHashSlug();
    const initial = sectionIndexForSlug(hash);
    activateSection(initial >= 0 ? initial : 0, false, initial >= 0);
  }

  function foldIntoOverview(definitions) {
    const supporting = definitions.filter((definition) => sectionKind(definition.title));
    if (!supporting.length) return definitions;

    const overviewIndex = definitions.findIndex((definition) => definition.title === 'Overview');
    const overview = overviewIndex >= 0
      ? definitions[overviewIndex]
      : { title: 'Overview', nodes: [] };

    supporting.forEach((definition) => {
      if (definition !== overview) overview.nodes.push(...definition.nodes);
    });

    return [
      overview,
      ...definitions.filter((definition, index) =>
        index !== overviewIndex && !sectionKind(definition.title)
      ),
    ];
  }

  function sectionKind(title) {
    const value = String(title).trim();
    if (/^prerequisites\b/i.test(value)) return 'prerequisites';
    if (/^(objectives|goals|required outcome|outcomes?)\b/i.test(value)) return 'outcomes';
    if (/^what\s+(?:you\s+will|you['’]ll)\s+(?:deliver|do|practice)\b/i.test(value)) return 'outcomes';
    return '';
  }

  function uniqueSlug(title, index, usedSlugs) {
    const base = String(title)
      .normalize('NFKD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '') || 'section-' + (index + 1);
    let slug = base;
    let suffix = 2;
    while (usedSlugs.has(slug)) slug = base + '-' + suffix++;
    usedSlugs.add(slug);
    return slug;
  }

  function renderSectionRail() {
    const nav = document.getElementById('guideSectionNav');
    const tabs = document.getElementById('guideSectionTabs');
    if (!nav || !tabs) return;

    tabs.innerHTML = _sections.map((section, index) => `
      <button class="guide-section-tab" id="section-tab-${section.slug}" type="button"
        role="tab" aria-controls="section-${section.slug}" aria-selected="false"
        tabindex="-1" data-section-index="${index}">
        <span>${String(index + 1).padStart(2, '0')}</span>
        ${FP.esc(section.title)}
      </button>`
    ).join('');
    nav.hidden = false;
  }

  function bindSectionNavigation(body) {
    const tabs = document.getElementById('guideSectionTabs');
    const pager = document.getElementById('guideSectionPager');
    const previous = document.getElementById('sectionScrollPrev');
    const next = document.getElementById('sectionScrollNext');

    tabs?.addEventListener('click', (event) => {
      const tab = event.target.closest('[data-section-index]');
      if (tab) activateSection(Number(tab.dataset.sectionIndex), true, true);
    });
    tabs?.addEventListener('keydown', (event) => {
      const tab = event.target.closest('[data-section-index]');
      if (!tab) return;
      const currentIndex = Number(tab.dataset.sectionIndex);
      const destinations = {
        ArrowLeft: Math.max(0, currentIndex - 1),
        ArrowRight: Math.min(_sections.length - 1, currentIndex + 1),
        Home: 0,
        End: _sections.length - 1,
      };
      if (!(event.key in destinations)) return;
      event.preventDefault();
      const destination = destinations[event.key];
      activateSection(destination, true, true);
      document.getElementById('section-tab-' + _sections[destination].slug)?.focus();
    });
    pager?.addEventListener('click', (event) => {
      const button = event.target.closest('[data-section-index]');
      if (button) activateSection(Number(button.dataset.sectionIndex), true, true);
    });
    previous?.addEventListener('click', () => tabs?.scrollBy({ left: -320, behavior: 'smooth' }));
    next?.addEventListener('click', () => tabs?.scrollBy({ left: 320, behavior: 'smooth' }));

    body.addEventListener('click', (event) => {
      const link = event.target.closest('a[href^="#"]');
      if (!link) return;
      const slug = decodeURIComponent(link.getAttribute('href').slice(1));
      const index = sectionIndexForSlug(slug);
      if (index < 0) return;
      event.preventDefault();
      activateSection(index, true, true);
    });

    const restoreSectionFromUrl = () => {
      const slug = currentHashSlug();
      const index = sectionIndexForSlug(slug);
      if (index >= 0 && index !== _activeSection) activateSection(index, false, false);
    };
    window.addEventListener('hashchange', restoreSectionFromUrl);
    window.addEventListener('popstate', restoreSectionFromUrl);
  }

  function currentHashSlug() {
    try {
      return decodeURIComponent(window.location.hash.replace(/^#/, ''));
    } catch (e) {
      return '';
    }
  }

  function sectionIndexForSlug(slug) {
    return _sections.findIndex((section) =>
      section.slug === slug || section.aliases.includes(slug)
    );
  }

  function activateSection(index, updateHistory, scrollToGuide) {
    if (!_sections[index]) return;
    _activeSection = index;

    _sections.forEach((section, sectionIndex) => {
      const active = sectionIndex === index;
      section.element.hidden = !active;
      const tab = document.getElementById('section-tab-' + section.slug);
      if (tab) {
        tab.setAttribute('aria-selected', String(active));
        tab.tabIndex = active ? 0 : -1;
        if (active && tab.parentElement) {
          tab.parentElement.scrollTo({
            left: tab.offsetLeft - (tab.parentElement.clientWidth - tab.offsetWidth) / 2,
            behavior: 'smooth',
          });
        }
      }
    });

    const progress = document.getElementById('guideSectionProgress');
    if (progress) progress.textContent = (index + 1) + ' / ' + _sections.length;
    renderSectionPager();

    if (updateHistory) {
      window.history.pushState(null, '', '#' + _sections[index].slug);
    }
    if (scrollToGuide) {
      const nav = document.getElementById('guideSectionNav');
      const top = nav ? nav.offsetTop - 58 : 0;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  }

  function renderSectionPager() {
    const pager = document.getElementById('guideSectionPager');
    if (!pager) return;

    const previous = _sections[_activeSection - 1];
    const next = _sections[_activeSection + 1];
    pager.innerHTML = [
      sectionPagerButton('Previous section', previous, _activeSection - 1, 'previous'),
      sectionPagerButton('Next section', next, _activeSection + 1, 'next'),
    ].join('');
    pager.hidden = false;
  }

  function sectionPagerButton(label, section, index, direction) {
    if (!section) return `<span class="guide-pager-button is-disabled ${direction}" aria-hidden="true"></span>`;
    return `
      <button class="guide-pager-button ${direction}" type="button" data-section-index="${index}">
        <span class="guide-pager-label">${label}</span>
        <strong>${FP.esc(section.title)}</strong>
      </button>`;
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

'use strict';

const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');
const { validateOutcomes, enrichOutcome, challengeIdFromSlug } = require('../docs/build.js');

const root = path.resolve(__dirname, '..');
const data = JSON.parse(fs.readFileSync(path.join(root, 'docs/assets/data/platform.json'), 'utf8'));
const scripts = Object.fromEntries(['core', 'catalog', 'builder', 'home', 'set', 'challenge'].map((name) => [
  name, fs.readFileSync(path.join(root, `docs/assets/js/${name}.js`), 'utf8'),
]));

test('all activity summaries fit the card copy limits', () => {
  for (const activity of data.challenges) {
    assert(activity.description.trim(), `${activity.id}: missing summary`);
    assert(activity.description.length <= 100, `${activity.id}: exceeds 100 characters`);
    assert(activity.description.trim().split(/\s+/).length <= 16, `${activity.id}: exceeds 16 words`);
  }
});

test('catalog and builder have no nested route controls', () => {
  for (const name of ['catalog', 'builder']) {
    const html = fs.readFileSync(path.join(root, `docs/${name}.html`), 'utf8');
    assert(!/journeyPanel|routeSelect|journey-options/.test(html));
    assert(!/_activeRoute|renderJourneySelector|selectedRoute/.test(scripts[name]));
  }
  assert(!/renderJourneySelector|selectedRoute|journey-options/.test(scripts.core));
});

async function render(page, query = '', platform = data) {
  let init;
  const elements = Object.fromEntries([
    'grid', 'count', 'trackChips', 'outcomeChips',
    'outcomeGrid', 'setIntro', 'setHeading', 'challengeTitle', 'challengeId',
    'challengeMeta', 'activityPager', 'generateBtn', 'deselectBtn', 'setName',
    'linkRow', 'setLink', 'openBtn', 'setCount',
  ].map((id) => [
    id, {
      innerHTML: '', textContent: '', hidden: false, value: '', listeners: {},
      querySelectorAll: () => [], setAttribute() {},
      addEventListener(event, callback) { this.listeners[event] = callback; },
    },
  ]));
  elements.grid.querySelectorAll = selector => {
    if (selector !== '.sel-card') return [];
    elements.grid.cards = [...elements.grid.innerHTML.matchAll(/data-id="([^"]+)"/g)].map(match => ({
      dataset: { id: match[1] }, listeners: {}, setAttribute() {},
      addEventListener(event, callback) { this.listeners[event] = callback; },
    }));
    return elements.grid.cards;
  };
  const context = {
    URLSearchParams,
    URL,
    location: { search: query, pathname: `/${page}.html`, href: `https://example.test/${page}.html${query}` },
    history: { replaceState(_state, _title, url) { context.lastUrl = url; } },
    document: {
      getElementById: (id) => elements[id] || null,
      querySelectorAll: () => [],
      querySelector: () => null,
      documentElement: { style: { setProperty() {} } },
      addEventListener: (event, callback) => { if (event === 'DOMContentLoaded') init = callback; },
    },
  };
  context.window = context;
  vm.createContext(context);
  vm.runInContext(scripts.core, context);
  context.FP.loadData = async () => platform;
  vm.runInContext(scripts[page], context);
  await init();
  const cardPattern = page === 'builder' ? /data-id="([^"]+)"/g : /href="challenge.html\?id=([^"&]+)[^"]*"/g;
  const snapshot = () => {
    const html = elements.grid.innerHTML;
    return {
      html,
      headings: [...html.matchAll(/<h3>(.*?)<\/h3>/g)].map((match) => match[1]),
      intros: [...html.matchAll(/<p class="group-intro">(.*?)<\/p>/g)].map((match) => match[1]),
      ids: [...html.matchAll(cardPattern)].map((match) => match[1]),
      count: elements.count.textContent,
      chips: elements.trackChips.innerHTML,
    };
  };
  return {
    ...snapshot(),
    elements, context, snapshot,
    FP: context.FP,
  };
}

for (const page of ['catalog', 'builder']) {
  test(`${page}: unfiltered results group by session type without losing or duplicating activities`, async () => {
    const result = await render(page);
    assert.equal(result.ids.length, data.challenges.length);
    assert.equal(new Set(result.ids).size, data.challenges.length);
    assert.deepEqual([...result.ids].sort(), data.challenges.map((c) => c.id).sort());
    const tracks = result.FP.catalogTracks(data.modules);
    assert.deepEqual(result.headings, Array.from(tracks, (track) => result.FP.esc(track.name)));
    assert.deepEqual(result.intros, Array.from(tracks, (track) => result.FP.esc(track.description)));
    for (const track of tracks) assert(result.chips.includes(result.FP.esc(track.name)));
    for (const activity of data.challenges) {
      assert(result.html.includes(`<div class="ch-desc">${result.FP.esc(activity.description)}</div>`));
    }
    assert(result.html.includes('badge-outcome'));
  });

  for (const outcome of data.outcomes) {
    test(`${page}: ${outcome.id} shows all chapters without another selection`, async () => {
      const result = await render(page, `?outcome=${outcome.id}`);
      assert.deepEqual(result.ids, outcome.challenge_ids);
      assert.deepEqual(result.headings, [result.FP.esc(outcome.name)]);
      assert(!result.html.includes('badge-outcome'));
      assert(!result.html.includes('<select'));
      assert(!result.html.includes('<details'));
      assert.equal(result.count, `${outcome.challenge_ids.length} activities`);
      for (const id of result.ids) {
        const activity = data.challenges.find(c => c.id === id);
        const product = result.FP.moduleName(activity.module, data.modules);
        assert(result.html.includes(`<span class="ch-module-label">${result.FP.esc(product)}</span>`));
      }
    });
  }

  test(`${page}: migration chapters are immediately available for every source platform`, async () => {
    const result = await render(page, '?outcome=platform-migration');
    for (const id of ['ghec-ch21', 'ghec-ch24', 'ghec-ch25', 'ghec-ch26']) {
      assert(result.ids.includes(id));
    }
  });

  test(`${page}: old route URLs no longer narrow or block the outcome`, async () => {
    const outcome = data.outcomes.find(o => o.id === 'platform-migration');
    for (const route of ['gitlab', 'not-a-route']) {
      const result = await render(page, `?outcome=${outcome.id}&route=${route}&track=migration&difficulty=intermediate`);
      const expected = outcome.challenge_ids.filter(id => {
        const activity = data.challenges.find(c => c.id === id);
        return activity.track === 'migration' && activity.difficulty === 'intermediate';
      });
      assert.deepEqual(result.ids, expected);
      assert(!result.context.lastUrl.includes('route='));
      assert(result.context.lastUrl.includes('outcome=platform-migration'));
      assert(result.context.lastUrl.includes('track=migration'));
      assert(result.context.lastUrl.includes('difficulty=intermediate'));
    }
  });

  test(`${page}: search finds any source platform even in an old route URL`, async () => {
    const result = await render(page, '?outcome=platform-migration&route=gitlab&q=Bitbucket');
    assert(result.ids.includes('ghec-ch24'));
  });

  test(`${page}: session-type and level filters include GHAS developer sessions`, async () => {
    const result = await render(page, '?track=developer-flow&difficulty=beginner');
    const expected = data.challenges.filter((c) => c.track === 'developer-flow' && c.difficulty === 'beginner');
    assert.deepEqual([...result.ids].sort(), expected.map((c) => c.id).sort());
    assert.deepEqual(result.headings, ['Developer Flow']);
    assert(result.ids.includes('ghas-00'));
    assert(!result.ids.includes('ghas-01'));
  });

  test(`${page}: empty results have no group headings`, async () => {
    const result = await render(page, '?q=no-such-session-987654321');
    assert.deepEqual(result.ids, []);
    assert.deepEqual(result.headings, []);
    assert.deepEqual(result.intros, []);
    assert.equal(result.count, '0 activities');
    assert(result.html.includes('no-results'));
  });

  test(`${page}: interleaved products stay in outcome order and headings are escaped`, async () => {
    const fixture = JSON.parse(JSON.stringify(data));
    const ids = ['ghec-ch00', 'ghas-00', 'ghec-ch01'];
    fixture.outcomes = [{
      id: 'mixed', name: 'Delivery & <review>', tagline: 'Plan & <review> changes.', challenge_ids: ids,
    }];
    fixture.challenges.forEach((c) => { c.outcomes = ids.includes(c.id) ? ['mixed'] : []; });
    const result = await render(page, '?outcome=mixed', fixture);
    assert.deepEqual(result.ids, ids);
    assert.deepEqual(result.headings, ['Delivery &amp; &lt;review&gt;']);
    assert.deepEqual(result.intros, ['Plan &amp; &lt;review&gt; changes.']);
  });

  test(`${page}: descriptions are used when taglines are absent, with no empty intro`, async () => {
    const fixture = JSON.parse(JSON.stringify(data));
    const outcome = fixture.outcomes[0];
    delete outcome.tagline;
    const result = await render(page, `?outcome=${outcome.id}`, fixture);
    assert.deepEqual(result.intros, [result.FP.esc(outcome.description)]);
    delete outcome.description;
    const withoutIntro = await render(page, `?outcome=${outcome.id}`, fixture);
    assert.deepEqual(withoutIntro.intros, []);
    assert.deepEqual(withoutIntro.ids, outcome.challenge_ids);
  });
}

test('every active activity is discoverable through a homepage result', () => {
  const ids = new Set(data.outcomes.flatMap(outcome => outcome.challenge_ids));
  for (const activity of data.challenges) assert(ids.has(activity.id), `${activity.id} has no outcome`);
});

test('outcomes contain unique activity lists and accurate catalog totals', () => {
  const byId = new Map(data.challenges.map(c => [c.id, c]));
  for (const outcome of data.outcomes) {
    assert.equal(outcome.challenge_count, outcome.challenge_ids.length);
    assert.equal(new Set(outcome.challenge_ids).size, outcome.challenge_ids.length);
    assert.equal(outcome.duration_minutes,
      outcome.challenge_ids.reduce((sum, id) => sum + byId.get(id).duration_minutes, 0));
    for (const key of ['routes', 'default_route', 'optional_groups', 'duration_minutes_min', 'duration_minutes_max']) {
      assert(!Object.hasOwn(outcome, key));
    }
  }
});

test('all outcomes and prerequisites validate, with exact forwarding mappings', () => {
  assert.deepEqual(validateOutcomes(data.outcomes, data.challenges), []);
  assert.deepEqual(data.retired_challenges, {
    'ghec-ch06': 'ghec-ch07', 'ghec-ch17': 'ghec-ch20',
    'ghec-ch47': 'ghec-ch02', 'ghec-ch50': 'ghas-admin-05',
    'ghec-ch16': 'ghec-ch20', 'ghec-ch52': 'ghec-ch07',
    'ghec-ch35': 'ghec-ch01', 'ghec-ch43': 'ghec-ch42', 'ghas-06': 'ghas-admin-06',
    'ghas-01': 'ghas-00', 'ghas-05': 'ghas-admin-05',
    'ghas-admin-04': 'ghas-admin-03', 'sre-agent-00': 'sre-agent-01',
    'ghaw-01': 'ghaw-07', 'ghaw-11': 'ghaw-18', 'ghaw-14': 'ghaw-18',
    'ghaw-23': 'ghas-admin-06', 'ghaw-25': 'ghec-ch01',
    'ghaw-03': 'ghaw-19', 'ghaw-08': 'ghaw-17', 'ghaw-09': 'ghaw-17',
    'ghaw-10': 'ghaw-07', 'ghaw-12': 'ghaw-06', 'ghaw-16': 'ghaw-18',
    'ghaw-20': 'ghaw-19', 'ghaw-24': 'ghaw-06',
  });
  const ids = new Set(data.challenges.map(c => c.id));
  for (const [id, replacement] of Object.entries(data.retired_challenges)) {
    assert(!ids.has(id));
    assert(ids.has(replacement));
  }
  for (const c of data.challenges) for (const dependency of c.prerequisites) assert(ids.has(dependency));
});

test('build rejects invalid outcome membership instead of silently dropping work', () => {
  const activities = [{ id: 'setup', prerequisites: [], duration_minutes: 10 },
    { id: 'pilot', prerequisites: ['setup'], duration_minutes: 20 }];
  const outcome = {
    id: 'result', name: 'Result', challenge_ids: ['setup', 'pilot'],
  };
  assert.deepEqual(validateOutcomes([outcome], activities), []);
  assert.equal(enrichOutcome(outcome, activities).duration_minutes, 30);
  const missing = JSON.parse(JSON.stringify(outcome));
  missing.challenge_ids = ['pilot', 'unknown'];
  const errors = validateOutcomes([missing], activities).join('\n');
  assert.match(errors, /unknown or retired/);
  const duplicate = JSON.parse(JSON.stringify(outcome));
  duplicate.challenge_ids.push('pilot');
  assert.match(validateOutcomes([duplicate], activities).join('\n'), /duplicate activities/);
  const empty = { ...outcome, challenge_ids: [] };
  assert.match(validateOutcomes([empty], activities).join('\n'), /at least one activity/);
  assert.match(validateOutcomes([outcome, outcome], activities).join('\n'), /unique id/);
});

test('homepage offers learning and wizard routes before the activity outcomes', () => {
  const html = fs.readFileSync(path.join(root, 'docs/index.html'), 'utf8');
  const routes = [...html.matchAll(/<a href="([^"]+)" class="start-route[^"]*">([\s\S]*?)<\/a>/g)];
  assert.equal(routes.length, 2);
  assert.equal(routes[0][1], '#outcomes');
  assert.match(routes[0][2], /Learn by doing/);
  assert.equal(routes[1][1], 'wizard.html');
  assert.match(routes[1][2], /Set up with the wizard/);
  assert(html.indexOf('class="start-routes"') < html.indexOf('id="outcomes"'));
});

test('wizard pages resolve local assets, page links, and section links', () => {
  for (const name of ['wizard', 'wizard-guide']) {
    const file = path.join(root, `docs/${name}.html`);
    const html = fs.readFileSync(file, 'utf8');
    for (const [, href] of html.matchAll(/\b(?:href|src)="([^"]+)"/g)) {
      if (/^https?:/.test(href)) continue;
      const [target, fragment] = href.split('#');
      const targetPath = target ? path.resolve(path.dirname(file), target) : file;
      assert(fs.existsSync(targetPath), `${name}: missing ${href}`);
      if (fragment) {
        assert(fs.readFileSync(targetPath, 'utf8').includes(`id="${fragment}"`), `${name}: missing section ${href}`);
      }
    }
    assert.match(html, /id="navLinks"/);
    assert.match(html, /aria-controls="navLinks"/);
    assert.match(html, /src="assets\/js\/shell.js"/);
  }
});

test('core delegates navigation to the shared shell without attaching a second toggle', () => {
  let refreshed = 0;
  const context = {
    document: {
      addEventListener() {},
      querySelector() { assert.fail('core must not attach a second navigation handler'); },
    },
    RVASShell: { refresh() { refreshed++; } },
  };
  context.window = context;
  vm.createContext(context);
  vm.runInContext(scripts.core, context);
  context.FP.initNav();
  assert.equal(refreshed, 1);
});

test('homepage outcomes show activity counts without nested route choices or full-catalog time estimates', async () => {
  const result = await render('home');
  for (const outcome of data.outcomes) {
    assert(result.elements.outcomeGrid.innerHTML.includes(result.FP.esc(outcome.name)));
    assert(result.elements.outcomeGrid.innerHTML.includes(`${outcome.challenge_count} activities`));
    assert(!result.elements.outcomeGrid.innerHTML.includes(result.FP.durBadge(outcome.duration_minutes)));
  }
  assert(!result.elements.outcomeGrid.innerHTML.includes('route'));
  assert(!result.elements.outcomeGrid.innerHTML.includes('Optional extensions'));
});

test('sets resolve aliases once without changing cross-product order', async () => {
  const result = await render('set', '?ids=ghec-ch00,ghas-06,ghec-ch01,ghas-admin-06');
  assert.deepEqual(result.ids, ['ghec-ch00', 'ghas-admin-06', 'ghec-ch01']);
  assert(!/merged|retired|replaced/i.test(result.elements.setIntro.textContent));
});

test('repository intake and template preparation remain separate sessions', async () => {
  const result = await render('set', '?ids=ghec-ch36,ghec-ch38,ghec-ch39');
  assert.deepEqual(result.ids, ['ghec-ch36', 'ghec-ch38', 'ghec-ch39']);
  const activity = await render('challenge', '?id=ghec-ch36');
  assert.equal(activity.elements.challengeId.textContent, 'ghec-ch36');
  assert.equal(challengeIdFromSlug('ghec', '36-controlled-repo-intake'), 'ghec-ch36');
  assert.deepEqual(data.challenges.find(c => c.id === 'ghec-ch36').prerequisites, ['ghec-ch38']);
  const template = data.challenges.find(c => c.id === 'ghec-ch38');
  const guide = fs.readFileSync(path.join(root, template.student_source_path), 'utf8');
  assert(!/gh repo create|permission=push|repository-request\.yml/.test(guide));
});

test('saved sets report missing IDs', async () => {
  const result = await render('set', '?ids=ghec-ch00,unknown');
  assert(result.elements.setIntro.textContent.includes('Unavailable activities: unknown'));
  assert.deepEqual(result.ids, ['ghec-ch00']);
});

test('activity aliases resolve silently and preserve set navigation', async () => {
  const result = await render('challenge', '?id=ghaw-03&set=ghaw-00,ghaw-03,ghaw-19');
  assert.equal(result.elements.challengeId.textContent, 'ghaw-19');
  assert(!/merged|retired|replaced/i.test(result.elements.challengeMeta.innerHTML));
  assert(result.elements.activityPager.innerHTML.includes('id=ghaw-00'));
  assert(!result.elements.activityPager.innerHTML.includes('id=ghaw-03'));
});

test('activity pager follows outcome chapters and removes old route parameters', async () => {
  const result = await render('challenge', '?id=ghec-ch23&outcome=platform-migration&route=azure-devops');
  const ids = data.outcomes.find(o => o.id === 'platform-migration').challenge_ids;
  const index = ids.indexOf('ghec-ch23');
  assert(result.elements.activityPager.innerHTML.includes(`id=${ids[index - 1]}`));
  assert(result.elements.activityPager.innerHTML.includes(`id=${ids[index + 1]}`));
  assert(result.elements.activityPager.innerHTML.includes('outcome=platform-migration'));
  assert(!result.elements.activityPager.innerHTML.includes('route='));
});

test('guide links resolve active metadata IDs without placeholder folders', () => {
  assert.equal(challengeIdFromSlug('ghec', '01-issues-labels-projects'), 'ghec-ch01');
  assert.equal(challengeIdFromSlug('ghaw', '03-the-watcher'), null);
  assert.equal(challengeIdFromSlug('ghas', '06-security-campaigns'), null);
  assert.equal(challengeIdFromSlug('ghec', '../resources'), null);
});

test('catalog contains 61 active sessions and no alias has a generated guide', () => {
  assert.equal(data.challenges.length, 61);
  assert.deepEqual(Object.fromEntries(data.modules.map(m => [m.id, m.challenge_count])),
    { ghec: 41, ghas: 9, ghaw: 7, 'sre-agent': 4 });
  for (const id of Object.keys(data.retired_challenges)) {
    assert(!fs.existsSync(path.join(root, 'docs/assets/data/challenges', id)));
  }
  const ghaw = data.modules.find(m => m.id === 'ghaw');
  assert(!ghaw.tracks.some(t => t.id === 'continuous-intelligence'));
});

test('active guides do not refer participants to removed sessions', () => {
  const retiredIds = new RegExp(`\\b(?:${Object.keys(data.retired_challenges).join('|')})\\b`, 'i');
  for (const activity of data.challenges) {
    const guide = fs.readFileSync(path.join(root, activity.student_source_path), 'utf8');
    assert(!retiredIds.test(guide), `${activity.id} refers to a removed activity ID`);
    assert(!/\bCh(?:06|16|17|35|43|47|50|52)\b/.test(guide), `${activity.id} refers to a removed chapter`);
  }
});

test('integration provisioner seeds canonical files without extra scaffolding', () => {
  const resources = path.join(root, 'modules/ghec/resources');
  const directory = path.join(resources, 'provisioning/challenges/20-automation-capstone');
  const output = execFileSync('bash', ['-c', `
    set -euo pipefail
    CH_DIR="$1"
    ORG=example
    REPO=integration-test
    die() { printf '%s\\n' "$1" >&2; exit 1; }
    gh_put_file() {
      node -e 'console.log(JSON.stringify({path: process.argv[1], content: process.argv[2]}))' "$3" "$5"
    }
    source "$CH_DIR/provision.sh"
    _ch20_seed_repo
  `, 'test-provision', directory], { encoding: 'utf8' });
  const files = Object.fromEntries(output.trim().split('\n').map(line => {
    const file = JSON.parse(line);
    return [file.path, file.content];
  }));
  assert.deepEqual(Object.keys(files).sort(), ['README.md', 'package.json', 'src/handler.cjs', 'src/handler.test.cjs']);
  for (const name of ['handler.cjs', 'handler.test.cjs']) {
    assert.equal(files[`src/${name}`],
      fs.readFileSync(path.join(resources, 'integration', name), 'utf8').replace(/\n+$/, ''));
  }
  assert.deepEqual(JSON.parse(files['package.json']).scripts,
    { start: 'node src/handler.cjs', test: 'node --test src/handler.test.cjs' });
});

test('customer-target activities do not offer unrelated provisioning samples', () => {
  const numbers = ['31', '36', '38', '39', '41', '44', '45', '49', '51'];
  for (const number of numbers) {
    const activity = data.challenges.find(c => c.id === `ghec-ch${number}`);
    assert(activity, `missing activity ${number}`);
    const guide = fs.readFileSync(path.join(root, activity.student_source_path), 'utf8');
    assert(!new RegExp(`setup\\.(?:sh|ps1) provision ch${number}\\b`).test(guide));
    const slug = path.basename(path.dirname(activity.student_source_path));
    for (const extension of ['sh', 'ps1']) {
      for (const directory of [
        path.join(root, 'modules/ghec/resources/provisioning/challenges', slug),
        path.dirname(path.join(root, activity.student_source_path)),
      ]) {
        assert(!fs.existsSync(path.join(directory, `provision.${extension}`)),
          `${activity.id} still has a misleading provisioner`);
      }
    }
  }
});

test('reorganized sessions keep complete capabilities without repeated setup', () => {
  const byId = new Map(data.challenges.map(c => [c.id, c]));
  const guide = id => fs.readFileSync(path.join(root, byId.get(id).student_source_path), 'utf8');
  assert.match(guide('ghec-ch20'), /Try a native feature first/);
  assert.match(guide('ghec-ch20'), /Operate the App path/);
  assert.match(guide('ghas-admin-03'), /Correct and merge the same PR/);
  assert.match(guide('ghas-admin-05'), /license policy to the same check/);
  assert.match(guide('ghas-admin-02'), /Respond to an exposed credential/);
  assert.match(guide('ghec-ch02'), /Contribute across teams/);
  assert.match(guide('ghec-ch07'), /Repository creation belongs to Ch36/);
  assert.equal(byId.get('ghec-ch31').tier, 'stretch');
  assert.match(guide('ghec-ch19'), /copilot-first-run\.md/);
  assert.match(guide('ghec-ch32'), /copilot-first-run\.md/);
  assert(!byId.get('ghec-ch49').prerequisite_capabilities.some(c => /Ch39/.test(c)));
  assert.match(guide('ghec-ch49'), /cloud deployment are not prerequisites/);
  assert.match(guide('ghec-ch39'), /environment-approval\.md/);
  assert.match(guide('ghec-ch49'), /environment-approval\.md/);
  assert.deepEqual(byId.get('sre-agent-01').prerequisites, []);
  assert.match(guide('sre-agent-01'), /Approve the service and check access/);
  assert.match(guide('sre-agent-01'), /Grubify/);
  for (const id of ['ghas-02', 'ghas-03', 'ghas-04']) {
    assert.deepEqual(byId.get(id).prerequisites, ['ghas-00']);
    assert.match(guide(id), /start-remediation\.md/);
  }
});

test('saved combined-session links resolve directly and do not duplicate activities', async () => {
  const result = await render('set', '?ids=ghec-ch17,ghec-ch20,ghas-admin-04,ghas-admin-03,ghec-ch50,ghas-admin-05,sre-agent-00,sre-agent-01');
  assert.deepEqual(result.ids, ['ghec-ch20', 'ghas-admin-03', 'ghas-admin-05', 'sre-agent-01']);
  for (const slug of ['06-enterprise-org-101', '17-webhooks-github-apps',
    '47-innersource-program-operations', '50-license-compliance-workflow']) {
    assert(!fs.existsSync(path.join(root, 'modules/ghec/challenges', slug)));
  }
  for (const slug of ['01-explore-attack-surface', '04-admin-codeql-merge-enforcement',
    '05-secrets-and-dependencies']) {
    assert(!fs.existsSync(path.join(root, 'modules/ghas/challenges', slug)));
  }
  assert(!fs.existsSync(path.join(root, 'modules/sre-agent/challenges/00-setup')));
  for (const [module, file] of [['ghec', 'copilot-first-run.md'], ['ghec', 'environment-approval.md'],
    ['ghas', 'start-remediation.md'], ['ghas', 'license-exception.yml']]) {
    assert(fs.existsSync(path.join(root, 'docs/resources', module, file)));
  }
});

test('CodeQL fixture renders one current enforcement workflow and a safe replacement', () => {
  const fixture = path.join(root, 'modules/ghas/resources/provisioning/challenges/ghas-admin-codeql-live-20260915');
  const shell = fs.readFileSync(path.join(fixture, 'provision.sh'), 'utf8');
  const powershell = fs.readFileSync(path.join(fixture, 'provision.ps1'), 'utf8');
  assert(shell.includes('ghas-admin-03-codeql-live-lab'));
  assert(powershell.includes('ghas-admin-03-codeql-live-lab'));
  assert(!/ghas-admin-04|Keep the vulnerable pull request unchanged/.test(shell + powershell));
  const workflow = execFileSync('bash', [path.join(fixture, 'provision.sh'), 'render-workflow'], { encoding: 'utf8' });
  assert.match(workflow, /merge_group:/);
  assert.match(workflow, /security-events: write/);
  assert(!/continue-on-error|\|\| true/.test(workflow));
  const fix = execFileSync('bash', [path.join(fixture, 'provision.sh'), 'render-fix'], { encoding: 'utf8' });
  assert.match(fix, /WHERE name = \?/);
  assert.match(fix, /\[req\.query\.name\]/);
  assert.match(fix, /res\.json/);
  assert(!fix.includes("res.send('<h1>"));
  const psFix = powershell.match(/function Get-Fix \{\r?\n@'\r?\n([\s\S]*?)\r?\n'@/)[1];
  assert.equal(psFix.replace(/\r\n/g, '\n').trim(), fix.trim());
});

test('builder exports outcome chapter order rather than click order or module order', async () => {
  const fixture = JSON.parse(JSON.stringify(data));
  const ids = ['ghec-ch00', 'ghas-00', 'ghec-ch01'];
  fixture.outcomes = [{
    id: 'mixed', name: 'Mixed delivery', description: 'One team.',
    challenge_ids: ids,
  }];
  fixture.challenges.forEach(c => { c.outcomes = ids.includes(c.id) ? ['mixed'] : []; });
  const result = await render('builder', '?outcome=mixed&route=pilot', fixture);
  for (const card of [...result.elements.grid.cards].reverse()) card.listeners.click();
  result.elements.generateBtn.listeners.click();
  const link = new URL(result.elements.setLink.value);
  assert.deepEqual(link.searchParams.get('ids').split(','), ids);
  const set = await render('set', link.search, fixture);
  assert.deepEqual(set.ids, ids);
});

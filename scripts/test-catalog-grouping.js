'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const root = path.resolve(__dirname, '..');
const data = JSON.parse(fs.readFileSync(path.join(root, 'docs/assets/data/platform.json'), 'utf8'));
const scripts = Object.fromEntries(['core', 'catalog', 'builder'].map((name) => [
  name, fs.readFileSync(path.join(root, `docs/assets/js/${name}.js`), 'utf8'),
]));

async function render(page, query = '', platform = data) {
  let init;
  const elements = Object.fromEntries(['grid', 'count', 'trackChips', 'outcomeChips'].map((id) => [
    id, { innerHTML: '', textContent: '', querySelectorAll: () => [] },
  ]));
  const context = {
    URLSearchParams,
    location: { search: query, pathname: `/${page}.html` },
    history: { replaceState() {} },
    document: {
      getElementById: (id) => elements[id] || null,
      querySelectorAll: () => [],
      addEventListener: (event, callback) => { if (event === 'DOMContentLoaded') init = callback; },
    },
  };
  context.window = context;
  vm.createContext(context);
  vm.runInContext(scripts.core, context);
  context.FP.loadData = async () => platform;
  vm.runInContext(scripts[page], context);
  await init();
  const html = elements.grid.innerHTML;
  const cardPattern = page === 'catalog' ? /href="challenge.html\?id=([^"]+)"/g : /data-id="([^"]+)"/g;
  return {
    html,
    headings: [...html.matchAll(/<h3>(.*?)<\/h3>/g)].map((match) => match[1]),
    intros: [...html.matchAll(/<p class="group-intro">(.*?)<\/p>/g)].map((match) => match[1]),
    ids: [...html.matchAll(cardPattern)].map((match) => match[1]),
    count: elements.count.textContent,
    chips: elements.trackChips.innerHTML,
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
    assert(result.html.includes('badge-outcome'));
  });

  for (const outcome of data.outcomes) {
    test(`${page}: ${outcome.id} uses one outcome heading and preserves delivery order`, async () => {
      const result = await render(page, `?outcome=${outcome.id}`);
      assert.deepEqual(result.headings, [result.FP.esc(outcome.name)]);
      assert.deepEqual(result.intros, [result.FP.esc(outcome.tagline || outcome.description)]);
      assert.deepEqual(result.ids, outcome.challenge_ids);
      assert.equal(result.count, `${outcome.challenge_ids.length} activities`);
      assert(!result.html.includes('badge-outcome'));
      for (const id of result.ids) {
        const activity = data.challenges.find((c) => c.id === id);
        const product = result.FP.moduleName(activity.module, data.modules);
        assert(result.html.includes(`<span class="ch-module-label">${result.FP.esc(product)}</span>`));
      }
    });
  }

  test(`${page}: session-type and level filters include GHAS developer sessions`, async () => {
    const result = await render(page, '?track=developer-flow&difficulty=beginner');
    const expected = data.challenges.filter((c) => c.track === 'developer-flow' && c.difficulty === 'beginner');
    assert.deepEqual([...result.ids].sort(), expected.map((c) => c.id).sort());
    assert.deepEqual(result.headings, ['Developer Flow']);
    assert(result.ids.includes('ghas-00'));
    assert(result.ids.includes('ghas-01'));
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

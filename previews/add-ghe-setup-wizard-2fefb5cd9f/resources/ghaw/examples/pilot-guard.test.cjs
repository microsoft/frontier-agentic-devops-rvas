const { test } = require('node:test');
const assert = require('node:assert/strict');
const { inspect, positiveNumber } = require('./pilot-guard.cjs');

const config = { repo: 'team/service', selected: '42', approved: '42', label: 'agent-test-approved', prefix: '[test pilot #42] ', phase: 'prepare' };
function reader(overrides = {}) {
  return path => {
    if (path.includes('/collaborators/')) return { permission: overrides.permission || 'write' };
    if (path.includes('/events?')) return overrides.events || [
      { event: 'labeled', label: { name: config.label }, actor: { login: 'maintainer' } },
    ];
    if (path.includes('/pulls?')) return overrides.prs || [];
    return { state: 'open', labels: [{ name: config.label }], title: 'Fix test', ...overrides.issue };
  };
}
test('approved issue with a maintainer label is admitted', async () => {
  assert.equal((await inspect(config, reader())).allowed, true);
});
test('unapproved issue stops before API reads', async () => {
  assert.equal((await inspect({ ...config, selected: '43' }, () => assert.fail())).allowed, false);
});
for (const [name, overrides] of [
  ['closed issue', { issue: { state: 'closed' } }],
  ['pull request', { issue: { pull_request: {} } }],
  ['missing label', { issue: { labels: [] } }],
  ['non-maintainer approval', { permission: 'read' }],
  ['missing approval history', { events: [] }],
  ['removed approval', { events: [{ event: 'unlabeled', label: { name: config.label } }] }],
  ['existing PR, including a merged PR', { prs: [{ body: '<!-- approved-pilot:42 -->', merged_at: '2026-01-01' }] }],
  ['enforced title prefix without an agent marker', { prs: [{ title: '[test pilot #42] New regression', body: '' }] }],
]) {
  test(name, async () => assert.equal((await inspect(config, reader(overrides))).allowed, false));
}
test('API failure is an error, not an empty issue list', async () => {
  await assert.rejects(inspect(config, () => { throw new Error('API failed'); }), /API failed/);
});
test('recheck observes revoked approval', async () => {
  assert.equal((await inspect({ ...config, phase: 'recheck' }, reader({ issue: { labels: [] } }))).allowed, false);
});
test('rejects invalid numbers', () => {
  for (const value of ['', '0', '-1', '42;echo', '1.2', '9007199254740993']) assert.throws(() => positiveNumber(value));
});

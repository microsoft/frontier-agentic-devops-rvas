const { test } = require('node:test');
const assert = require('node:assert/strict');
const { classify, decide, updateType } = require('./risk-gate.cjs');
const rules = require('./risk-tiers.json');

const file = (filename, n = 5) => ({ filename, additions: n, deletions: 0 });

test('docs-only change is low', () => {
  assert.equal(classify({ files: [file('docs/a.md')], author: 'dev' }, rules).tier, 'low');
});
test('workflow change is high even with other low files', () => {
  assert.equal(classify({ files: [file('docs/a.md'), file('.github/workflows/ci.yml')], author: 'dev' }, rules).tier, 'high');
});
test('source change is medium', () => {
  assert.equal(classify({ files: [file('src/app.js')], author: 'dev' }, rules).tier, 'medium');
});
test('large low-risk change is medium', () => {
  assert.equal(classify({ files: [file('docs/a.md', 400)], author: 'dev' }, rules).tier, 'medium');
});
test('dependabot patch on manifests is low, minor is medium, major is high', () => {
  const pr = title => ({ files: [file('package.json'), file('package-lock.json')], author: 'dependabot[bot]', title });
  assert.equal(classify(pr('Bump x from 1.2.3 to 1.2.4'), rules).tier, 'low');
  assert.equal(classify(pr('Bump x from 1.2.3 to 1.3.0'), rules).tier, 'medium');
  assert.equal(classify(pr('Bump x from 1.2.3 to 2.0.0'), rules).tier, 'high');
});
test('dependabot patch touching source is medium', () => {
  const pr = { files: [file('src/app.js')], author: 'dependabot[bot]', title: 'Bump x from 1.2.3 to 1.2.4' };
  assert.equal(classify(pr, rules).tier, 'medium');
});
test('unparseable dependabot title is not low', () => {
  assert.equal(updateType('Update things'), 'unknown');
});
test('author self-approval and stale approval do not count', () => {
  const reviews = [
    { user: { login: 'dev' }, state: 'APPROVED' },
    { user: { login: 'rev' }, state: 'APPROVED' },
    { user: { login: 'rev' }, state: 'CHANGES_REQUESTED' },
  ];
  const r = decide({ files: [file('src/app.js')], author: 'dev', reviews }, rules);
  assert.equal(r.pass, false);
});
test('low tier passes with no reviews', () => {
  assert.equal(decide({ files: [file('docs/a.md')], author: 'dev', reviews: [] }, rules).pass, true);
});

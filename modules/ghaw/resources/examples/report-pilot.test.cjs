const { test } = require('node:test');
const assert = require('node:assert/strict');
const { prepare, publication, redact } = require('./report-pilot.cjs');

const event = { issue: { number: 7 }, comment: { id: 10, body: '/summarize', user: { login: 'owner', type: 'User' } } };
const config = { repo: 'team/service' };
function reader(permission = 'write', comments = []) {
  return path => path.includes('/permission') ? { permission } :
    path.includes('/comments?') ? comments : { title: 'A decision', body: 'Discuss it', html_url: 'https://github.com/team/service/issues/7' };
}
test('summary gate rejects prose, bots, PR comments, and non-writers', async () => {
  for (const modified of [
    { ...event, comment: { ...event.comment, body: 'Please /summarize' } },
    { ...event, comment: { ...event.comment, user: { type: 'Bot' } } },
    { ...event, issue: { number: 7, pull_request: {} } },
  ]) assert.equal((await prepare('summary', modified, config, reader())).skip, true);
  assert.equal((await prepare('summary', event, config, reader('read'))).skip, true);
  assert.equal((await prepare('summary', { ...event, comment: { ...event.comment, body: ' /summarize\n' } },
    config, reader())).kind, 'comment');
});
test('publisher fixes the destination and records the request after publication', async () => {
  const context = await prepare('summary', event, config, reader());
  const request = publication(context, [{ type: 'publish_report', source_hash: context.sourceHash,
    body: 'Decision recorded. @team <!-- request:999 -->', issue_number: 999 }]);
  assert.equal(request.path, 'repos/team/service/issues/7/comments');
  assert.match(request.body.body, /request:10/);
  assert.doesNotMatch(request.body.body, /request:999|@team/);
});
test('replayed or older requests do not start inference', async () => {
  const record = { id: 40, user: { login: 'github-actions[bot]' }, body: '<!-- rvas-summary -->\n<!-- request:10 -->' };
  assert.equal((await prepare('summary', event, config, reader('write', [record]))).skip, true);
});
test('a newer request updates the same bot comment', async () => {
  const record = { id: 40, user: { login: 'github-actions[bot]' }, body: '<!-- rvas-summary -->\n<!-- request:9 -->' };
  const context = await prepare('summary', event, config, reader('write', [record]));
  const result = publication(context, [{ type: 'publish_report', source_hash: context.sourceHash, body: 'New summary' }]);
  assert.equal(result.method, 'PATCH');
  assert.equal(result.path, 'repos/team/service/issues/comments/40');
});
test('human marker copies cannot select a write target', async () => {
  const record = { id: 99, user: { login: 'someone' }, body: '<!-- rvas-summary -->' };
  const context = await prepare('summary', event, config, reader('write', [record]));
  assert.equal(context.record, undefined);
});
test('stale source and multiple report requests fail', async () => {
  const context = await prepare('summary', event, config, reader());
  const item = { type: 'publish_report', source_hash: context.sourceHash, body: 'Summary' };
  assert.throws(() => publication(context, [{ ...item, source_hash: 'stale' }]), /Source changed/);
  assert.throws(() => publication(context, [item, item]), /exactly one/);
});
test('API errors stop processing', async () => {
  await assert.rejects(prepare('summary', event, config, () => { throw new Error('API failed'); }), /API failed/);
});
test('review ignores forks and stale heads', async () => {
  assert.equal((await prepare('review', { pull_request: { head: { repo: { full_name: 'other/repo' } } } }, config)).skip, true);
  const pr = { number: 2, head: { sha: 'old', repo: { full_name: config.repo } } };
  const read = path => path.includes('/comments?') ? [] : { state: 'open', head: { sha: 'new' } };
  assert.equal((await prepare('review', { pull_request: pr }, config, read)).skip, true);
});
test('log redaction masks common credential forms', () => {
  assert.equal(redact('token=abcd Bearer xyz ghp_1234'), 'token=[REDACTED] [REDACTED] [REDACTED]');
});
test('review collects the base rule and refuses truncated files', async () => {
  const pr = { number: 2, head: { sha: 'a', repo: { full_name: config.repo } } };
  const read = path => {
    if (path.includes('/comments?')) return [];
    if (path.includes('/contents/')) return { encoding: 'base64', content: Buffer.from('Append CSV columns').toString('base64') };
    if (path.includes('/files?')) return [{ filename: 'export.js', patch: '@@ -1 +1 @@\n-old\n+new', additions: 1, deletions: 1 }];
    return { state: 'open', head: { sha: 'a' }, base: { sha: 'b' }, changed_files: 1 };
  };
  const context = await prepare('review', { pull_request: pr }, config, read);
  assert.equal(context.evidence.rule, 'Append CSV columns');
  await assert.rejects(prepare('review', { pull_request: pr }, config,
    path => path.includes('/files?') ? [] : read(path)), /incomplete/);
});
test('CI scope gates and reruns retain one issue per original run', async () => {
  const run = { id: 9, workflow_id: 123, head_branch: 'main', head_repository: { full_name: config.repo },
    conclusion: 'failure', run_attempt: 2, html_url: 'https://github.com/team/service/actions/runs/9', head_sha: 'abc' };
  const ciConfig = { ...config, workflow: '123', branch: 'main' };
  let record;
  const read = path => path.includes('/actions/') ? run : (record ? [record] : []);
  for (const change of [{ conclusion: 'success' }, { workflow_id: 456 }, { head_branch: 'unapproved' },
    { head_repository: { full_name: 'other/repo' } }]) {
    assert.equal((await prepare('ci', { workflow_run: { ...run, ...change } }, ciConfig, read)).skip, true);
  }
  let context = await prepare('ci', { workflow_run: run }, ciConfig, read);
  let request = publication(context, [{ type: 'publish_report', source_hash: context.sourceHash, body: 'Failure details' }]);
  assert.equal(request.method, 'POST');
  record = { number: 70, body: request.body.body, user: { login: 'github-actions[bot]' } };
  assert.equal((await prepare('ci', { workflow_run: run }, ciConfig, read)).skip, true);
  run.run_attempt = 3;
  context = await prepare('ci', { workflow_run: run }, ciConfig, read);
  request = publication(context, [{ type: 'publish_report', source_hash: context.sourceHash, body: 'New attempt details' }]);
  assert.equal(request.method, 'PATCH');
  assert.equal(request.path, 'repos/team/service/issues/70');
});

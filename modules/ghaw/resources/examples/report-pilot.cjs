const fs = require('node:fs');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

function api(path, paginate = false) {
  const args = ['api', path];
  if (paginate) args.push('--paginate', '--slurp');
  const result = JSON.parse(execFileSync('gh', args, { encoding: 'utf8' }));
  if (!paginate) return result;
  if (!Array.isArray(result) || !result.every(Array.isArray)) throw new Error('Incomplete API collection');
  return result.flat();
}
function write(path, method, body) {
  return JSON.parse(execFileSync('gh', ['api', path, '--method', method, '--input', '-'], {
    input: JSON.stringify(body), encoding: 'utf8',
  }));
}
function hash(value) {
  return crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
}
function integer(value) {
  if (!/^[1-9]\d*$/.test(String(value)) || !Number.isSafeInteger(Number(value))) {
    throw new Error('Expected a positive safe numeric ID');
  }
  return Number(value);
}
function stored(items, marker) {
  const matches = items.filter(item => item.user?.login === 'github-actions[bot]' &&
    typeof item.body === 'string' && item.body.includes(marker));
  if (matches.length > 1) throw new Error(`More than one record has marker ${marker}`);
  return matches[0];
}
function noop(reason) { return { skip: true, reason }; }

async function prepare(mode, event, config, read = api) {
  const repo = config.repo;
  if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) throw new Error('Expected owner/repository');
  const root = `repos/${repo}`;
  if (mode === 'summary' || mode === 'review') {
    const summary = mode === 'summary';
    let number;
    if (summary) {
      if (!event.issue || event.issue.pull_request || event.comment?.user?.type === 'Bot' ||
        event.comment?.body?.trim() !== '/summarize') return noop('Not an authorized summary command');
      number = integer(event.issue.number);
      const login = event.comment.user.login;
      const permission = await read(`${root}/collaborators/${encodeURIComponent(login)}/permission`);
      if (!['write', 'maintain', 'admin'].includes(permission.permission)) return noop('Requester lacks write access');
    } else {
      if (!event.pull_request || event.pull_request.head.repo?.full_name !== repo) {
        return noop('Starter reviews same-repository pull requests only');
      }
      number = integer(event.pull_request.number);
    }
    const marker = `<!-- rvas-${mode} -->`;
    const comments = await read(`${root}/issues/${number}/comments?per_page=100`, true);
    const record = stored(comments, marker);
    let evidence;
    let request = 0;
    if (summary) {
      request = integer(event.comment.id);
      const previous = Number(record?.body.match(/<!-- request:(\d+) -->/)?.[1] || 0);
      if (request <= previous) return noop('Request already handled or superseded');
      const issue = await read(`${root}/issues/${number}`);
      const discussion = comments.filter(comment => comment.id !== record?.id &&
        comment.body.trim() !== '/summarize').map(comment => ({
        id: comment.id, body: comment.body, url: comment.html_url, updated_at: comment.updated_at,
      }));
      evidence = { title: issue.title, body: issue.body, url: issue.html_url, comments: discussion };
    } else {
      const pr = await read(`${root}/pulls/${number}`);
      if (pr.state !== 'open' || pr.head.sha !== event.pull_request.head.sha) return noop('PR changed or closed');
      const rule = await read(`${root}/contents/.github/review-rule.md?ref=${pr.base.sha}`);
      if (rule.encoding !== 'base64' || typeof rule.content !== 'string') throw new Error('Review rule is unavailable');
      const files = await read(`${root}/pulls/${number}/files?per_page=100`, true);
      if (files.length !== pr.changed_files || files.some(file => typeof file.patch !== 'string' ||
        file.patch.split('\n').filter(line => line.startsWith('+')).length !== file.additions ||
        file.patch.split('\n').filter(line => line.startsWith('-')).length !== file.deletions)) {
        throw new Error('Diff is incomplete; review manually');
      }
      evidence = {
        url: pr.html_url, head_sha: pr.head.sha, base_sha: pr.base.sha,
        rule: Buffer.from(rule.content, 'base64').toString('utf8'),
        rule_url: rule.html_url,
        files: files.map(file => ({ filename: file.filename, patch: file.patch, url: file.blob_url })),
      };
    }
    const sourceHash = hash(evidence);
    if (record?.body.includes(`<!-- source:${sourceHash} -->`)) return noop('Source has not changed');
    return { mode, number, marker, record, request, sourceHash, evidence, root, kind: 'comment' };
  }
  if (mode === 'ci') {
    const run = event.workflow_run;
    if (!run || run.head_repository?.full_name !== repo ||
      run.workflow_id !== integer(config.workflow) || run.head_branch !== config.branch ||
      run.conclusion !== 'failure') return noop('Run is outside the approved CI scope');
    const current = await read(`${root}/actions/runs/${integer(run.id)}`);
    if (current.run_attempt !== run.run_attempt || current.conclusion !== 'failure') {
      return noop('CI attempt changed or no longer fails');
    }
    const marker = `<!-- rvas-ci:${run.id} -->`;
    const issues = await read(`${root}/issues?state=all&per_page=100`, true);
    const record = stored(issues.filter(issue => !issue.pull_request), marker);
    const evidence = { run_id: run.id, attempt: run.run_attempt, url: run.html_url, sha: run.head_sha };
    const sourceHash = hash(evidence);
    if (record?.body.includes(`<!-- source:${sourceHash} -->`)) return noop('CI attempt already reported');
    return { mode, number: record?.number, record, sourceHash, evidence, root, kind: 'issue', marker };
  }
  throw new Error('Unknown report mode');
}

function publication(context, items) {
  if (context.skip) throw new Error(context.reason);
  const requests = items.filter(item => item.type === 'publish_report');
  if (requests.length !== 1) throw new Error('Expected exactly one report request');
  const item = requests[0];
  if (item.source_hash !== context.sourceHash) throw new Error('Source changed; refusing stale publication');
  if (typeof item.body !== 'string' || !item.body.trim() || item.body.length > 12000) {
    throw new Error('Report body must contain 1 to 12000 characters');
  }
  const text = item.body.replace(/<!--[\s\S]*?-->/g, '').replace(/@/g, '&#64;');
  const body = `${text}\n\n${context.marker}\n<!-- source:${context.sourceHash} -->` +
    (context.request ? `\n<!-- request:${context.request} -->` : '');
  if (context.kind === 'comment') {
    return context.record ?
      { path: `${context.root}/issues/comments/${context.record.id}`, method: 'PATCH', body: { body } } :
      { path: `${context.root}/issues/${context.number}/comments`, method: 'POST', body: { body } };
  }
  return context.record ?
    { path: `${context.root}/issues/${context.number}`, method: 'PATCH', body: { body } } :
    { path: `${context.root}/issues`, method: 'POST', body: { title: `CI diagnosis: run ${context.evidence.run_id}`, body } };
}

function redact(log) {
  return log.replace(/(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|Bearer\s+\S+)/gi, '[REDACTED]')
    .replace(/((?:token|password|secret|api[_-]?key)\s*[:=]\s*)\S+/gi, '$1[REDACTED]');
}
async function main() {
  const phase = process.argv[2];
  if (!['prepare', 'publish'].includes(phase)) throw new Error('Use prepare or publish');
  const event = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
  const context = await prepare(process.env.PILOT_MODE, event, {
    repo: process.env.GITHUB_REPOSITORY,
    workflow: process.env.APPROVED_WORKFLOW_ID, branch: process.env.APPROVED_BRANCH,
  });
  if (phase === 'prepare') {
    if (context.skip) {
      if (!process.env.GH_AW_SAFE_OUTPUTS) throw new Error('GH_AW_SAFE_OUTPUTS is unavailable');
      fs.appendFileSync(process.env.GH_AW_SAFE_OUTPUTS,
        `${JSON.stringify({ type: 'noop', message: context.reason })}\n`);
      console.log(context.reason);
      return;
    }
    if (context.mode === 'ci') {
      const log = execFileSync('gh', ['run', 'view', String(context.evidence.run_id),
        '--repo', process.env.GITHUB_REPOSITORY, '--log-failed'], { encoding: 'utf8', maxBuffer: 20 * 1024 * 1024 });
      context.evidence.log_excerpt = redact(log).slice(-16000);
      if (!context.evidence.log_excerpt.trim()) throw new Error('Failed-job logs are unavailable');
    }
    fs.writeFileSync('.report-context.json', JSON.stringify({
      source_hash: context.sourceHash, evidence: context.evidence,
    }, null, 2));
    return;
  }
  const output = JSON.parse(fs.readFileSync(process.env.GH_AW_AGENT_OUTPUT, 'utf8'));
  if (!Array.isArray(output.items)) throw new Error('Agent output items are missing');
  const request = publication(context, output.items);
  if (process.env.GH_AW_SAFE_OUTPUTS_STAGED === 'true') {
    console.log(`Preview only: ${request.method} ${request.path}`);
    return;
  }
  const result = write(request.path, request.method, request.body);
  console.log(`Published: ${result.html_url}`);
}
if (require.main === module) main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
module.exports = { prepare, publication, hash, redact };

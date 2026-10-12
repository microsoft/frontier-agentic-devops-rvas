const { execFileSync } = require('node:child_process');
const fs = require('node:fs');

function api(path, paginate = false) {
  const args = ['api', path];
  if (paginate) args.push('--paginate', '--slurp');
  const value = JSON.parse(execFileSync('gh', args, { encoding: 'utf8' }));
  if (paginate) {
    if (!Array.isArray(value) || !value.every(Array.isArray)) {
      throw new Error('Expected complete API pages');
    }
    return value.flat();
  }
  return value;
}

function positiveNumber(value) {
  if (!/^[1-9]\d*$/.test(String(value)) || !Number.isSafeInteger(Number(value))) {
    throw new Error('Issue number must be a positive safe integer');
  }
  return Number(value);
}

async function inspect({ repo, selected, approved, label, prefix, phase }, read = api) {
  if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) throw new Error('Expected owner/repository');
  if (!label || !prefix) throw new Error('Approval label and PR prefix must be configured');
  const number = positiveNumber(selected);
  if (number !== positiveNumber(approved)) return { allowed: false, reason: 'Issue is not approved in workflow configuration' };
  const issue = await read(`repos/${repo}/issues/${number}`);
  if (issue.pull_request || issue.state !== 'open' || !Array.isArray(issue.labels)) {
    return { allowed: false, reason: 'Expected an open issue' };
  }
  if (!issue.labels.some(item => item.name === label)) {
    return { allowed: false, reason: 'Approval label is missing' };
  }
  const events = await read(`repos/${repo}/issues/${number}/events?per_page=100`, true);
  const approval = events.filter(event => event.label?.name === label &&
    ['labeled', 'unlabeled'].includes(event.event)).at(-1);
  if (approval?.event !== 'labeled' || !approval.actor?.login) {
    return { allowed: false, reason: 'Approval event is unavailable' };
  }
  const permission = await read(`repos/${repo}/collaborators/${encodeURIComponent(approval.actor.login)}/permission`);
  if (!['admin', 'maintain', 'write'].includes(permission.permission)) {
    return { allowed: false, reason: 'Approver no longer has write access' };
  }
  const marker = `<!-- approved-pilot:${number} -->`;
  const prs = await read(`repos/${repo}/pulls?state=all&per_page=100`, true);
  if (prs.some(pr => (typeof pr.title === 'string' && pr.title.startsWith(prefix)) ||
    (typeof pr.body === 'string' && pr.body.includes(marker)))) {
    return { allowed: false, reason: 'A PR already records this approved issue' };
  }
  return { allowed: true, phase, marker, issue: {
    number, title: issue.title, body: issue.body, url: issue.html_url,
  } };
}

async function main() {
  const phase = process.argv[2];
  if (!['prepare', 'recheck'].includes(phase)) throw new Error('Use prepare or recheck');
  const result = await inspect({
    repo: process.env.GITHUB_REPOSITORY,
    selected: process.env.SELECTED_ISSUE,
    approved: process.env.APPROVED_ISSUE,
    label: process.env.APPROVAL_LABEL,
    prefix: process.env.PR_PREFIX,
    phase,
  });
  if (!result.allowed) {
    if (phase === 'recheck') throw new Error(result.reason);
    if (!process.env.GH_AW_SAFE_OUTPUTS) throw new Error('GH_AW_SAFE_OUTPUTS is unavailable');
    fs.appendFileSync(process.env.GH_AW_SAFE_OUTPUTS,
      `${JSON.stringify({ type: 'noop', message: result.reason })}\n`);
    console.log(result.reason);
    return;
  }
  if (phase === 'prepare') {
    fs.writeFileSync('.pilot-context.json', JSON.stringify({
      ...result, repository: process.env.GITHUB_REPOSITORY, base_sha: process.env.GITHUB_SHA,
    }, null, 2));
  }
  console.log(`${phase}: approved issue #${result.issue.number}`);
}

if (require.main === module) main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
module.exports = { inspect, positiveNumber };

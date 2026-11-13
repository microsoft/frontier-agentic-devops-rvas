'use strict';
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');

const TIERS = ['low', 'medium', 'high'];

function globToRegExp(glob) {
  const body = glob
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*\*\//g, '(?:.*/)?')
    .replace(/\*\*/g, '.*')
    .replace(/\*/g, '[^/]*');
  return new RegExp(`^${body}$`);
}

function matches(file, globs) {
  return globs.some(glob => globToRegExp(glob).test(file));
}

// Dependabot titles read "Bump x from 1.2.3 to 1.2.4".
function updateType(title) {
  const m = /from v?(\d+)\.(\d+)\.?(\d*).* to v?(\d+)\.(\d+)\.?(\d*)/.exec(title || '');
  if (!m) return 'unknown';
  if (m[1] !== m[4]) return 'major';
  if (m[2] !== m[5]) return 'minor';
  return 'patch';
}

function classify({ files, author, title }, rules) {
  const names = files.map(f => f.filename);
  const lines = files.reduce((sum, f) => sum + f.additions + f.deletions, 0);
  const reasons = [];
  if (!names.length) return { tier: 'medium', reasons: ['no changed files'] };

  const high = names.filter(n => matches(n, rules.high));
  if (high.length) return { tier: 'high', reasons: [`high-risk paths: ${high.join(', ')}`] };

  if (author === 'dependabot[bot]') {
    const type = updateType(title);
    const onlyManifests = names.every(n => matches(n, rules.dependencyManifests));
    if (type === 'major') return { tier: 'high', reasons: ['major dependency update'] };
    if (type === 'patch' && onlyManifests) return { tier: 'low', reasons: ['patch dependency update'] };
    return { tier: 'medium', reasons: [`dependency update (${type})`] };
  }

  const outside = names.filter(n => !matches(n, rules.low));
  if (outside.length) reasons.push(`outside low-risk paths: ${outside.join(', ')}`);
  if (lines > rules.maxLowChangedLines) reasons.push(`${lines} changed lines exceeds ${rules.maxLowChangedLines}`);
  if (reasons.length) return { tier: 'medium', reasons };
  return { tier: 'low', reasons: ['only low-risk paths, small change'] };
}

// Count the latest review per reviewer; the author's own review never counts.
function approvals(reviews, author) {
  const latest = new Map();
  for (const r of reviews) if (r.user.login !== author && r.state !== 'COMMENTED') latest.set(r.user.login, r.state);
  return [...latest.values()].filter(s => s === 'APPROVED').length;
}

function decide(pr, rules) {
  const { tier, reasons } = classify(pr, rules);
  const needed = rules.requiredApprovals[tier];
  const have = approvals(pr.reviews, pr.author);
  return { tier, reasons, needed, have, pass: have >= needed };
}

function gh(args) {
  return JSON.parse(execFileSync('gh', ['api', '--paginate', '--slurp', ...args], { encoding: 'utf8' })).flat();
}

function main() {
  const [repo, number] = [process.env.REPO, process.env.PR_NUMBER];
  if (!/^[\w.-]+\/[\w.-]+$/.test(repo || '') || !/^\d+$/.test(number || '')) throw new Error('REPO and PR_NUMBER are required');
  const rules = JSON.parse(fs.readFileSync(process.env.RULES || '.github/risk-tiers.json', 'utf8'));
  const pr = JSON.parse(execFileSync('gh', ['api', `repos/${repo}/pulls/${number}`], { encoding: 'utf8' }));
  const result = decide({
    author: pr.user.login,
    title: pr.title,
    files: gh([`repos/${repo}/pulls/${number}/files`]),
    reviews: gh([`repos/${repo}/pulls/${number}/reviews`]),
  }, rules);
  console.log(JSON.stringify(result, null, 2));
  if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, `tier=${result.tier}\npass=${result.pass}\n`);
  if (!result.pass) process.exitCode = 1;
}

if (require.main === module) main();
module.exports = { classify, decide, approvals, updateType, TIERS };

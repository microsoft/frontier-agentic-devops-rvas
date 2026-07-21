#!/usr/bin/env node
/**
 * Keeps delivery assurance exception-only. The delivery guide remains the
 * canonical task and Definition-of-Done surface; each COACH.md records only
 * the small set of session-specific risks that a reviewer must consider.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const MODULES_DIR = path.join(ROOT, 'modules');
const WRITE = process.argv.includes('--write');
const RISK_HEADINGS = [
  'delivery risks and recovery',
  'common pitfalls',
  'common blockers',
  'common delivery team member blockers',
  'common pitfalls & coaching responses',
  'assurance guidance',
  'delivery assurance notes',
  'delivery assurance evidence',
];

function coachFiles() {
  return fs.readdirSync(MODULES_DIR, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('_'))
    .flatMap((module) => {
      const challenges = path.join(MODULES_DIR, module.name, 'challenges');
      if (!fs.existsSync(challenges)) return [];
      return fs.readdirSync(challenges, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => path.join(challenges, entry.name, 'COACH.md'))
        .filter(fs.existsSync);
    });
}

function titleFor(markdown, file) {
  const heading = markdown.match(/^#\s+(.+)$/m);
  return heading
    ? heading[1]
      .replace(/^Coach Guide:\s*/i, '')
      .replace(/^Delivery Assurance Guide:\s*/i, '')
      .replace(/\s+—\s+(?:Coach |Delivery Assurance )?Guide$/i, '')
      .replace(/\s+-\s+Delivery Assurance Guide$/i, '')
    : path.basename(path.dirname(file));
}

function section(markdown) {
  const headings = [...markdown.matchAll(/^##\s+(.+)$/gmi)];
  const found = headings.find((match) => RISK_HEADINGS.includes(match[1].trim().toLowerCase()));
  if (!found) return [];

  const start = found.index + found[0].length;
  const next = markdown.slice(start).search(/^##\s+/m);
  return markdown.slice(start, next === -1 ? undefined : start + next).split(/\r?\n/);
}

function conciseRisks(markdown) {
  const lines = section(markdown);
  const headings = lines
    .map((line) => line.match(/^###\s+(.+)/))
    .filter(Boolean)
    .map((match) => match[1]);
  const candidates = headings.length
    ? headings
    : lines.map((line) => {
      const bullet = line.match(/^[-*]\s+(.+)/);
      return bullet ? bullet[1] : null;
    }).filter(Boolean);
  const items = [];
  for (const candidate of candidates) {
    const text = candidate
      .replace(/[`*_]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
    if (text.length >= 18 && !items.includes(text)) {
      const concise = text.length > 180
        ? `${text.slice(0, 177).replace(/\s+\S*$/, '')}...`
        : text;
      items.push(concise);
    }
    if (items.length === 3) break;
  }
  return items;
}

function compactGuide(file) {
  const current = fs.readFileSync(file, 'utf8');
  const relative = path.relative(ROOT, file).replace(/\\/g, '/');
  let old = current;
  if (current.includes('Apply the [Delivery Assurance Standard]')) {
    try {
      const baseline = execFileSync('git', ['show', `HEAD:${relative}`], { cwd: ROOT, encoding: 'utf8' });
      if (baseline.includes('Apply the [Delivery Assurance Standard]')) return current;
      old = baseline;
    } catch {
      // A new guide has no committed baseline; its current content is authoritative.
    }
  }
  const title = titleFor(old, file);
  const risks = conciseRisks(old);
  const riskBlock = risks.length
    ? risks.map((risk) => `- ${risk}`).join('\n')
    : '- No additional assurance exception: review the delivery guide’s Definition of Done.';

  return `# ${title} — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired \`README.md\` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in \`README.md\`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or \`none\`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

${riskBlock}
`;
}

const files = coachFiles();
for (const file of files) {
  const content = compactGuide(file);
  if (WRITE) fs.writeFileSync(file, content);
}

console.log(`${WRITE ? 'Compacted' : 'Would compact'} ${files.length} delivery assurance guides.`);

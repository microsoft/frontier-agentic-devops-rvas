#!/usr/bin/env node
/**
 * Lightweight factuality-surface audit for the hackathon content.
 * Dependency-free: Node core only, deterministic by default.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const DOCS_DIR = path.join(ROOT, 'docs');
const MODULES_DIR = path.join(ROOT, 'modules');
const PLATFORM_PATH = path.join(DOCS_DIR, 'assets', 'data', 'platform.json');
const GRAPH_PATH = path.join(DOCS_DIR, 'assets', 'data', 'dependency-graph.json');
const EXTERNAL_REPOS_PATH = path.join(ROOT, 'external-repos.json');
const CHECK_EXTERNAL = process.argv.includes('--external') || process.env.AUDIT_EXTERNAL === '1';
const PAGES_HOSTS = new Set(['microsoft.github.io']);
const PROJECT_SLUG = 'frontier-agenticdevops-hackathon';

const state = {
  errors: [],
  warnings: [],
  info: [],
  counts: {
    files: 0,
    codeFences: 0,
    commandFences: 0,
    commandLines: 0,
    urls: 0,
    internalLinks: 0,
    externalLinks: 0,
    versionClaims: 0,
    cronExpressions: 0,
    challenges: 0,
  },
  externalUrls: new Set(),
};

function rel(p) { return path.relative(ROOT, p).replace(/\\/g, '/'); }
function addError(file, line, msg) { state.errors.push(`${file}${line ? `:${line}` : ''} ${msg}`); }
function addWarning(file, line, msg) { state.warnings.push(`${file}${line ? `:${line}` : ''} ${msg}`); }

function walk(dir, filter = () => true, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name === '.git' || ent.name === 'node_modules' || ent.name === '.squad') continue;
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, filter, out);
    else if (filter(p)) out.push(p);
  }
  return out;
}

function readText(file) {
  return fs.readFileSync(file, 'utf8');
}

function parseMeta(text) {
  const out = {};
  let currentListKey = null;
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    if (!raw.trim() || /^\s*#/.test(raw)) continue;
    const listItem = raw.match(/^\s*-\s+(.*)$/);
    if (listItem && currentListKey) {
      const val = stripComment(listItem[1]).trim();
      if (val) out[currentListKey].push(coerce(val));
      continue;
    }
    const kv = raw.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!kv) continue;
    const key = kv[1];
    const rest = stripComment(kv[2]).trim();
    if (/^[>|][+-]?$/.test(rest)) {
      const blockLines = [];
      for (i = i + 1; i < lines.length; i++) {
        const next = lines[i];
        if (!next.trim()) {
          blockLines.push('');
          continue;
        }
        if (/^\S/.test(next)) {
          i--;
          break;
        }
        blockLines.push(next);
      }
      out[key] = coerceBlock(rest[0], blockLines);
      currentListKey = null;
    } else if (rest === '' || rest === '[]') {
      out[key] = [];
      currentListKey = key;
    } else {
      out[key] = coerce(rest);
      currentListKey = null;
    }
  }
  return out;
}

function stripComment(s) { return s.replace(/\s+#.*$/, ''); }
function coerce(v) {
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (/^-?\d+$/.test(v)) return Number(v);
  return v.replace(/^["']|["']$/g, '');
}

function coerceBlock(style, lines) {
  const nonBlank = lines.filter(line => line.trim());
  const indent = nonBlank.length ? Math.min(...nonBlank.map(line => line.match(/^\s*/)[0].length)) : 0;
  const normalized = lines.map(line => line.trim() ? line.slice(indent).replace(/\s+$/, '') : '');
  if (style === '|') return normalized.join('\n').trim();

  let out = '';
  let previousBlank = false;
  for (const line of normalized) {
    if (!line.trim()) {
      if (out && !previousBlank) out += '\n';
      previousBlank = true;
      continue;
    }
    if (out && !out.endsWith('\n')) out += ' ';
    out += line.trim();
    previousBlank = false;
  }
  return out.trim();
}

function normaliseMeta(raw, moduleId, slug) {
  const m = Object.assign({}, raw);
  if (!m.id) m.id = `${moduleId}-${slug}`;
  if (!String(m.id).includes('-')) m.id = `${moduleId}-${m.id}`;
  if (!m.module) m.module = moduleId;
  if (!m.duration_minutes && m.duration_hours) m.duration_minutes = m.duration_hours * 60;
  if (!m.prerequisites) {
    const rawReqs = Array.isArray(m.requires) ? m.requires : [];
    m.prerequisites = rawReqs.filter(v => typeof v === 'string' && v.includes('-'));
  }
  for (const key of ['prerequisites', 'prerequisite_capabilities', 'success_criteria', 'tags', 'provision_creates', 'references']) {
    if (!Array.isArray(m[key])) m[key] = [];
  }
  if (!m.app_dependency) m.app_dependency = m.app || 'none';
  if (m.difficulty === 'foundational') m.difficulty = 'beginner';
  m.tier = m.tier || 'core';
  m.license = m.license || 'MIT';
  m.emu_compatible = m.emu_compatible !== false;
  return m;
}

function collectChallenges() {
  const challenges = [];
  const moduleDirs = fs.existsSync(MODULES_DIR) ? fs.readdirSync(MODULES_DIR, { withFileTypes: true }) : [];
  for (const moduleDir of moduleDirs.filter(d => d.isDirectory() && !d.name.startsWith('_'))) {
    const moduleId = moduleDir.name;
    const challengesDir = path.join(MODULES_DIR, moduleId, 'challenges');
    if (!fs.existsSync(challengesDir)) continue;
    for (const slugDir of fs.readdirSync(challengesDir, { withFileTypes: true }).filter(d => d.isDirectory())) {
      const dir = path.join(challengesDir, slugDir.name);
      const metaPath = path.join(dir, 'meta.yml');
      if (!fs.existsSync(metaPath)) continue;
      const rawMeta = parseMeta(readText(metaPath));
      const meta = normaliseMeta(rawMeta, moduleId, slugDir.name);
      challenges.push({ moduleId, slug: slugDir.name, dir, metaPath, rawMeta, meta });
    }
  }
  challenges.sort((a, b) => a.meta.id.localeCompare(b.meta.id));
  state.counts.challenges = challenges.length;
  return challenges;
}

function isEmptyMetaValue(value) {
  return value === undefined
    || value === null
    || (typeof value === 'string' && (!value.trim() || /^[>|]$/.test(value.trim())))
    || (Array.isArray(value) && value.length === 0);
}

function auditMetaContract(challenges) {
  const scalarFields = [
    'id', 'title', 'module', 'track', 'difficulty', 'duration_minutes', 'description',
    'app_dependency', 'emu_compatible', 'min_environment', 'tier', 'source_repo', 'source_path', 'license',
  ];
  const nonEmptyArrays = ['prerequisite_capabilities', 'success_criteria'];
  for (const c of challenges) {
    const fileRel = rel(c.metaPath);
    const raw = c.rawMeta || {};
    for (const field of scalarFields) {
      if (isEmptyMetaValue(raw[field])) addError(fileRel, 0, `missing or empty required meta field "${field}"`);
    }
    if (!Object.prototype.hasOwnProperty.call(raw, 'prerequisites')) {
      addError(fileRel, 0, 'missing required meta field "prerequisites" (use [] when intentionally independent)');
    }
    for (const field of nonEmptyArrays) {
      if (!Array.isArray(raw[field]) || raw[field].filter(v => String(v).trim()).length === 0) {
        addError(fileRel, 0, `missing or empty required meta list "${field}"`);
      }
    }
    if (!Array.isArray(raw.tags) || raw.tags.length === 0) addWarning(fileRel, 0, 'meta tags list is empty');
    if (raw.id && raw.id !== c.meta.id) addError(fileRel, 0, `raw id "${raw.id}" normalizes to "${c.meta.id}"`);
    if (raw.module && raw.module !== c.moduleId) addError(fileRel, 0, `module "${raw.module}" does not match directory "${c.moduleId}"`);
    if (raw.duration_minutes !== undefined && (!Number.isFinite(Number(raw.duration_minutes)) || Number(raw.duration_minutes) <= 0)) {
      addError(fileRel, 0, `duration_minutes must be a positive number: ${raw.duration_minutes}`);
    }
    if (raw.difficulty && !['beginner', 'intermediate', 'advanced', 'foundational'].includes(String(raw.difficulty))) {
      addError(fileRel, 0, `unknown difficulty "${raw.difficulty}"`);
    }
    if (raw.tier && !['setup', 'core', 'stretch', 'bonus'].includes(String(raw.tier))) {
      addError(fileRel, 0, `unknown tier "${raw.tier}"`);
    }
  }
}

function auditPlaceholders(files) {
  const patterns = [
    { name: 'REPLACE', re: /\bREPLACE\b/ },
    { name: 'YOUR_ORG', re: /\bYOUR_ORG\b|\bYOUR_REPO\b/ },
    { name: 'OWNER/REPO', re: /\bOWNER\/REPO\b/ },
    { name: 'XXXXX', re: /\bX{5,}\b/ },
    { name: 'docs.example.com', re: /\bdocs\.example\.com\b/i },
  ];
  for (const file of files.filter(p => /\.(md|yml|html)$/i.test(p))) {
    const fileRel = rel(file);
    if (fileRel.startsWith('modules/_TEMPLATE/')) continue;
    const lines = readText(file).split(/\r?\n/);
    let inFence = false;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (/^\s*```/.test(line)) inFence = !inFence;
      for (const pattern of patterns) {
        if (!pattern.re.test(line)) continue;
        const context = lines.slice(Math.max(0, i - 4), Math.min(lines.length, i + 2)).join('\n');
        if (isIllustrativePlaceholder(pattern.name, line, context, inFence)) continue;
        addError(fileRel, i + 1, `unresolved placeholder token "${pattern.name}"`);
      }
    }
  }
}

function isIllustrativePlaceholder(name, line, context, inFence) {
  if (name === 'REPLACE' || name === 'XXXXX') return false;
  const illustrative = /(example|sample|template|placeholder|format|pattern|should follow|use a github url|your repo|e\.g\.)/i;
  if (illustrative.test(line) || illustrative.test(context)) return true;
  return inFence && /(example|sample)/i.test(context);
}

function auditGuideSurfaces(challenges) {
  for (const c of challenges) {
    const titleNeedle = normalizeText(c.meta.title || '');
    const readmePath = path.join(c.dir, 'README.md');
    const coachPath = path.join(c.dir, 'COACH.md');
    if (!fs.existsSync(readmePath)) addError(rel(c.dir), 0, `${c.meta.id} missing README.md student guide`);
    if (!fs.existsSync(coachPath)) addError(rel(c.dir), 0, `${c.meta.id} missing COACH.md facilitator guide`);

    if (fs.existsSync(readmePath)) {
      const readme = readText(readmePath);
      const h1 = (readme.match(/^#\s+(.+)$/m) || [])[1] || '';
      if (titleNeedle && h1 && !titleMatchesHeading(titleNeedle, h1)) {
        addWarning(rel(readmePath), 1, `README title does not include meta title "${c.meta.title}"`);
      }
      if (!/^##\s+(Success Criteria|Acceptance Criteria|Verify|Verification)\b/im.test(readme)
        && (!Array.isArray(c.meta.success_criteria) || c.meta.success_criteria.length === 0)) {
        addWarning(rel(readmePath), 0, 'student guide has no visible success/verification surface');
      }
    }

    if (fs.existsSync(coachPath)) {
      const coach = readText(coachPath);
      const hasAssessmentSurface = /(grading rubric|rubric|expected (outputs?|outcomes?|solution shape)|strong evidence|how to verify|verification|success check|acceptance checklist|common (gaps|blockers|pitfalls))/i.test(coach);
      if (!hasAssessmentSurface) addWarning(rel(coachPath), 0, 'coach guide lacks an expected-output, verification, or rubric surface');
    }
  }
}

function normalizeText(value) {
  return String(value)
    .toLowerCase()
    .replace(/^challenge\s+[\w.-]+[:—-]\s*/, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function titleMatchesHeading(titleNeedle, heading) {
  const normalizedHeading = normalizeText(heading);
  if (normalizedHeading.includes(titleNeedle)) return true;
  const titleWords = titleNeedle.split(/\s+/).filter(word => word.length > 2 && word !== 'the');
  return titleWords.length > 0 && titleWords.every(word => normalizedHeading.includes(word));
}

function auditNumberingGaps(challenges) {
  const groups = new Map();
  for (const c of challenges) {
    const local = String(c.meta.id).startsWith(`${c.moduleId}-`) ? String(c.meta.id).slice(c.moduleId.length + 1) : c.slug;
    const parsed = parseNumberedLocalId(c.moduleId, local);
    if (!parsed) continue;
    const key = `${c.moduleId}:${parsed.group}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push({ number: parsed.number, id: c.meta.id });
  }
  const documentation = [
    path.join(ROOT, 'README.md'),
    path.join(ROOT, 'modules', 'README.md'),
    path.join(ROOT, 'CONTRIBUTING.md'),
    path.join(ROOT, '.squad', 'decisions.md'),
  ].filter(fs.existsSync).map(readText).join('\n').toLowerCase();

  for (const [groupKey, entries] of groups) {
    const sorted = [...new Set(entries.map(e => e.number))].sort((a, b) => a - b);
    if (sorted.length < 2) continue;
    for (let n = sorted[0]; n <= sorted[sorted.length - 1]; n++) {
      if (sorted.includes(n)) continue;
      const [moduleId, group] = groupKey.split(':');
      const localId = formatMissingLocalId(moduleId, group, n);
      if (!documentation.includes(`${moduleId}-${localId}`.toLowerCase()) && !documentation.includes(`gap at ${localId}`.toLowerCase())) {
        addWarning(`modules/${moduleId}`, 0, `undocumented numbering gap: ${moduleId}-${localId}`);
      }
    }
  }
}

function parseNumberedLocalId(moduleId, local) {
  let m;
  if ((m = local.match(/^ch(\d+)$/i))) return { group: 'ch', number: Number(m[1]) };
  if ((m = local.match(/^s(\d+)$/i))) return { group: 's', number: Number(m[1]) };
  if ((m = local.match(/^(\d+)$/))) return { group: 'root', number: Number(m[1]) };
  if (moduleId === 'ghaw' && (m = local.match(/^(\d+)-(\d+)$/))) return { group: m[1], number: Number(m[2]) };
  return null;
}

function formatMissingLocalId(moduleId, group, number) {
  const width = moduleId === 'ghaw' || group === 'root' || group === 's' ? 2 : 2;
  const n = String(number).padStart(width, '0');
  if (group === 'ch') return `ch${n}`;
  if (group === 's') return `s${n}`;
  if (group === 'root') return n;
  return `${group}-${n}`;
}

function markdownFiles() {
  return [
    path.join(ROOT, 'README.md'),
    path.join(ROOT, 'CONTRIBUTING.md'),
    path.join(MODULES_DIR, 'README.md'),
    ...walk(MODULES_DIR, p => /\.(md|yml)$/i.test(p)),
    ...walk(DOCS_DIR, p => {
      const r = rel(p);
      return /\.(md|html|css)$/i.test(p) && !r.startsWith('docs/assets/data/') && !r.startsWith('docs/resources/');
    }),
  ].filter((p, i, a) => fs.existsSync(p) && a.indexOf(p) === i);
}

function auditCodeFencesAndCommands(files) {
  for (const file of files.filter(p => /\.(md|yml)$/i.test(p))) {
    const lines = readText(file).split(/\r?\n/);
    const fileRel = rel(file);
    let inFence = false;
    let fenceStart = 0;
    let fenceLang = '';
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const fence = line.match(/^\s*```\s*([^`]*)\s*$/);
      if (fence) {
        if (!inFence) {
          inFence = true;
          fenceStart = i + 1;
          fenceLang = fence[1].trim().toLowerCase();
          state.counts.codeFences++;
          if (/^(bash|sh|shell|console|zsh|powershell|ps1|pwsh)$/.test(fenceLang)) state.counts.commandFences++;
        } else {
          inFence = false;
          fenceLang = '';
        }
        continue;
      }
      const commandPrompt = line.match(/^\s*(?:\$|>)\s+\S+/);
      if (commandPrompt || (inFence && /^(bash|sh|shell|console|zsh|powershell|ps1|pwsh)$/.test(fenceLang) && /^\s*[A-Za-z0-9_.\/-]+(?:\s|$)/.test(line) && line.trim() && !line.trim().startsWith('#'))) {
        state.counts.commandLines++;
      }
    }
    if (inFence) addError(fileRel, fenceStart, 'unclosed Markdown code fence');
  }
}

function linkCandidates(text) {
  const links = [];
  const md = /!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g;
  let m;
  while ((m = md.exec(text)) !== null) links.push({ href: m[1], index: m.index });
  const html = /\b(?:href|src)=["']([^"']+)["']/gi;
  while ((m = html.exec(text)) !== null) links.push({ href: m[1], index: m.index });
  const raw = /https?:\/\/[^\s<>\])"`'{}]+/g;
  while ((m = raw.exec(text)) !== null) links.push({ href: trimUrlCandidate(m[0]), index: m.index });
  return links;
}

function trimUrlCandidate(href) {
  return href.replace(/[.,;:]+$/, '');
}

function lineAt(text, index) {
  return text.slice(0, index).split(/\r?\n/).length;
}

function withoutFragmentAndQuery(href) {
  return href.split('#')[0].split('?')[0];
}

function isExternal(href) { return /^https?:\/\//i.test(href); }
function isSkippable(href) {
  return !href
    || href.startsWith('#')
    || href.includes('${')
    || href.includes('{{')
    || /^(mailto|tel|javascript|data):/i.test(href)
    || href.startsWith('{');
}

function auditLinks(files) {
  const challengeIds = collectChallengeIds();
  for (const file of files) {
    const text = readText(file);
    const fileRel = rel(file);
    for (const link of linkCandidates(text)) {
      const href = link.href.trim();
      if (isSkippable(href)) continue;
      state.counts.urls++;
      const line = lineAt(text, link.index);
      if (isExternal(href)) {
        state.counts.externalLinks++;
        state.externalUrls.add(href);
        auditInternalPagesUrl(fileRel, line, href);
        continue;
      }
      state.counts.internalLinks++;
      const target = withoutFragmentAndQuery(href);
      if (!target) continue;
      if (file.startsWith(DOCS_DIR) && isValidDocsRoute(href, challengeIds)) continue;
      const base = file.startsWith(DOCS_DIR) ? path.dirname(file) : path.dirname(file);
      const resolved = path.resolve(base, decodeURIComponent(target));
      if (!resolved.startsWith(ROOT)) {
        addError(fileRel, line, `internal link escapes repository: ${href}`);
        continue;
      }
      if (!fs.existsSync(resolved)) addError(fileRel, line, `internal link target does not exist: ${href}`);
    }
  }
}

function auditRenderedGuideLinks(challenges) {
  const challengeIds = new Set(challenges.map(c => c.meta.id));
  for (const c of challenges) {
    for (const kind of ['README.md', 'COACH.md']) {
      const generated = path.join(DOCS_DIR, 'assets', 'data', 'challenges', c.meta.id, kind);
      if (!fs.existsSync(generated)) continue;
      const text = readText(generated);
      const fileRel = rel(generated);
      for (const link of linkCandidates(text)) {
        const href = link.href.trim();
        if (isSkippable(href) || isExternal(href)) continue;
        const target = withoutFragmentAndQuery(href);
        if (!target) continue;
        if (isValidDocsRoute(href, challengeIds)) continue;
        // Markdown is injected into docs/challenge.html, so browser-relative links resolve from docs/.
        const renderedTarget = path.resolve(DOCS_DIR, decodeURIComponent(target));
        if (!renderedTarget.startsWith(DOCS_DIR) || !fs.existsSync(renderedTarget)) {
          addError(fileRel, lineAt(text, link.index), `rendered guide link will 404 on GitHub Pages: ${href}`);
        }
      }
    }
  }
}

function auditInternalPagesUrl(fileRel, line, href) {
  let url;
  try { url = new URL(href); } catch { return; }
  if (!PAGES_HOSTS.has(url.hostname)) return;
  const pathName = decodeURIComponent(url.pathname.replace(/\/+/g, '/'));
  let docsRelative = pathName.replace(/^\//, '');
  if (docsRelative.startsWith(`${PROJECT_SLUG}/`)) docsRelative = docsRelative.slice(PROJECT_SLUG.length + 1);
  const docsTarget = path.join(DOCS_DIR, docsRelative || 'index.html');
  const challengeIds = collectChallengeIds();
  if (!fs.existsSync(docsTarget) && !isValidDocsRoute(docsRelative + url.search, challengeIds)) {
    addError(fileRel, line, `internal GitHub Pages URL has no generated target and will 404: ${href}`);
  }
}

function collectChallengeIds() {
  try {
    const platform = JSON.parse(readText(PLATFORM_PATH));
    return new Set((platform.challenges || []).map(c => c.id));
  } catch {
    return new Set();
  }
}

function isValidDocsRoute(href, challengeIds) {
  const [pathname, query = ''] = href.split('?');
  const page = pathname.replace(/^\.?\//, '');
  if (page === 'challenge.html') {
    const id = new URLSearchParams(query).get('id');
    return Boolean(id && challengeIds.has(id));
  }
  return fs.existsSync(path.join(DOCS_DIR, page));
}

function auditVersionClaims(files) {
  const claimRe = /\b(?:Node(?:\.js)?|npm|Python|CodeQL|Dependabot|GitHub Actions|gh(?:\s+CLI)?|Actions runner)\b[^\n]{0,80}?(?:>=|≤|≥|v?\d+(?:\.\d+){0,2})/gi;
  for (const file of files.filter(p => /\.(md|yml)$/i.test(p))) {
    const text = readText(file);
    let m;
    while ((m = claimRe.exec(text)) !== null) {
      state.counts.versionClaims++;
      const claim = m[0].replace(/\s+/g, ' ').trim();
      if (/preview|beta|limited availability/i.test(claim)) {
        addWarning(rel(file), lineAt(text, m.index), `version/availability claim should be source-backed: ${claim}`);
      }
    }
  }
  const pkg = JSON.parse(readText(path.join(ROOT, 'package.json')));
  if (pkg.engines && pkg.engines.node) {
    const readme = readText(path.join(ROOT, 'README.md'));
    if (!readme.includes(pkg.engines.node.replace('>=', '≥ ')) && !readme.includes(pkg.engines.node)) {
      addWarning('README.md', 0, `README does not mention package.json Node engine (${pkg.engines.node})`);
    }
  }
}

function auditCron(files) {
  const cronQuoted = /\bcron:\s*["']([^"']+)["']/gi;
  const inlineCron = /`((?:\*|\d|\*\/\d)[^`\n]*\s+(?:\*|\d|\*\/\d)[^`\n]*\s+(?:\*|\d|\*\/\d)[^`\n]*\s+(?:\*|\d|\*\/\d)[^`\n]*\s+(?:\*|\d|\*\/\d)[^`\n]*)`/g;
  for (const file of files.filter(p => /\.(md|yml)$/i.test(p))) {
    const text = readText(file);
    for (const re of [cronQuoted, inlineCron]) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(text)) !== null) {
        const expr = m[1].trim();
        if (!looksLikeCron(expr)) continue;
        state.counts.cronExpressions++;
        const reason = validateCron(expr);
        if (reason) addError(rel(file), lineAt(text, m.index), `invalid cron expression "${expr}": ${reason}`);
      }
    }
  }
}

function looksLikeCron(expr) { return expr.trim().split(/\s+/).length === 5 && /^[\d\s*\/,.\-]+$/.test(expr); }
function validateCron(expr) {
  const fields = expr.trim().split(/\s+/);
  if (fields.length !== 5) return 'expected 5 fields';
  const ranges = [[0, 59], [0, 23], [1, 31], [1, 12], [0, 7]];
  for (let i = 0; i < fields.length; i++) {
    const bad = validateCronField(fields[i], ranges[i][0], ranges[i][1]);
    if (bad) return `field ${i + 1}: ${bad}`;
  }
  return '';
}
function validateCronField(field, min, max) {
  for (const part of field.split(',')) {
    if (!part) return 'empty list item';
    const [rangePart, stepPart] = part.split('/');
    if (part.split('/').length > 2) return 'too many / separators';
    if (stepPart !== undefined && (!/^\d+$/.test(stepPart) || Number(stepPart) < 1)) return 'invalid step';
    if (rangePart === '*') continue;
    const bounds = rangePart.split('-');
    if (bounds.length > 2 || bounds.some(b => !/^\d+$/.test(b))) return `unsupported token ${part}`;
    const nums = bounds.map(Number);
    if (nums.some(n => n < min || n > max)) return `${part} outside ${min}-${max}`;
    if (nums.length === 2 && nums[0] > nums[1]) return `${part} has descending range`;
  }
  return '';
}

function auditAttribution(challenges) {
  for (const c of challenges) {
    const fileRel = rel(c.metaPath);
    const m = c.meta;
    if (!m.source_repo) addError(fileRel, 0, 'missing source_repo attribution');
    if (!m.source_path) addError(fileRel, 0, 'missing source_path attribution');
    if (m.source_path && (path.isAbsolute(String(m.source_path)) || String(m.source_path).includes('..'))) {
      addError(fileRel, 0, `source_path must be repository-relative and non-traversing: ${m.source_path}`);
    }
    const attrPath = path.join(MODULES_DIR, c.moduleId, 'ATTRIBUTION.md');
    if (m.source_repo && fs.existsSync(attrPath)) {
      const attr = readText(attrPath);
      if (!attr.includes(m.source_repo)) addError(rel(attrPath), 0, `does not mention source_repo used by ${m.id}: ${m.source_repo}`);
    }
  }
}

function auditCatalog(challenges) {
  if (!fs.existsSync(PLATFORM_PATH)) addError(rel(PLATFORM_PATH), 0, 'missing generated platform catalog; run npm run build');
  if (!fs.existsSync(GRAPH_PATH)) addError(rel(GRAPH_PATH), 0, 'missing generated dependency graph; run npm run build');
  if (!fs.existsSync(PLATFORM_PATH) || !fs.existsSync(GRAPH_PATH)) return;
  const platform = JSON.parse(readText(PLATFORM_PATH));
  const graph = JSON.parse(readText(GRAPH_PATH));
  const sourceIds = new Set(challenges.map(c => c.meta.id));
  const catalogIds = new Set((platform.challenges || []).map(c => c.id));
  for (const id of sourceIds) if (!catalogIds.has(id)) addError(rel(PLATFORM_PATH), 0, `missing source challenge ${id}`);
  for (const id of catalogIds) if (!sourceIds.has(id)) addError(rel(PLATFORM_PATH), 0, `contains stale challenge ${id}`);
  for (const c of platform.challenges || []) {
    for (const key of ['student_path', 'coach_path']) {
      if (!c[key]) { addError(rel(PLATFORM_PATH), 0, `${c.id} missing ${key}`); continue; }
      const target = path.join(DOCS_DIR, c[key]);
      if (!fs.existsSync(target)) addError(rel(PLATFORM_PATH), 0, `${c.id} ${key} target missing: ${c[key]}`);
    }
  }
  const expectedEdges = new Set();
  for (const c of challenges) for (const dep of c.meta.prerequisites || []) expectedEdges.add(`${dep}->${c.meta.id}`);
  const actualEdges = new Set((graph.edges || []).map(e => `${e.from}->${e.to}`));
  for (const edge of expectedEdges) if (!actualEdges.has(edge)) addError(rel(GRAPH_PATH), 0, `missing dependency edge ${edge}`);
  for (const edge of actualEdges) if (!expectedEdges.has(edge)) addError(rel(GRAPH_PATH), 0, `stale dependency edge ${edge}`);
  const moduleCounts = new Map();
  for (const c of challenges) moduleCounts.set(c.moduleId, (moduleCounts.get(c.moduleId) || 0) + 1);
  for (const mod of platform.modules || []) {
    const expected = moduleCounts.get(mod.id) || 0;
    if (mod.challenge_count !== expected) addError(rel(PLATFORM_PATH), 0, `${mod.id} challenge_count ${mod.challenge_count} != ${expected}`);
  }
  auditStaticChallengeCounts(platform);
}

function auditStaticChallengeCounts(platform) {
  const allowedCounts = new Set([
    String((platform.challenges || []).length),
    ...(platform.modules || []).map(mod => String(mod.challenge_count)),
  ]);
  for (const file of [path.join(DOCS_DIR, 'index.html'), path.join(DOCS_DIR, 'catalog.html'), path.join(ROOT, 'README.md'), path.join(ROOT, 'modules', 'README.md')]) {
    if (!fs.existsSync(file)) continue;
    const text = readText(file);
    const countRe = /\b(\d+)\s+challenges\b/gi;
    let match;
    while ((match = countRe.exec(text)) !== null) {
      if (!allowedCounts.has(match[1])) {
        addError(rel(file), lineAt(text, match.index), `static challenge count ${match[1]} does not match catalog totals/module counts`);
      }
    }
  }
}

async function auditExternalUrls() {
  if (!CHECK_EXTERNAL) return;
  const urls = [...state.externalUrls].sort().filter(url => !shouldSkipExternalCheck(url));
  const checks = urls.map(url => checkUrl(url).then(result => {
    if (!result.ok) addWarning('(external-url)', 0, `${url} returned ${result.status || result.error}`);
  }));
  await Promise.all(checks);
}

function shouldSkipExternalCheck(url) {
  let parsed;
  try { parsed = new URL(url); } catch { return false; }
  if (['localhost', '127.0.0.1', '::1'].includes(parsed.hostname) || parsed.hostname.endsWith('.local')) return true;
  if ((parsed.hostname === 'fonts.googleapis.com' || parsed.hostname === 'fonts.gstatic.com') && parsed.pathname === '/') return true;
  if (parsed.hostname === 'github.com' && /^\/orgs\/?$/.test(parsed.pathname)) return true;
  if (parsed.hostname === 'api.github.com' && /^\/scim\/v2\/organizations\/?$/.test(parsed.pathname)) return true;
  if (knownSourceRepoUrls().has(url.replace(/\/+$/, ''))) return true;
  return false;
}

let sourceRepoUrlCache;
function knownSourceRepoUrls() {
  if (sourceRepoUrlCache) return sourceRepoUrlCache;
  sourceRepoUrlCache = new Set();
  if (!fs.existsSync(EXTERNAL_REPOS_PATH)) return sourceRepoUrlCache;
  try {
    const manifest = JSON.parse(readText(EXTERNAL_REPOS_PATH));
    for (const entry of manifest.dependencies || []) {
      if (entry && entry.source && entry.source.url) sourceRepoUrlCache.add(String(entry.source.url).replace(/\/+$/, ''));
    }
  } catch {
    // Shape and JSON errors are reported by verify-external-repos.js.
  }
  return sourceRepoUrlCache;
}

function checkUrl(url) {
  return requestUrl(url, 'HEAD').then(result => {
    if (result.ok || !result.status) return result;
    return requestUrl(url, 'GET');
  });
}

function requestUrl(url, method) {
  return new Promise(resolve => {
    let parsed;
    try {
      parsed = new URL(url);
    } catch {
      resolve({ ok: false, error: 'invalid URL' });
      return;
    }
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      resolve({ ok: false, error: `unsupported protocol ${parsed.protocol}` });
      return;
    }

    const client = parsed.protocol === 'https:' ? https : http;
    let req;
    try {
      req = client.request(parsed, { method, timeout: 8000 }, res => {
        res.resume();
        resolve({ ok: res.statusCode >= 200 && res.statusCode < 400, status: res.statusCode });
      });
    } catch (err) {
      resolve({ ok: false, error: err.code || err.message });
      return;
    }
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, error: 'timeout' }); });
    req.on('error', err => resolve({ ok: false, error: err.code || err.message }));
    req.end();
  });
}

async function main() {
  const challenges = collectChallenges();
  const files = markdownFiles();
  state.counts.files = files.length;
  auditMetaContract(challenges);
  auditPlaceholders(files);
  auditGuideSurfaces(challenges);
  auditNumberingGaps(challenges);
  auditCodeFencesAndCommands(files);
  auditLinks(files);
  auditRenderedGuideLinks(challenges);
  auditVersionClaims(files);
  auditCron(files);
  auditAttribution(challenges);
  auditCatalog(challenges);
  await auditExternalUrls();

  console.log('Audit summary');
  for (const [key, value] of Object.entries(state.counts)) console.log(`  ${key}: ${value}`);
  console.log(`  externalUrlChecks: ${CHECK_EXTERNAL ? 'enabled (warnings only)' : 'disabled'}`);

  if (state.warnings.length) {
    console.warn(`\nWarnings (${state.warnings.length})`);
    for (const w of state.warnings.slice(0, 50)) console.warn(`  ! ${w}`);
    if (state.warnings.length > 50) console.warn(`  ... ${state.warnings.length - 50} more warning(s)`);
  }
  if (state.errors.length) {
    console.error(`\nErrors (${state.errors.length})`);
    for (const e of state.errors.slice(0, 80)) console.error(`  ✗ ${e}`);
    if (state.errors.length > 80) console.error(`  ... ${state.errors.length - 80} more error(s)`);
    process.exit(1);
  }
  console.log('\n✓ audit passed');
}

main().catch(err => {
  console.error(err.stack || err.message);
  process.exit(1);
});

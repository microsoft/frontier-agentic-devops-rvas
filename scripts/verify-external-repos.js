#!/usr/bin/env node
/**
 * Verifies external repository/app dependency metadata against challenge meta.yml.
 * Dependency-free: Node core only. Network checks are opt-in via --external.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const MODULES_DIR = path.join(ROOT, 'modules');
const MANIFEST_PATH = path.join(ROOT, 'external-repos.json');
const CHECK_EXTERNAL = process.argv.includes('--external');

const state = {
  errors: [],
  warnings: [],
  counts: {
    manifestEntries: 0,
    challenges: 0,
    appDependencies: 0,
    sourceRepos: 0,
    externalChecks: 0,
  },
};

function rel(file) {
  return path.relative(ROOT, file).replace(/\\/g, '/');
}

function addError(message) {
  state.errors.push(message);
}

function addWarning(message) {
  state.warnings.push(message);
}

function readText(file) {
  return fs.readFileSync(file, 'utf8');
}

function walk(dir, filter = () => true, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name === '.git' || ent.name === 'node_modules' || ent.name === '.squad' || ent.name === '_TEMPLATE') continue;
    const file = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(file, filter, out);
    else if (filter(file)) out.push(file);
  }
  return out;
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

function stripComment(s) {
  return s.replace(/\s+#.*$/, '');
}

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
  const meta = Object.assign({}, raw);
  if (!meta.id) meta.id = `${moduleId}-${slug}`;
  if (!String(meta.id).includes('-')) meta.id = `${moduleId}-${meta.id}`;
  if (!meta.module) meta.module = moduleId;
  if (!meta.app_dependency) meta.app_dependency = meta.app || 'none';
  return meta;
}

function collectChallenges() {
  const challenges = [];
  const files = walk(MODULES_DIR, file => /^modules\/[^/]+\/challenges\/[^/]+\/meta\.yml$/.test(rel(file)));
  for (const metaPath of files) {
    const parts = rel(metaPath).split('/');
    const moduleId = parts[1];
    const slug = parts[3];
    const meta = normaliseMeta(parseMeta(readText(metaPath)), moduleId, slug);
    challenges.push({ id: meta.id, meta, metaPath });
  }
  challenges.sort((a, b) => a.id.localeCompare(b.id));
  state.counts.challenges = challenges.length;
  return challenges;
}

function loadManifest() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    addError('external-repos.json is missing');
    return { dependencies: [] };
  }
  try {
    const manifest = JSON.parse(readText(MANIFEST_PATH));
    if (!manifest || !Array.isArray(manifest.dependencies)) {
      addError('external-repos.json must contain a dependencies array');
      return { dependencies: [] };
    }
    state.counts.manifestEntries = manifest.dependencies.length;
    return manifest;
  } catch (err) {
    addError(`external-repos.json is invalid JSON: ${err.message}`);
    return { dependencies: [] };
  }
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function hasSourceOrLocalPath(entry) {
  return Boolean(entry && ((entry.source && isNonEmptyString(entry.source.url)) || isNonEmptyString(entry.local_path)));
}

function sourceNeedsImmutableRef(entry) {
  if (!entry || !entry.source || !isNonEmptyString(entry.source.url)) return false;
  const acquisition = entry.acquisition || '';
  return acquisition !== 'docker-runtime' && acquisition !== 'reference-only';
}

function challengeUsesEntry(challenge, entry) {
  const usage = entry.usage || {};
  if (entry.type === 'app_dependency') return challenge.meta.app_dependency === entry.key;
  if (usage.field && Object.prototype.hasOwnProperty.call(challenge.meta, usage.field)) {
    const allowed = [usage.value, ...(Array.isArray(usage.aliases) ? usage.aliases : [])].filter(Boolean);
    return allowed.includes(challenge.meta[usage.field]);
  }
  return false;
}

function validateManifestShape(entries) {
  const keys = new Set();
  for (const [index, entry] of entries.entries()) {
    const label = entry && entry.key ? entry.key : `entry[${index}]`;
    for (const field of ['key', 'name', 'description', 'type', 'acquisition', 'attribution']) {
      if (!isNonEmptyString(entry && entry[field])) addError(`${label}: missing required field ${field}`);
    }
    if (!hasSourceOrLocalPath(entry)) addError(`${label}: must specify source.url or local_path`);
    if (sourceNeedsImmutableRef(entry) && !isNonEmptyString(entry.source.sha) && !isNonEmptyString(entry.source.tag)) {
      addError(`${label}: source.url entries must specify source.sha or source.tag`);
    }
    if (entry && entry.type === 'source_repo' && (!entry.usage || entry.usage.field !== 'source_repo' || !isNonEmptyString(entry.usage.value))) {
      addError(`${label}: source_repo entries must specify usage.field \"source_repo\" and usage.value`);
    }
    if (entry && entry.local_path && path.isAbsolute(entry.local_path)) addError(`${label}: local_path must be repository-relative`);
    if (entry && entry.local_path && String(entry.local_path).includes('..')) addError(`${label}: local_path must not contain ..`);
    if (!Array.isArray(entry && entry.affected_challenge_ids) || entry.affected_challenge_ids.length === 0) {
      addError(`${label}: affected_challenge_ids must be a non-empty array`);
    }
    if (entry && keys.has(entry.key)) addError(`${label}: duplicate manifest key`);
    if (entry && entry.key) keys.add(entry.key);
  }
}

function validateAppDependencies(challenges, entries) {
  const appEntries = new Map(entries.filter(e => e.type === 'app_dependency').map(e => [e.key, e]));
  const liveDeps = new Map();
  for (const challenge of challenges) {
    const dep = challenge.meta.app_dependency || 'none';
    if (dep === 'none') continue;
    state.counts.appDependencies++;
    if (!liveDeps.has(dep)) liveDeps.set(dep, []);
    liveDeps.get(dep).push(challenge.id);
    if (!appEntries.has(dep)) addError(`${rel(challenge.metaPath)}: app_dependency "${dep}" is not defined in external-repos.json`);
  }

  for (const [key, entry] of appEntries) {
    const actualIds = new Set(liveDeps.get(key) || []);
    for (const id of actualIds) {
      if (!entry.affected_challenge_ids.includes(id)) addError(`${key}: missing affected_challenge_ids entry for ${id}`);
    }
  }
}

function validateSourceRepos(challenges, entries) {
  const coveredSourceRepos = new Set();
  const sourceEntries = entries.filter(e => e.type === 'source_repo');
  const liveSourceRepos = new Map();

  for (const entry of sourceEntries) {
    if (!entry.usage || entry.usage.field !== 'source_repo') continue;
    if (entry.usage.value) coveredSourceRepos.add(entry.usage.value);
    for (const alias of Array.isArray(entry.usage.aliases) ? entry.usage.aliases : []) coveredSourceRepos.add(alias);
  }

  for (const challenge of challenges) {
    const sourceRepo = challenge.meta.source_repo;
    if (!sourceRepo) continue;
    state.counts.sourceRepos++;
    if (!coveredSourceRepos.has(sourceRepo)) {
      addError(`${rel(challenge.metaPath)}: source_repo "${sourceRepo}" is not defined in external-repos.json`);
    }
    if (!liveSourceRepos.has(sourceRepo)) liveSourceRepos.set(sourceRepo, []);
    liveSourceRepos.get(sourceRepo).push(challenge.id);
  }

  for (const entry of sourceEntries) {
    if (!entry.usage || entry.usage.field !== 'source_repo' || !Array.isArray(entry.affected_challenge_ids)) continue;
    const accepted = [entry.usage.value, ...(Array.isArray(entry.usage.aliases) ? entry.usage.aliases : [])].filter(Boolean);
    for (const sourceRepo of accepted) {
      for (const id of liveSourceRepos.get(sourceRepo) || []) {
        if (!entry.affected_challenge_ids.includes(id)) addError(`${entry.key}: missing affected_challenge_ids entry for ${id}`);
      }
    }
  }
}

function validateAffectedChallenges(challenges, entries) {
  const byId = new Map(challenges.map(c => [c.id, c]));
  for (const entry of entries) {
    if (!Array.isArray(entry.affected_challenge_ids)) continue;
    for (const id of entry.affected_challenge_ids) {
      const challenge = byId.get(id);
      if (!challenge) {
        addError(`${entry.key}: affected challenge id does not exist: ${id}`);
        continue;
      }
      if (!challengeUsesEntry(challenge, entry)) {
        const field = entry.type === 'app_dependency' ? 'app_dependency' : ((entry.usage && entry.usage.field) || 'usage.field');
        addError(`${entry.key}: ${id} does not use expected ${field}`);
      }
    }
  }
}

function validateLocalPaths(entries) {
  for (const entry of entries) {
    if (!entry.local_path) continue;
    const target = path.resolve(ROOT, entry.local_path);
    if (!target.startsWith(ROOT)) addError(`${entry.key}: local_path escapes repository`);
    else if (!fs.existsSync(target)) addError(`${entry.key}: local_path does not exist: ${entry.local_path}`);
  }
}

function runGit(args, options = {}) {
  return new Promise(resolve => {
    const child = execFile('git', args, Object.assign({ timeout: 15000 }, options), (err, stdout, stderr) => {
      if (err) {
        resolve({ ok: false, error: (stderr || err.message).trim() || err.code || 'git command failed' });
        return;
      }
      resolve({ ok: true, stdout });
    });
    child.on('error', err => resolve({ ok: false, error: err.message }));
  });
}

function gitLsRemote(url, ref) {
  const args = ['ls-remote', url];
  if (ref) args.push(ref);
  return runGit(args);
}

async function gitFetchSha(url, sha) {
  const advertised = await gitLsRemote(url, sha);
  if (advertised.ok && advertised.stdout.includes(sha)) return advertised;

  const tmp = fs.mkdtempSync(path.join(ROOT, '.repo-check-'));
  try {
    const init = await runGit(['init', '--quiet'], { cwd: tmp });
    if (!init.ok) return init;
    return await runGit(['fetch', '--depth=1', url, sha], { cwd: tmp, timeout: 30000 });
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

async function checkExternal(entries) {
  if (!CHECK_EXTERNAL) return;
  for (const entry of entries) {
    if (!entry.source || !entry.source.url) continue;
    state.counts.externalChecks++;
    const repoResult = await gitLsRemote(entry.source.url, 'HEAD');
    if (!repoResult.ok) {
      addError(`${entry.key}: source repository check failed (${repoResult.error})`);
      continue;
    }
    if (entry.source.tag) {
      state.counts.externalChecks++;
      const tagRef = `refs/tags/${entry.source.tag}^{}`;
      const tagResult = await gitLsRemote(entry.source.url, tagRef);
      if (!tagResult.ok || !tagResult.stdout.trim()) {
        addError(`${entry.key}: source tag check failed for ${entry.source.tag} (${tagResult.error || 'not found'})`);
      } else if (entry.source.sha && !tagResult.stdout.includes(entry.source.sha)) {
        addError(`${entry.key}: source tag ${entry.source.tag} does not resolve to ${entry.source.sha}`);
      }
    }
    if (entry.source.sha && !entry.source.tag) {
      state.counts.externalChecks++;
      const shaResult = await gitFetchSha(entry.source.url, entry.source.sha);
      if (!shaResult.ok) {
        addError(`${entry.key}: source sha fetch failed for ${entry.source.sha} (${shaResult.error})`);
      }
    }
  }
}

async function main() {
  const manifest = loadManifest();
  const challenges = collectChallenges();
  const entries = manifest.dependencies || [];

  validateManifestShape(entries);
  validateLocalPaths(entries);
  validateAppDependencies(challenges, entries);
  validateSourceRepos(challenges, entries);
  validateAffectedChallenges(challenges, entries);
  await checkExternal(entries);

  console.log('External repo verification summary');
  for (const [key, value] of Object.entries(state.counts)) console.log(`  ${key}: ${value}`);
  console.log(`  network: ${CHECK_EXTERNAL ? 'enabled' : 'disabled'}`);

  if (state.warnings.length) {
    console.warn(`\nWarnings (${state.warnings.length})`);
    for (const warning of state.warnings) console.warn(`  ! ${warning}`);
  }
  if (state.errors.length) {
    console.error(`\nErrors (${state.errors.length})`);
    for (const error of state.errors) console.error(`  ✗ ${error}`);
    process.exit(1);
  }
  console.log('\n✓ external repo verification passed');
}

main().catch(err => {
  console.error(err.stack || err.message);
  process.exit(1);
});

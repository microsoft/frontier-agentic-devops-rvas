#!/usr/bin/env node
/**
 * Agentic DevSecOps — build step (dependency-free, Node core only).
 *
 * Reads every  modules/<moduleId>/challenges/<slug>/meta.yml  as the single
 * source of truth and emits site-consumable data + copied guides under docs/assets/data/.
 *
 *   node docs/build.js
 *
 * Outputs:
 *   docs/assets/data/platform.json                       — full catalog (modules + challenges)
 *   docs/assets/data/dependency-graph.json               — prereq graph (nodes + edges)
 *   docs/assets/data/challenges/<id>/README.md           — delivery guide copy
 *   docs/resources/<moduleId>/...                        — module resource files
 *
 * Validation (exits non-zero on errors):
 *   - Every prerequisites[] entry must reference a real challenge id in the catalog.
 *   - No circular dependencies.
 *   - Warns on missing optional fields.
 */
'use strict';

const fs   = require('fs');
const path = require('path');

/* ─── Module config ──────────────────────────────────────────────────────────
 * Kaylee: tweak names, descriptions, colors, and icons here.
 * Track descriptions are shown on module detail pages.
 * ─────────────────────────────────────────────────────────────────────────── */
const MODULE_CONFIG = {
  ghec: {
    name: 'GitHub Enterprise Cloud',
    description: 'Set up GitHub Enterprise Cloud in your organization, then put the policies and workflows your teams need into practice.',
    color: '#0969da',
    icon: 'icon-ghec.svg',
    tracks: {
      'developer-flow':   { name: 'Developer Flow',       description: 'Help developers plan work, review code, and use Codespaces across the organization.' },
      'admin-governance': { name: 'Admin & Governance',   description: 'Set up organization policies, identity, audit logs, and compliance controls.' },
      'security':         { name: 'Security',             description: 'Protect code with scanning, Dependabot, and supply-chain controls.' },
      'automation-ai':    { name: 'Automation & AI',      description: 'Build automation with Actions, GitHub APIs, webhooks, apps, and AI-assisted workflows.' },
      'migration':        { name: 'Migration',             description: 'Move repositories and their history into GitHub Enterprise Cloud from another platform.' },
    },
  },
  ghas: {
    name: 'GitHub Advanced Security',
    description: 'Find real security problems in a vulnerable app, then fix them with GitHub Advanced Security.',
    color: '#cf222e',
    icon: 'icon-ghas.svg',
    tracks: {
      'security': { name: 'Security', description: 'Use code scanning, secret scanning, and Dependabot against a vulnerable application.' },
    },
  },
  ghaw: {
    name: 'GitHub Agentic Workflows',
    description: 'Build AI agent workflows on GitHub Actions and learn how to run them safely.',
    color: '#8250df',
    icon: 'icon-ghaw.svg',
    tracks: {
      'hello-agent':              { name: 'Hello, Agent', description: 'Build your first agents with schedules, triggers, and controlled outputs.' },
      'repo-concierge':           { name: 'Repo Concierge', description: 'Automate issue triage and pull request review from repository events.' },
      'continuous-intelligence': { name: 'Continuous Intelligence', description: 'Connect workflows, MCP tools, and custom engines to handle larger jobs.' },
      'production-patterns':      { name: 'Production Patterns', description: 'Adapt proven Agent Factory examples to work in your own repository.' },
    },
  },
  'sre-agent': {
    name: 'SRE Agent',
    description: 'Use Azure SRE Agent to investigate service problems, trace evidence back to source code, and make reviewed fixes.',
    color: '#1a7f37',
    icon: 'icon-agentic-devops.svg',
    tracks: {
      'azure-sre-agent': { name: 'Azure SRE Agent', description: 'Set up the agent, connect a service, investigate an alert, and review a fix.' },
    },
  },
};

/* ─── Paths ──────────────────────────────────────────────────────────────── */
const ROOT           = path.resolve(__dirname, '..');
const MODULES_DIR    = path.join(ROOT, 'modules');
const OUT_DATA_DIR   = path.join(__dirname, 'assets', 'data');
const OUT_GUIDES_DIR = path.join(OUT_DATA_DIR, 'challenges');
const OUT_RESOURCES_DIR = path.join(__dirname, 'resources');
const OUTCOMES_PATH  = path.join(ROOT, 'outcomes.json');
const CURRENT_SOURCE_REPO = 'microsoft/frontier-agentic-devops-rvas';
const CURRENT_SOURCE_REF = process.env.SOURCE_REF || 'main';

/* ─── Minimal YAML parser ────────────────────────────────────────────────────
 * Handles only the locked meta.yml contract: scalar key-value pairs, block
 * lists, inline comments. NOT a general parser — intentional.
 * ─────────────────────────────────────────────────────────────────────────── */
function parseMeta(text) {
  const out          = {};
  let currentListKey = null;
  const lines = text.split(/\r?\n/);

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    if (!raw.trim() || /^\s*#/.test(raw)) continue;

    // Block-list item.
    const listItem = raw.match(/^\s*-\s+(.*)$/);
    if (listItem && currentListKey) {
      const val = stripComment(listItem[1]).trim();
      if (val) out[currentListKey].push(val);
      continue;
    }

    const kv = raw.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!kv) continue;

    const key  = kv[1];
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
      out[key]       = coerceBlock(rest[0], blockLines);
      currentListKey = null;
    } else if (rest === '' || rest === '[]') {
      out[key]       = [];
      currentListKey = key;
    } else {
      out[key]       = coerce(rest);
      currentListKey = null;
    }
  }
  return out;
}

function stripComment(s) {
  return s.replace(/\s+#.*$/, '');
}

function coerce(v) {
  if (v === 'true')  return true;
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

/* ─── Field normalisation ───────────────────────────────────────────────────
 * Maps legacy GHEC field names to the platform contract so old-style meta.yml
 * files (pre-migration) don't hard-fail during the porting phase.
 * ─────────────────────────────────────────────────────────────────────────── */
function normaliseMeta(raw, moduleId, slug) {
  const m = Object.assign({}, raw);

  // id: legacy GHEC files use bare "ch01"; prefix with module if not prefixed.
  if (!m.id) m.id = `${moduleId}-${slug}`;
  if (!String(m.id).includes('-')) m.id = `${moduleId}-${m.id}`;

  const explicitOrder = Number(m.display_order);
  const idOrder = String(m.id).match(/(?:ch)?(\d+)$/);
  m.display_order = Number.isFinite(explicitOrder)
    ? explicitOrder
    : idOrder ? Number(idOrder[1]) : Number.MAX_SAFE_INTEGER;

  // module: inject if absent
  if (!m.module) m.module = moduleId;

  // duration_minutes: legacy uses duration_hours
  if (!m.duration_minutes && m.duration_hours) {
    m.duration_minutes = m.duration_hours * 60;
  }

  // prerequisites: legacy GHEC uses "requires" but that field mixes challenge IDs
  // (e.g. "ghec-ch00") with environment types (e.g. "org", "repo", "codespace").
  // Only promote items that look like challenge IDs (contain a hyphen).
  if (!m.prerequisites) {
    const raw = Array.isArray(m.requires) ? m.requires : [];
    m.prerequisites = raw.filter(v => typeof v === 'string' && v.includes('-'));
    // Items that are environment types migrate to min_environment.
    if (!m.min_environment) {
      const envTypes = raw.filter(v => ['org', 'repo', 'codespace'].includes(v));
      if (envTypes.length) m.min_environment = envTypes[0];
    }
  }

  // Ensure arrays
  if (!Array.isArray(m.prerequisites))         m.prerequisites = [];
  if (!Array.isArray(m.prerequisite_capabilities)) m.prerequisite_capabilities = [];
  if (!Array.isArray(m.tags))                  m.tags = [];
  if (!Array.isArray(m.provision_creates))     m.provision_creates = [];
  if (!Array.isArray(m.references))            m.references = [];
  if (!Array.isArray(m.outcomes))              m.outcomes = [];
  if (!Array.isArray(m.personas))              m.personas = [];
  if (!Array.isArray(m.business_value))        m.business_value = [];

  // app_dependency: legacy uses "app"
  if (!m.app_dependency) m.app_dependency = m.app || 'none';

  // difficulty: legacy uses "foundational" → "beginner"
  if (m.difficulty === 'foundational') m.difficulty = 'beginner';

  // defaults
  m.tier    = m.tier    || 'core';
  m.license = m.license || 'MIT';
  m.emu_compatible = m.emu_compatible !== false;

  return m;
}

/* ─── Helpers ─────────────────────────────────────────────────────────────── */
function readDirSafe(p) {
  try { return fs.readdirSync(p, { withFileTypes: true }); }
  catch { return []; }
}

function relativeSourcePath(file) {
  return path.relative(ROOT, file).replace(/\\/g, '/');
}

function validateLocalSourceAttribution(meta, metaPath) {
  if (meta.source_repo !== CURRENT_SOURCE_REPO) return null;

  const sourcePath = String(meta.source_path || '');
  const resolved = path.resolve(ROOT, sourcePath);
  if (!sourcePath || !resolved.startsWith(`${ROOT}${path.sep}`) || !fs.existsSync(resolved)) {
    return `${relativeSourcePath(metaPath)}: source_path "${sourcePath}" does not resolve in ${CURRENT_SOURCE_REPO}`;
  }
  return null;
}

function rewriteResourceLinksForPages(text, moduleId) {
  const moduleResources = `resources/${moduleId}/`;
  return text.replace(
    /(\]\()(https:\/\/microsoft\.github\.io\/resources\/|(?:\.\.\/)+[Rr]esources\/|\/[Rr]esources\/|(?:\.\/)?[Rr]esources\/)/g,
    `$1${moduleResources}`,
  ).replace(
    /(\]\()(?:\.\.\/)+setup\.md/g,
    `$1${moduleResources}setup.md`,
  ).replace(
    /(\]\()(?:\.\.\/)([^/)]+)\/README\.md/g,
    (_match, prefix, slug) => {
      const challengeId = challengeIdFromSlug(moduleId, slug);
      return challengeId ? `${prefix}challenge.html?id=${challengeId}` : `${prefix}../${slug}/README.md`;
    },
  );
}

function challengeIdFromSlug(moduleId, slug) {
  if (moduleId === 'ghec' && /^ch\d+/.test(slug)) return `ghec-${slug.split('-')[0]}`;
  if (moduleId === 'ghas' && /^s\d+/.test(slug)) return `ghas-${slug.split('-')[0]}`;
  if (moduleId === 'ghaw' && /^\d+-\d+/.test(slug)) return `ghaw-${slug.split('-').slice(0, 2).join('-')}`;
  if (moduleId === 'sre-agent' && /^\d+/.test(slug)) return `sre-agent-${slug.split('-')[0]}`;
  return null;
}

// Global "bring your own" adoption callout. Injected into every delivery guide at
// build time (single source), except pure setup challenges (tier: setup). Authored as a
// GitHub-style alert so it renders as an icon banner on GitHub and the Pages site alike.
// Source READMEs stay untouched.
const BYO_CALLOUT = [
  '> [!IMPORTANT]',
  '> **Use your own environment.**',
  '>',
  '> Work with your **own** application, repository, and data whenever you can. Use the sample only when you need a fallback. Anything you build with your own resources can keep running after the session.',
  '',
].join('\n');

// Insert the callout immediately after the first level-1 heading ("# Title").
// If no H1 is found, prepend it at the very top.
function injectByoCallout(md) {
  const lines = md.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (/^#\s+\S/.test(lines[i])) {
      lines.splice(i + 1, 0, '', BYO_CALLOUT);
      return lines.join('\n');
    }
  }
  return `${BYO_CALLOUT}\n${md}`;
}

function copyGuideForPages(src, dest, moduleId, injectByo = false) {
  if (!fs.existsSync(src)) return false;
  let md = fs.readFileSync(src, 'utf8');
  md = rewriteResourceLinksForPages(md, moduleId);
  if (injectByo) md = injectByoCallout(md);
  fs.writeFileSync(dest, md);
  return true;
}

function rewriteModuleResourceLinksForPages(text, moduleId) {
  return text.replace(
    /(\]\()(?:\.\.\/)+challenges\/([^/)]+)\/README\.md/g,
    (_match, prefix, slug) => {
      const challengeId = challengeIdFromSlug(moduleId, slug);
      return challengeId ? `${prefix}../../challenge.html?id=${challengeId}` : `${prefix}../challenges/${slug}/README.md`;
    },
  ).replace(
    /(\]\()(?:\.\.\/)+(?:README|ATTRIBUTION)\.md/g,
    '$1README.md',
  );
}

function rewriteCopiedMarkdownFiles(dir, moduleId) {
  for (const entry of readDirSafe(dir)) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      rewriteCopiedMarkdownFiles(file, moduleId);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      const md = fs.readFileSync(file, 'utf8');
      fs.writeFileSync(file, rewriteModuleResourceLinksForPages(md, moduleId));
    }
  }
}

function copyModuleResources(moduleId) {
  const dest = path.join(OUT_RESOURCES_DIR, moduleId);
  let copied = false;

  const resourcesSrc = path.join(MODULES_DIR, moduleId, 'resources');
  if (fs.existsSync(resourcesSrc)) {
    fs.cpSync(resourcesSrc, dest, { recursive: true });
    rewriteCopiedMarkdownFiles(dest, moduleId);
    copied = true;
  }

  const setupSrc = path.join(MODULES_DIR, moduleId, 'setup.md');
  if (fs.existsSync(setupSrc)) {
    fs.mkdirSync(dest, { recursive: true });
    fs.copyFileSync(setupSrc, path.join(dest, 'setup.md'));
    copied = true;
  }

  return copied;
}

function readOutcomeConfig() {
  if (!fs.existsSync(OUTCOMES_PATH)) return [];
  const parsed = JSON.parse(fs.readFileSync(OUTCOMES_PATH, 'utf8'));
  return Array.isArray(parsed.outcomes) ? parsed.outcomes : [];
}

function uniq(values) {
  return [...new Set((values || []).filter(Boolean))];
}

/* ─── Cycle detection (DFS) ─────────────────────────────────────────────────*/
function detectCycles(challenges) {
  const adjMap = new Map(challenges.map(c => [c.id, c.prerequisites]));
  const cycles = [];

  function dfs(node, visited, stack) {
    visited.add(node);
    stack.add(node);
    for (const dep of (adjMap.get(node) || [])) {
      if (!adjMap.has(dep)) continue; // already caught as invalid ref
      if (!visited.has(dep)) {
        if (dfs(dep, visited, stack)) return true;
      } else if (stack.has(dep)) {
        cycles.push([...stack, dep]);
        return true;
      }
    }
    stack.delete(node);
    return false;
  }

  const visited = new Set();
  for (const c of challenges) {
    if (!visited.has(c.id)) dfs(c.id, visited, new Set());
  }
  return cycles;
}

/* ─── Main ────────────────────────────────────────────────────────────────── */
function main() {
  let errors   = 0;
  let warnings = 0;
  const allChallenges = [];
  const outcomes = readOutcomeConfig();

  fs.rmSync(OUT_RESOURCES_DIR, { recursive: true, force: true });
  fs.rmSync(OUT_GUIDES_DIR, { recursive: true, force: true });
  fs.mkdirSync(OUT_RESOURCES_DIR, { recursive: true });
  fs.mkdirSync(OUT_DATA_DIR, { recursive: true });

  /* ── 1. Collect all challenges from all modules ── */
  for (const [moduleId, moduleCfg] of Object.entries(MODULE_CONFIG)) {
    copyModuleResources(moduleId);

    const challengesDir = path.join(MODULES_DIR, moduleId, 'challenges');
    const slugDirs = readDirSafe(challengesDir)
      .filter(d => d.isDirectory())
      .map(d => d.name)
      .sort();

    for (const slug of slugDirs) {
      const dir      = path.join(challengesDir, slug);
      const metaPath = path.join(dir, 'meta.yml');

      if (!fs.existsSync(metaPath)) {
        console.warn(`  ! skip ${moduleId}/${slug}: no meta.yml`);
        warnings++;
        continue;
      }

      const raw  = parseMeta(fs.readFileSync(metaPath, 'utf8'));
      const meta = normaliseMeta(raw, moduleId, slug);
      const sourceAttributionError = validateLocalSourceAttribution(meta, metaPath);
      if (sourceAttributionError) {
        console.error(`  ✗ ${sourceAttributionError}`);
        errors++;
      }

      // Warn on missing recommended fields
      const warnFields = ['description', 'title', 'track', 'difficulty', 'duration_minutes'];
      for (const f of warnFields) {
        if (!meta[f]) {
          console.warn(`  ! ${meta.id}: missing field "${f}"`);
          warnings++;
        }
      }

      // Validate track is known for this module
      if (meta.track && moduleCfg.tracks && !moduleCfg.tracks[meta.track]) {
        console.warn(`  ! ${meta.id}: unknown track "${meta.track}" for module "${moduleId}"`);
        warnings++;
      }

      // Copy the delivery guide
      const guideDir = path.join(OUT_GUIDES_DIR, meta.id);
      fs.mkdirSync(guideDir, { recursive: true });
      const hasReadme = copyGuideForPages(path.join(dir, 'README.md'), path.join(guideDir, 'README.md'), moduleId, meta.tier !== 'setup');

      if (!hasReadme) { console.error(`  ✗ ${meta.id}: no README.md (delivery guide)`); errors++; }

      const trackCfg = (moduleCfg.tracks && moduleCfg.tracks[meta.track]) || {};

      allChallenges.push({
        id:                      meta.id,
        title:                   meta.title        || slug,
        module:                  moduleId,
        track:                   meta.track        || '',
        difficulty:              meta.difficulty   || 'beginner',
        duration_minutes:        meta.duration_minutes || null,
        display_order:           meta.display_order,
        description:             meta.description  || '',
        prerequisites:           meta.prerequisites,
        prerequisite_capabilities: meta.prerequisite_capabilities,
        tags:                    meta.tags,
        outcomes:                meta.outcomes,
        personas:                meta.personas,
        business_value:          meta.business_value,
        adoption_stage:          meta.adoption_stage || '',
        app_dependency:          meta.app_dependency,
        emu_compatible:          meta.emu_compatible,
        tier:                    meta.tier,
        references:              meta.references.filter(r => r && r !== 'TODO'),
        source_repo:             meta.source_repo  || '',
        source_path:             meta.source_path  || '',
        source_ref:              CURRENT_SOURCE_REF,
        student_source_repo:     CURRENT_SOURCE_REPO,
        student_source_path:     relativeSourcePath(path.join(dir, 'README.md')),
        license:                 meta.license,
        student_path:            `assets/data/challenges/${meta.id}/README.md`,
        // internal
        _has_student_guide:      hasReadme,
      });
    }
  }

  const moduleOrder = new Map(Object.keys(MODULE_CONFIG).map((id, index) => [id, index]));
  allChallenges.sort((a, b) =>
    (moduleOrder.get(a.module) - moduleOrder.get(b.module))
    || (a.display_order - b.display_order)
    || a.id.localeCompare(b.id)
  );

  /* ── 2. Validate prerequisites ── */
  const allIds = new Set(allChallenges.map(c => c.id));
  const outcomeIds = new Set(outcomes.map(o => o.id));

  for (const c of allChallenges) {
    for (const prereqId of c.prerequisites) {
      if (!allIds.has(prereqId)) {
        console.error(`  ✗ ${c.id}: prerequisites references unknown id "${prereqId}"`);
        errors++;
      }
      for (const outcomeId of c.outcomes) {
        if (!outcomeIds.has(outcomeId)) {
          console.error(`  ✗ ${c.id}: outcomes references unknown id "${outcomeId}"`);
          errors++;
        }
      }
    }

    for (const outcome of outcomes) {
      if (!outcome.id || !outcome.name) {
        console.error('  ✗ outcomes.json: every outcome needs id and name');
        errors++;
      }
      for (const challengeId of outcome.challenge_ids || []) {
        if (!allIds.has(challengeId)) {
          console.error(`  ✗ outcome "${outcome.id}": challenge_ids references unknown id "${challengeId}"`);
          errors++;
        }
      }
    }
  }

  /* ── 3. Detect cycles ── */
  const cycles = detectCycles(allChallenges);
  for (const cycle of cycles) {
    console.error(`  ✗ cycle detected: ${cycle.join(' → ')}`);
    errors++;
  }

  if (errors > 0) {
    console.error(`\n✗ build failed: ${errors} error(s), ${warnings} warning(s). Fix errors above.`);
    process.exit(1);
  }

  /* ── 4. Enrich challenges with outcome journey membership ── */
  const challengeById = new Map(allChallenges.map(c => [c.id, c]));
  for (const outcome of outcomes) {
    for (const challengeId of outcome.challenge_ids || []) {
      const challenge = challengeById.get(challengeId);
      if (!challenge) continue;
      challenge.outcomes = uniq([...(challenge.outcomes || []), outcome.id]);
      challenge.personas = uniq([...(challenge.personas || []), ...(outcome.personas || [])]);
      challenge.business_value = uniq([...(challenge.business_value || []), ...(outcome.business_value || [])]);
    }
  }

  /* ── 5. Build modules metadata ── */
  const modules = Object.entries(MODULE_CONFIG).map(([moduleId, cfg]) => {
    const moduleChallenges = allChallenges.filter(c => c.module === moduleId);
    const trackSet         = {};

    for (const c of moduleChallenges) {
      if (!c.track) continue;
      if (!trackSet[c.track]) trackSet[c.track] = 0;
      trackSet[c.track]++;
    }

    const tracks = Object.entries(cfg.tracks || {}).map(([trackId, trackCfg]) => ({
      id:              trackId,
      name:            trackCfg.name,
      description:     trackCfg.description,
      challenge_count: trackSet[trackId] || 0,
    }));

    return {
      id:              moduleId,
      name:            cfg.name,
      description:     cfg.description,
      color:           cfg.color,
      icon:            cfg.icon,
      challenge_count: moduleChallenges.length,
      tracks,
    };
  });

  const outputOutcomes = outcomes.map(o => {
    const challengeIds = (o.challenge_ids || []).filter(id => allIds.has(id));
    const totalMinutes = challengeIds.reduce((sum, id) => {
      const c = challengeById.get(id);
      return sum + (c && c.duration_minutes ? c.duration_minutes : 0);
    }, 0);
    return Object.assign({}, o, {
      challenge_count: challengeIds.length,
      duration_minutes: totalMinutes,
    });
  });

  /* ── 6. Build dependency graph ── */
  const graphNodes = allChallenges.map(c => ({
    id:     c.id,
    title:  c.title,
    module: c.module,
    track:  c.track,
    tier:   c.tier,
  }));
  const graphEdges = [];
  for (const c of allChallenges) {
    for (const prereqId of c.prerequisites) {
      if (allIds.has(prereqId)) {
        graphEdges.push({ from: prereqId, to: c.id });
      }
    }
  }

  /* ── 7. Strip internal fields before writing ── */
  const outputChallenges = allChallenges.map(c => {
    const out = Object.assign({}, c);
    delete out._has_student_guide;
    return out;
  });

  /* ── 8. Write outputs ── */
  fs.mkdirSync(OUT_DATA_DIR, { recursive: true });

  const platform = {
    generated_at: new Date().toISOString(),
    modules,
    outcomes: outputOutcomes,
    challenges: outputChallenges,
  };
  fs.writeFileSync(
    path.join(OUT_DATA_DIR, 'platform.json'),
    JSON.stringify(platform, null, 2),
  );

  const graph = { nodes: graphNodes, edges: graphEdges };
  fs.writeFileSync(
    path.join(OUT_DATA_DIR, 'dependency-graph.json'),
    JSON.stringify(graph, null, 2),
  );

  const totalChallenges = allChallenges.length;
  console.log(`✓ built platform.json  (modules: ${modules.length}, outcomes: ${outputOutcomes.length}, challenges: ${totalChallenges})`);
  console.log(`✓ built dependency-graph.json  (nodes: ${graphNodes.length}, edges: ${graphEdges.length})`);
  console.log(`✓ copied delivery guides → ${path.relative(ROOT, OUT_GUIDES_DIR)}`);
  if (warnings > 0) console.warn(`  ${warnings} warning(s) — review above`);
}

main();

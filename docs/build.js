#!/usr/bin/env node
/**
 * Agentic DevOps — build step (dependency-free, Node core only).
 *
 * Reads every  modules/<moduleId>/challenges/<slug>/meta.yml  as the single
 * source of truth and emits site-consumable data + copied guides under docs/assets/data/.
 *
 *   node docs/build.js
 *
 * Outputs:
 *   docs/assets/data/platform.json                       — full catalog (modules + challenges)
 *   docs/assets/data/dependency-graph.json               — prereq graph (nodes + edges)
 *   docs/assets/data/challenges/<id>/README.md           — student guide copy
 *   docs/assets/data/challenges/<id>/COACH.md            — coach guide copy
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
    description: 'Master enterprise GitHub: planning, governance, security, and automation across a full SDLC.',
    color: '#0969da',
    icon: 'icon-ghec.svg',
    tracks: {
      'developer-flow':   { name: 'Developer Flow',       description: 'Issues, pull requests, Codespaces, and developer ergonomics at scale.' },
      'admin-governance': { name: 'Admin & Governance',   description: 'Org structure, policies, SAML/SSO, audit logs, and enterprise compliance.' },
      'security':         { name: 'Security',             description: 'Code scanning, secret scanning, Dependabot, and supply-chain protection.' },
      'automation-ai':    { name: 'Automation & AI',      description: 'Actions, REST/GraphQL, webhooks, GitHub Apps, and AI-assisted workflows.' },
    },
  },
  ghas: {
    name: 'GitHub Advanced Security',
    description: 'Deep-dive security: exploit a vulnerable app, then fix it using GHAS tooling.',
    color: '#cf222e',
    icon: 'icon-ghas.svg',
    tracks: {
      'security': { name: 'Security', description: 'SAST, secret scanning, Dependabot, and hands-on Juice Shop exploitation + remediation.' },
    },
  },
  ghaw: {
    name: 'GitHub Agentic Workflows',
    description: 'Build, compose, and harden AI agent workflows on top of GitHub Actions.',
    color: '#8250df',
    icon: 'icon-ghaw.svg',
    tracks: {
      'hello-agent':              { name: 'Hello, Agent', description: 'First agents: scheduled briefings, safe outputs, and basic triggers.' },
      'repo-concierge':           { name: 'Repo Concierge', description: 'Event-driven automation: issue triage, PR review, and slash commands.' },
      'continuous-intelligence': { name: 'Continuous Intelligence', description: 'Multi-workflow coordination, MCP tools, custom engines, and advanced patterns.' },
      'production-patterns':      { name: 'Production Patterns', description: 'Battle-tested agents from the Agent Factory — remix for your repo and ship.' },
    },
  },
  'sre-agent': {
    name: 'SRE Agent',
    description: 'End-to-end agentic pipeline: from issue triage to Azure SRE incident response.',
    color: '#1a7f37',
    icon: 'icon-agentic-devops.svg',
    tracks: {
      'agentic-lifecycle': { name: 'Agentic Lifecycle', description: 'A linear journey through agent-driven DevOps: plan, build, deploy, monitor, and recover.' },
    },
  },
};

/* ─── Paths ──────────────────────────────────────────────────────────────── */
const ROOT           = path.resolve(__dirname, '..');
const MODULES_DIR    = path.join(ROOT, 'modules');
const OUT_DATA_DIR   = path.join(__dirname, 'assets', 'data');
const OUT_GUIDES_DIR = path.join(OUT_DATA_DIR, 'challenges');

/* ─── Minimal YAML parser ────────────────────────────────────────────────────
 * Handles only the locked meta.yml contract: scalar key-value pairs, block
 * lists, inline comments. NOT a general parser — intentional.
 * ─────────────────────────────────────────────────────────────────────────── */
function parseMeta(text) {
  const out          = {};
  let currentListKey = null;

  for (const raw of text.split(/\r?\n/)) {
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

    if (rest === '' || rest === '[]') {
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

/* ─── Field normalisation ───────────────────────────────────────────────────
 * Maps legacy GHEC field names to the platform contract so old-style meta.yml
 * files (pre-migration) don't hard-fail during the porting phase.
 * ─────────────────────────────────────────────────────────────────────────── */
function normaliseMeta(raw, moduleId, slug) {
  const m = Object.assign({}, raw);

  // id: legacy GHEC files use bare "ch01"; prefix with module if not prefixed.
  if (!m.id) m.id = `${moduleId}-${slug}`;
  if (!String(m.id).includes('-')) m.id = `${moduleId}-${m.id}`;

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
  if (!Array.isArray(m.success_criteria))      m.success_criteria = [];
  if (!Array.isArray(m.tags))                  m.tags = [];
  if (!Array.isArray(m.provision_creates))     m.provision_creates = [];
  if (!Array.isArray(m.references))            m.references = [];

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

function copyIfExists(src, dest) {
  if (fs.existsSync(src)) { fs.copyFileSync(src, dest); return true; }
  return false;
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

  /* ── 1. Collect all challenges from all modules ── */
  for (const [moduleId, moduleCfg] of Object.entries(MODULE_CONFIG)) {
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

      // Copy student + coach guides
      const guideDir = path.join(OUT_GUIDES_DIR, meta.id);
      fs.mkdirSync(guideDir, { recursive: true });
      const hasReadme = copyIfExists(path.join(dir, 'README.md'), path.join(guideDir, 'README.md'));
      const hasCoach  = copyIfExists(path.join(dir, 'COACH.md'),  path.join(guideDir, 'COACH.md'));

      if (!hasReadme) { console.warn(`  ! ${meta.id}: no README.md (student guide)`); warnings++; }
      if (!hasCoach)  { console.warn(`  ! ${meta.id}: no COACH.md (coach guide)`);   warnings++; }

      const trackCfg = (moduleCfg.tracks && moduleCfg.tracks[meta.track]) || {};

      allChallenges.push({
        id:                      meta.id,
        title:                   meta.title        || slug,
        module:                  moduleId,
        track:                   meta.track        || '',
        difficulty:              meta.difficulty   || 'beginner',
        duration_minutes:        meta.duration_minutes || null,
        description:             meta.description  || '',
        prerequisites:           meta.prerequisites,
        prerequisite_capabilities: meta.prerequisite_capabilities,
        success_criteria:        meta.success_criteria,
        tags:                    meta.tags,
        app_dependency:          meta.app_dependency,
        emu_compatible:          meta.emu_compatible,
        tier:                    meta.tier,
        references:              meta.references.filter(r => r && r !== 'TODO'),
        source_repo:             meta.source_repo  || '',
        source_path:             meta.source_path  || '',
        license:                 meta.license,
        student_path:            `assets/data/challenges/${meta.id}/README.md`,
        coach_path:              `assets/data/challenges/${meta.id}/COACH.md`,
        // internal
        _has_student_guide:      hasReadme,
        _has_coach_guide:        hasCoach,
      });
    }
  }

  /* ── 2. Validate prerequisites ── */
  const allIds = new Set(allChallenges.map(c => c.id));

  for (const c of allChallenges) {
    for (const prereqId of c.prerequisites) {
      if (!allIds.has(prereqId)) {
        console.error(`  ✗ ${c.id}: prerequisites references unknown id "${prereqId}"`);
        errors++;
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

  /* ── 4. Build modules metadata ── */
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

  /* ── 5. Build dependency graph ── */
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

  /* ── 6. Strip internal fields before writing ── */
  const outputChallenges = allChallenges.map(c => {
    const out = Object.assign({}, c);
    delete out._has_student_guide;
    delete out._has_coach_guide;
    return out;
  });

  /* ── 7. Write outputs ── */
  fs.mkdirSync(OUT_DATA_DIR, { recursive: true });

  const platform = {
    generated_at: new Date().toISOString(),
    modules,
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
  console.log(`✓ built platform.json  (modules: ${modules.length}, challenges: ${totalChallenges})`);
  console.log(`✓ built dependency-graph.json  (nodes: ${graphNodes.length}, edges: ${graphEdges.length})`);
  console.log(`✓ copied student/coach guides → ${path.relative(ROOT, OUT_GUIDES_DIR)}`);
  if (warnings > 0) console.warn(`  ${warnings} warning(s) — review above`);
}

main();

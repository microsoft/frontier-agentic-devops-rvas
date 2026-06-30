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
    description: 'Master enterprise GitHub: planning, governance, security, and automation across a full SDLC.',
    color: '#0969da',
    icon: 'icon-ghec.svg',
    tracks: {
      'developer-flow':   { name: 'Developer Flow',       description: 'Issues, pull requests, Codespaces, and developer ergonomics at scale.' },
      'admin-governance': { name: 'Admin & Governance',   description: 'Org structure, policies, SAML/SSO, audit logs, and enterprise compliance.' },
      'security':         { name: 'Security',             description: 'Code scanning, secret scanning, Dependabot, and supply-chain protection.' },
      'automation-ai':    { name: 'Automation & AI',      description: 'Actions, REST/GraphQL, webhooks, GitHub Apps, and AI-assisted workflows.' },
      'migration':        { name: 'Migration',            description: 'Move repos, history, and metadata from Azure DevOps, Bitbucket, GitLab, and legacy VCS into GitHub Enterprise Cloud.' },
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
    description: 'Use Azure SRE Agent to investigate Azure signals, connect evidence to source, and drive governed remediation.',
    color: '#1a7f37',
    icon: 'icon-agentic-devops.svg',
    tracks: {
      'azure-sre-agent': { name: 'Azure SRE Agent', description: 'A focused journey through setup, service onboarding, alert investigation, code-context RCA, and governed remediation.' },
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

function rewriteResourceLinksForPages(text, moduleId) {
  const moduleResources = `resources/${moduleId}/`;
  return text.replace(
    /(\]\()(https:\/\/microsoft\.github\.io\/resources\/|(?:\.\.\/)+[Rr]esources\/|\/[Rr]esources\/|(?:\.\/)?[Rr]esources\/)/g,
    `$1${moduleResources}`,
  ).replace(
    /(\]\()(?:\.\.\/)+setup\.md/g,
    '$1resources/ghas/setup.md',
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

function copyGuideForPages(src, dest, moduleId) {
  if (!fs.existsSync(src)) return false;
  const md = fs.readFileSync(src, 'utf8');
  fs.writeFileSync(dest, rewriteResourceLinksForPages(md, moduleId));
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
    /(\]\()(?:\.\.\/)+(?:README|COACH|ATTRIBUTION)\.md/g,
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
      const hasReadme = copyGuideForPages(path.join(dir, 'README.md'), path.join(guideDir, 'README.md'), moduleId);
      const hasCoach  = copyGuideForPages(path.join(dir, 'COACH.md'),  path.join(guideDir, 'COACH.md'), moduleId);

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
    delete out._has_coach_guide;
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
  console.log(`✓ copied student/coach guides → ${path.relative(ROOT, OUT_GUIDES_DIR)}`);
  if (warnings > 0) console.warn(`  ${warnings} warning(s) — review above`);
}

main();

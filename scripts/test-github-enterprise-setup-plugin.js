'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..');
const marketplace = JSON.parse(fs.readFileSync(path.join(root, '.github/plugin/marketplace.json'), 'utf8'));
const entry = marketplace.plugins.find((plugin) => plugin.name === 'github-enterprise-setup');
const pluginRoot = path.resolve(root, entry.source);
const manifest = JSON.parse(fs.readFileSync(path.join(pluginRoot, 'plugin.json'), 'utf8'));
const skillRoot = path.join(pluginRoot, 'skills', 'github-enterprise-setup');

test('marketplace resolves a portable skills-only package inside the repository', () => {
  assert(pluginRoot.startsWith(`${root}${path.sep}`));
  assert.equal(manifest.name, entry.name);
  assert.equal(manifest.$schema, 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json');
  const allowedFields = new Set([
    '$schema', 'name', 'version', 'description', 'author', 'homepage',
    'repository', 'license', 'keywords', 'extensions',
  ]);
  for (const field of Object.keys(manifest)) {
    assert(allowedFields.has(field), `Unsupported Agent Plugins manifest field: ${field}`);
  }
  assert.match(manifest.version, /^\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?$/);
  assert.deepEqual(fs.readdirSync(path.join(pluginRoot, 'skills')), ['github-enterprise-setup']);
  assert(!fs.existsSync(path.join(pluginRoot, 'mcp.json')));
  assert(!fs.existsSync(path.join(pluginRoot, 'com.github.copilot')));
  assert.equal(fs.readFileSync(path.join(pluginRoot, 'LICENSE'), 'utf8'), fs.readFileSync(path.join(root, 'LICENSE'), 'utf8'));
});

test('the development skill resolves to the canonical package source', () => {
  const localSkill = path.join(root, '.agents/skills/github-enterprise-setup');
  assert.equal(fs.realpathSync(localSkill), fs.realpathSync(skillRoot));
  const instruction = fs.readFileSync(path.join(localSkill, 'SKILL.md'), 'utf8');
  assert.match(instruction, new RegExp(`^name: ${entry.name}$`, 'm'));
});

test('all runtime reference pointers resolve inside the installed package', () => {
  const markdown = [
    path.join(skillRoot, 'SKILL.md'),
    ...fs.readdirSync(path.join(skillRoot, 'references')).map((name) => path.join(skillRoot, 'references', name)),
  ];
  const references = new Set();
  for (const file of markdown) {
    assert(fs.realpathSync(file).startsWith(`${pluginRoot}${path.sep}`), `External package dependency: ${file}`);
    const content = fs.readFileSync(file, 'utf8');
    for (const match of content.matchAll(/\breferences\/[\w./-]+\.md\b/g)) references.add(path.resolve(skillRoot, match[0]));
    for (const [, href] of content.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
      if (/^[a-z][a-z\d+.-]*:|^#/i.test(href)) continue;
      references.add(path.resolve(path.dirname(file), href.split('#')[0]));
    }
  }
  assert(references.size > 0, 'Missing bundled reference pointers');
  for (const reference of references) {
    assert(fs.realpathSync(reference).startsWith(`${pluginRoot}${path.sep}`), `Reference escapes package: ${reference}`);
  }
});

test('installation instructions name the published marketplace entry', () => {
  const install = `copilot plugin install ${entry.name}@${marketplace.name}`;
  for (const relative of ['README.md', 'plugins/github-enterprise-setup/README.md', 'docs/github-setup-guide.html']) {
    const content = fs.readFileSync(path.join(root, relative), 'utf8');
    assert(content.includes(install), `${relative}: wrong plugin install command`);
    assert(content.includes('copilot plugin marketplace add microsoft/frontier-agentic-devops-rvas'), `${relative}: missing marketplace registration`);
  }
});

test('relocated workflow evaluations remain readable and have unique IDs', () => {
  const evaluations = JSON.parse(fs.readFileSync(path.join(skillRoot, 'evals/evals.json'), 'utf8'));
  assert.equal(evaluations.skill_name, entry.name);
  assert(evaluations.evals.length >= 19, 'Lost existing workflow evaluations');
  assert.equal(new Set(evaluations.evals.map((evaluation) => evaluation.id)).size, evaluations.evals.length);
});

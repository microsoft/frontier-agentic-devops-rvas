'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { validateWorkflowLock } = require('./check-agentic-workflow-locks');

const sha = 'a'.repeat(40);

function lock({ compiler = 'v0.91.11', runtime = compiler, ref = sha, manifestSha = sha } = {}) {
  return [
    `# gh-aw-metadata: ${JSON.stringify({ compiler_version: compiler })}`,
    `# gh-aw-manifest: ${JSON.stringify({ actions: [{
      repo: 'github/gh-aw-actions/setup', version: runtime, sha: manifestSha,
    }] })}`,
    'jobs:',
    '  activation:',
    '    steps:',
    `      - uses: github/gh-aw-actions/setup@${ref} # ${runtime}`,
    '        env:',
    `          GH_AW_COMPILED_VERSION: "${compiler}"`,
    '  agent:',
    '    steps:',
    `      - uses: github/gh-aw-actions/setup@${ref} # ${runtime}`,
    '        env:',
    `          GH_AW_COMPILED_VERSION: ${compiler}`,
  ].join('\n');
}

test('accepts coherent locks at and above the provenance minimum', () => {
  for (const compiler of ['v0.91.10', 'v0.91.11', 'v1.2.2']) {
    assert.doesNotThrow(() => validateWorkflowLock(lock({ compiler })));
  }
});

test('rejects compilers without required provenance', () => {
  assert.throws(() => validateWorkflowLock(lock({ compiler: 'v0.90.1' })), /lacks required provenance/);
});

test('rejects a runtime bump without recompilation, including changes to only one job', () => {
  assert.throws(() => validateWorkflowLock(lock({ ref: 'b'.repeat(40) })), /differs from the compiled manifest/);
  const partial = lock().replace(`setup@${sha}`, `setup@${'b'.repeat(40)}`);
  assert.throws(() => validateWorkflowLock(partial), /differs from the compiled manifest/);
});

test('rejects a runtime manifest version different from its compiler', () => {
  assert.throws(() => validateWorkflowLock(lock({ runtime: 'v1.0.1' })), /must match compiler/);
});

test('rejects missing provenance metadata or unpinned setup runtimes', () => {
  assert.throws(() => validateWorkflowLock('jobs: {}'), /Missing gh-aw-metadata/);
  assert.throws(() => validateWorkflowLock(lock({ manifestSha: 'v0.91.11', ref: 'v0.91.11' })), /full commit SHA/);
  assert.throws(() => validateWorkflowLock(lock().replaceAll('uses:', 'unused:')), /differs from the compiled manifest/);
});

test('rejects inconsistent runtime compiler declarations', () => {
  const stale = lock().replace('GH_AW_COMPILED_VERSION: v0.91.11', 'GH_AW_COMPILED_VERSION: v0.90.1');
  assert.throws(() => validateWorkflowLock(stale), /must match metadata/);
});

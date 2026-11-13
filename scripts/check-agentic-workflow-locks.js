'use strict';

const fs = require('node:fs');
const path = require('node:path');

const setupAction = 'github/gh-aw-actions/setup';
const minimumCompiler = [0, 91, 10];

function readHeader(text, name) {
  const prefix = `# ${name}: `;
  const line = text.split('\n').find(line => line.startsWith(prefix));
  if (!line) throw new Error(`Missing ${name}; regenerate with gh aw compile.`);
  return JSON.parse(line.slice(prefix.length));
}

function validateWorkflowLock(text) {
  const metadata = readHeader(text, 'gh-aw-metadata');
  const manifest = readHeader(text, 'gh-aw-manifest');
  const compiler = metadata.compiler_version;
  const match = /^v(\d+)\.(\d+)\.(\d+)$/.exec(compiler);
  if (!match) throw new Error(`Invalid compiler version: ${compiler}.`);
  const parts = match.slice(1).map(Number);
  let comparison = 0;
  for (let i = 0; i < parts.length && comparison === 0; i++) {
    comparison = parts[i] - minimumCompiler[i];
  }
  if (comparison < 0) {
    throw new Error(`Compiler ${compiler} lacks required provenance; use gh-aw v0.91.10 or newer.`);
  }

  const setups = (manifest.actions || []).filter(action => action.repo === setupAction);
  if (setups.length !== 1 || setups[0].version !== compiler) {
    throw new Error(`Setup manifest must match compiler ${compiler}; regenerate with gh aw compile.`);
  }
  const setup = setups[0];
  if (!/^[a-f0-9]{40}$/.test(setup.sha)) {
    throw new Error('Setup runtime must be pinned to a full commit SHA.');
  }
  const refs = [...text.matchAll(/^\s*(?:-\s+)?uses:\s+github\/gh-aw-actions\/setup@([^\s#]+)/gm)];
  if (!refs.length || refs.some(ref => ref[1] !== setup.sha)) {
    throw new Error('Setup runtime differs from the compiled manifest; regenerate with gh aw compile.');
  }
  const versions = [...text.matchAll(/^\s*GH_AW_COMPILED_VERSION:\s*["']?(v[\d.]+)["']?\s*$/gm)];
  if (!versions.length || versions.some(version => version[1] !== compiler)) {
    throw new Error(`Runtime compiler versions must match metadata ${compiler}.`);
  }
}

if (require.main === module) {
  const directory = path.resolve(__dirname, '../.github/workflows');
  const files = fs.readdirSync(directory).filter(file => file.endsWith('.lock.yml')).sort();
  if (!files.length) {
    console.error('No agentic workflow locks found.');
    process.exitCode = 1;
  }
  for (const file of files) {
    try {
      validateWorkflowLock(fs.readFileSync(path.join(directory, file), 'utf8'));
      console.log(`OK ${file}`);
    } catch (error) {
      console.error(`${file}: ${error.message}`);
      process.exitCode = 1;
    }
  }
}

module.exports = { validateWorkflowLock };

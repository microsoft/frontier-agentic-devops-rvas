'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '../..');
const entrypoint = path.join(root, 'scripts/github-enterprise-wizard.sh');
const catalog = JSON.parse(fs.readFileSync(path.join(__dirname, 'catalog.json'), 'utf8'));

// This shim has no network client. Unexpected endpoints fail rather than reaching gh.
const fakeGh = `#!${process.execPath}
'use strict';
const fs = require('node:fs');
const crypto = require('node:crypto');
const args = process.argv.slice(2);
const read = name => JSON.parse(fs.readFileSync(process.env[name], 'utf8'));
const state = read('WIZARD_FAKE_STATE');
const calls = read('WIZARD_FAKE_CALLS');
const value = flag => args.includes(flag) ? args[args.indexOf(flag) + 1] : undefined;
const method = value('--method');
const host = value('--hostname');
const endpoint = args.find((arg, i) => (arg === 'graphql' || arg.startsWith('/')) && args[i - 1] !== '--hostname');
const input = args.includes('--input') ? fs.readFileSync(0, 'utf8') : '';
let body;
try { body = input ? JSON.parse(input) : null; }
catch { process.stderr.write('invalid JSON input\\n'); process.exit(90); }
calls.push({args, method, host, endpoint, body, ghHost: process.env.GH_HOST});
fs.writeFileSync(process.env.WIZARD_FAKE_CALLS, JSON.stringify(calls));
function reply(status, json) {
  fs.writeFileSync(process.env.WIZARD_FAKE_STATE, JSON.stringify(state));
  const link = (state.links || {})[method + ' ' + endpoint];
  process.stdout.write('HTTP/2.0 ' + status + ' Fake\\r\\ncontent-type: application/json\\r\\n' +
    (link ? 'Link: ' + link + '\\r\\n' : '') + '\\r\\n' + JSON.stringify(json) + '\\n');
  if (status >= 400) {
    process.stderr.write('gh: ' + (json.message || 'request failed') + ' (HTTP ' + status + ')\\n');
    process.exit(1);
  }
  process.exit(0);
}
if (args[0] === 'aw') {
  if (!state.compiler) { process.stderr.write('gh: unknown command "aw"\\n'); process.exit(1); }
  if (args[1] === '--version') { process.stderr.write(state.compiler.version + '\\n'); process.exit(0); }
  if (args[1] === 'compile' && /^[a-z0-9-]+$/.test(args[2])) {
    fs.writeFileSync('.github/workflows/' + args[2] + '.lock.yml', state.compiler.lock);
    process.exit(0);
  }
  process.stderr.write('fake gh-aw: unexpected command\\n'); process.exit(90);
}
if (args[0] !== 'api' || !args.includes('--include') || !host ||
    host !== process.env.GH_HOST || (input && value('--input') !== '-')) {
  process.stderr.write('fake gh: expected host-scoped gh api --include --input -\\n'); process.exit(90);
}
const key = method + ' ' + endpoint;
if (state.failures[key]) {
  const messages = {403: 'Resource not accessible by personal access token', 404: 'Not Found', 422: 'Validation Failed', 502: 'Bad Gateway'};
  reply(state.failures[key], {message: messages[state.failures[key]] || 'Request failed'});
}
if (endpoint === '/user' && method === 'GET') reply(200, {login: state.actor});
if (endpoint === 'graphql') {
  if (/^\\s*mutation/.test(body.query)) {
    const org = body.variables.input.login;
    state.orgs.push(org); state.resources['/orgs/' + org] = {login: org};
    for (const owner of body.variables.input.adminLogins) {
      state.resources['/orgs/' + org + '/memberships/' + owner] = {
        role: 'admin', state: state.ownerInvitationPending ? 'pending' : 'active',
      };
    }
    reply(200, {data: {createEnterpriseOrganization: {organization: {login: org}, enterprise: {id: state.enterpriseId}}}});
  }
  reply(200, {data: {viewer: {login: state.actor}, enterprise: {id: state.enterpriseId, slug: 'acme',
    organizations: {nodes: state.orgs.map(login => ({login})), pageInfo: {hasNextPage: false, endCursor: null}}}}});
}
if (method === 'GET' && Object.hasOwn(state.resources, endpoint)) reply(200, state.resources[endpoint]);
const bare = endpoint && endpoint.split('?')[0];
if (method === 'GET' && Object.hasOwn(state.resources, bare)) reply(200, state.resources[bare]);
if (method === 'GET' && /^\\/orgs\\/[^/]+\\/(members|outside_collaborators|repos|hooks|audit-log|packages|code-security\\/configurations)$/.test(bare)) reply(200, []);
if (method === 'GET' && /^\\/orgs\\/[^/]+\\/installations$/.test(bare)) reply(200, {total_count: 0, installations: []});
if (method === 'GET' && /^\\/organizations\\/[^/]+\\/settings\\/billing\\/usage$/.test(bare)) reply(200, {usageItems: []});
if (method === 'GET' && /\\/copilot\\/billing$/.test(bare)) reply(200, {seat_management_setting: 'assign_selected', public_code_suggestions: 'block'});
if (method === 'GET' && /\\/copilot\\/billing\\/seats$/.test(bare)) reply(200, {seats: state.seats});
if (method === 'POST' && /\\/copilot\\/billing\\/selected_users$/.test(bare)) {
  state.seats.push(...body.selected_usernames.map(login => ({assignee: {login}, pending_cancellation_date: null})));
  reply(201, {seats_created: body.selected_usernames.length});
}
if (method === 'GET' && /\\/actions\\/workflows\\/[^/]+\\/runs$/.test(bare)) reply(200, {workflow_runs: state.runs});
if (method === 'POST' && /\\/actions\\/workflows\\/[^/]+\\/dispatches$/.test(bare)) {
  state.runs.push({id: 42, head_sha: 'head1', actor: {login: state.actor}, event: 'workflow_dispatch', status: 'completed', conclusion: 'success'});
  reply(204, {});
}
if (method === 'GET' && /\\/actions\\/runs\\/42$/.test(bare)) reply(200, {id: 42, status: 'completed', conclusion: 'success'});
if (method === 'GET' && /^\\/repos\\/[^/]+\\/[^/]+\\/commits\\//.test(bare)) {
  const source = bare.split('/').slice(2, 4).join('/');
  const ref = decodeURIComponent(bare.split('/').slice(5).join('/'));
  const sha = (state.actionCommits || {})[source + '@' + ref];
  if (sha) reply(200, {sha});
}
if (method === 'GET' && /\\/commits\\/main$/.test(bare)) reply(200, {sha: 'head1'});
if (method === 'GET' && /\\/contents\\//.test(bare)) {
  const file = state.files[bare];
  if (file !== undefined) {
    const sha = crypto.createHash('sha1').update(Buffer.concat([Buffer.from('blob ' + Buffer.byteLength(file) + '\\0'), Buffer.from(file)])).digest('hex');
    reply(200, {type: 'file', sha, content: Buffer.from(file).toString('base64'), encoding: 'base64'});
  }
  reply(404, {message: 'Not Found'});
}
if (method === 'GET' && /\\/git\\/ref\\/heads\\/main$/.test(bare)) reply(200, {object: {sha: 'head1'}});
if (method === 'GET' && /\\/git\\/commits\\/head1$/.test(bare)) reply(200, {tree: {sha: 'tree1'}});
if (method === 'POST' && /\\/git\\/blobs$/.test(bare)) {
  const sha = 'blob' + Object.keys(state.blobs).length;
  state.blobs[sha] = body.content; reply(201, {sha});
}
if (method === 'POST' && /\\/git\\/trees$/.test(bare)) { state.tree = body.tree; reply(201, {sha: 'tree2'}); }
if (method === 'POST' && /\\/git\\/commits$/.test(bare)) reply(201, {sha: 'commit2'});
if (method === 'POST' && /\\/git\\/refs$/.test(bare)) {
  state.resources[bare.replace(/\\/refs$/, '/ref/') + body.ref.replace(/^refs\\//, '')] = {object: {sha: body.sha}};
  reply(201, {ref: body.ref, object: {sha: body.sha}});
}
if (method === 'PATCH' && /\\/git\\/refs\\/heads\\/main$/.test(bare)) {
  for (const file of state.tree) state.files[bare.split('/git/')[0] + '/contents/' + file.path] = state.blobs[file.sha];
  reply(200, {object: {sha: body.sha}});
}
if (method === 'GET' && /\\/pulls$/.test(bare)) reply(200, state.prs);
if (method === 'POST' && /\\/pulls$/.test(bare)) {
  const pr = {number: state.prs.length + 1, ...body}; state.prs.push(pr); reply(201, pr);
}
if (method === 'POST' && /\\/orgs\\/[^/]+\\/repos$/.test(bare)) {
  const org = bare.split('/')[2];
  state.resources['/repos/' + org + '/' + body.name] = {...body, default_branch: 'main'};
  reply(201, state.resources['/repos/' + org + '/' + body.name]);
}
if (method === 'POST' && /^\\/repos\\/[^/]+\\/[^/]+\\/generate$/.test(bare)) {
  const repo = '/repos/' + body.owner + '/' + body.name;
  state.resources[repo] = {name: body.name, visibility: body.private ? 'private' : 'public', default_branch: 'main'};
  reply(201, state.resources[repo]);
}
if (method === 'POST' && /\\/teams$/.test(bare)) {
  const slug = body.name.toLowerCase().replace(/ /g, '-');
  state.resources[bare + '/' + slug] = {...body, slug}; reply(201, {...body, slug});
}
if (method === 'POST' && /\\/labels$/.test(bare)) {
  state.resources[bare + '/' + encodeURIComponent(body.name)] = body; reply(201, body);
}
if (method === 'PATCH' && /\\/runner-groups\\/\\d+$/.test(bare)) {
  const collection = state.resources[bare.replace(/\\/\\d+$/, '')];
  const group = collection.runner_groups.find(group => group.id === Number(bare.split('/').at(-1)));
  if (!group) reply(404, {message: 'Not Found'});
  Object.assign(group, body); reply(200, group);
}
if (method === 'PUT' && /\\/environments\\/[^/]+$/.test(bare)) {
  state.resources[bare] = {
    name: decodeURIComponent(bare.split('/').at(-1)),
    deployment_branch_policy: body.deployment_branch_policy,
    protection_rules: [
      {type: 'wait_timer', wait_timer: body.wait_timer || 0},
      {type: 'required_reviewers', prevent_self_review: body.prevent_self_review || false,
       reviewers: (body.reviewers || []).map(reviewer => ({type: reviewer.type, reviewer: {id: reviewer.id}}))},
    ],
  };
  reply(200, state.resources[bare]);
}
if (method === 'PATCH' && /\\/code-quality\\/setup$/.test(bare) && state.asyncQuality) {
  state.resources[bare] = {...state.resources[bare], ...body};
  reply(202, {run_id: 43});
}
if (method === 'PATCH' || method === 'PUT') {
  state.resources[bare] = {...(state.resources[bare] || {}), ...body};
  if (/\\/memberships\\//.test(bare)) state.resources[bare].state = 'active';
  reply(200, state.resources[bare]);
}
if (method === 'GET') reply(404, {message: 'Not Found'});
reply(422, {message: 'Unexpected offline endpoint: ' + key});
`;

function config() {
  return {
    schema_version: 1, host: 'github.com', actor: 'alice',
    enterprise: {slug: 'acme', identity: 'personal'},
    defaults: {packages: ['workspace'], repository_visibility: 'private', settings: {}},
    organizations: [{
      login: 'acme-org', create: false, adopt: true, owners: ['alice'], teams: [],
      repositories: [{name: 'service', adopt: true, stack: 'none'}],
    }],
  };
}

function fixture(t, configuration = config()) {
  const directory = fs.mkdtempSync(path.join(__dirname, '.wizard-test-'));
  t.after(() => fs.rmSync(directory, {recursive: true, force: true}));
  // Keep approval hashes stable when another task edits the implementation.
  const snapshotScripts = path.join(directory, 'snapshot', 'scripts');
  const snapshotHome = path.join(snapshotScripts, 'github-enterprise-wizard');
  fs.mkdirSync(snapshotHome, {recursive: true});
  const snapshotEntrypoint = path.join(snapshotScripts, 'github-enterprise-wizard.sh');
  fs.copyFileSync(entrypoint, snapshotEntrypoint);
  for (const name of ['lib', 'packages', 'templates', 'catalog.json', 'validate.jq']) {
    fs.cpSync(path.join(__dirname, name), path.join(snapshotHome, name), {recursive: true});
  }
  const bin = path.join(directory, 'bin');
  fs.mkdirSync(bin);
  fs.writeFileSync(path.join(bin, 'gh'), fakeGh, {mode: 0o700});
  const configFile = path.join(directory, 'config.json');
  const stateFile = path.join(directory, 'fake-state.json');
  const callsFile = path.join(directory, 'calls.json');
  const planFile = path.join(directory, 'plan.json');
  const runDirectory = path.join(directory, 'run');
  const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));
  const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
  write(configFile, configuration);
  write(callsFile, []);
  write(stateFile, {
    actor: 'alice', enterpriseId: 'E1', orgs: ['acme-org'], failures: {}, links: {}, seats: [], runs: [],
    actionCommits: {}, asyncQuality: false, ownerInvitationPending: false,
    files: {}, blobs: {}, tree: [], prs: [],
    resources: {
      '/orgs/acme-org': {login: 'acme-org', default_repository_permission: 'read'},
      '/orgs/acme-org/memberships/alice': {role: 'admin', state: 'active'},
      '/repos/acme-org/service': {name: 'service', visibility: 'private', default_branch: 'main'},
    },
  });
  const env = {
    PATH: `${bin}:${process.env.PATH}`, HOME: directory, TMPDIR: directory,
    LC_ALL: 'C', GH_CONFIG_DIR: directory, GH_HOST: 'blocked.invalid',
    WIZARD_FAKE_STATE: stateFile, WIZARD_FAKE_CALLS: callsFile,
  };
  function command(args, input) {
    const result = spawnSync('/bin/bash', [snapshotEntrypoint, ...args], {
      cwd: directory, env, input, encoding: 'utf8', timeout: 120000,
    });
    assert.ifError(result.error);
    return result;
  }
  function shell(script, args = [], input) {
    const result = spawnSync('/bin/bash', ['-c', script, 'wizard-test', ...args], {
      cwd: directory, env, input, encoding: 'utf8', timeout: 5000,
    });
    assert.ifError(result.error);
    return result;
  }
  function success(result, expected = 0) {
    assert.equal(result.status, expected, `${result.stdout}\n${result.stderr}`);
    return result;
  }
  function incompleteOrReady(result) {
    assert.ok([0, 3].includes(result.status), `${result.stdout}\n${result.stderr}`);
    return result;
  }
  function plan() {
    success(command(['plan', '--config', configFile, '--output', planFile]));
    return json(planFile);
  }
  return {
    directory, configFile, planFile, runDirectory, command, shell, success, incompleteOrReady, plan, json, write,
    calls: () => json(callsFile),
    state: () => json(stateFile),
    changeState: edit => { const state = json(stateFile); edit(state); write(stateFile, state); },
    saveConfig: value => write(configFile, value),
    apply: digest => command(['apply', '--plan', planFile, '--run', runDirectory, '--approve', digest]),
    resume: digest => command(['resume', '--run', runDirectory, '--approve', digest]),
    ledger: () => json(path.join(runDirectory, 'ledger.json')).actions,
  };
}

function mutations(calls) {
  return calls.filter(call => call.method && call.method !== 'GET' &&
    !(call.endpoint === 'graphql' && /^\s*query\b/.test(call.body.query)));
}

function repositoryAction(plan) {
  const action = plan.actions.find(action => action.kind === 'ensure' && action.read_path === '/repos/acme-org/service' && action.desired.name);
  assert.ok(action, 'repository action must exist');
  return action;
}

test('help and catalog run offline and list every package', t => {
  const f = fixture(t);
  for (const args of [[], ['help'], ['--help']]) {
    const result = f.success(f.command(args));
    for (const command of ['init', 'doctor', 'plan', 'apply', 'resume', 'verify', 'status', 'catalog']) {
      assert.match(result.stdout, new RegExp(`\\b${command}\\b`));
    }
  }
  assert.deepEqual(JSON.parse(f.success(f.command(['catalog'])).stdout), catalog);
  assert.deepEqual(f.calls(), []);
});

test('unknown commands and missing option values fail before API calls', t => {
  const f = fixture(t);
  for (const args of [['delete'], ['plan', '--config'], ['init', '--output', '--plain'],
    ['plan', '--config', '--output', 'plan.json'], ['apply'], ['status'], ['doctor', '--surprise']]) {
    assert.notEqual(f.command(args).status, 0);
  }
  assert.deepEqual(f.calls(), []);
});

test('init saves a private config without API calls or approval', t => {
  const f = fixture(t);
  const output = path.join(f.directory, 'interview.json');
  const input = ['github.com', 'alice', 'acme', 'personal', 'workspace', '', 'acme-org',
    'no', 'yes', 'alice', '', 'no', 'no', 'no', '', 'yes'].join('\n') + '\n';
  f.success(f.command(['init', '--output', output], input));
  const saved = f.json(output);
  assert.equal(saved.actor, 'alice');
  assert.equal(saved.organizations[0].login, 'acme-org');
  assert.equal(fs.statSync(output).mode & 0o777, 0o600);
  assert.deepEqual(f.calls(), []);
  assert.notEqual(f.command(['init', '--output', output], input).status, 0);
  assert.deepEqual(f.json(output), saved);
});

test('init EOF and refusal never leave a configuration', t => {
  const f = fixture(t);
  const output = path.join(f.directory, 'interview.json');
  assert.notEqual(f.command(['init', '--output', output], 'github.com\n').status, 0);
  assert.equal(fs.existsSync(output), false);
  const input = ['github.com', 'alice', 'acme', 'personal', 'workspace', '', 'acme-org',
    'no', 'yes', 'alice', '', 'no', 'no', 'no', '', 'no'].join('\n') + '\n';
  assert.notEqual(f.command(['init', '--output', output], input).status, 0);
  assert.equal(fs.existsSync(output), false);
  assert.deepEqual(f.calls(), []);
});

test('prompt input families reject bad attempts and accept corrected values', t => {
  const f = fixture(t);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/config.sh');
  const cases = [
    ['wizard_prompt_required Value', '   \nactual command\n', 'actual command'],
    ["wizard_prompt_identifier host Value '' help", ` HTTPS://github.com \n${'a'.repeat(64)}.ghe.com\n GITHUB.COM \n`, 'github.com'],
    ["wizard_prompt_identifier enterprise Value '' help", 'https://github.com/enterprises/acme\n enterprise_slug \n', 'enterprise_slug'],
    ["wizard_prompt_identifier repo Value '' help '[\"Service\"]'", '.\nfoo..bar\nservice\nother\n', 'other'],
    ["wizard_prompt_list users Value '' help true", ' , , \nalice@example.com\nalice,ALICE\n alice,bob \n', 'alice,bob'],
    ["wizard_prompt_list users Value '' help", `${'a'.repeat(101)}\nalice--dev\nalice_emu\n`, 'alice_emu'],
    ["wizard_prompt_list slugs Value '' help", '@acme/dev\nDev,dev\n dev-platform \n', 'dev-platform'],
    ["wizard_prompt_list labels Value '' help", `${'a'.repeat(51)}\na/b\nBug,bug\nbug,customer issue\n`, 'bug,customer issue'],
    ["wizard_prompt_checked Value '' help '$answer|test(\"^[0-6]$\")'", '-1\n1.5\n7\n 0 \n', '0'],
    ["wizard_prompt_path Value '' help '[\"agents/reviewer.md\"]'", '../agent.md\n.git/config\nC:\\file.md\nagent%2e.md\nagents/reviewer.md\nagents/other.md\n', 'agents/other.md'],
    ['wizard_prompt_ref Value main', 'feature//bad\nbranch.lock\nbranch with spaces\nfeature/good\n', 'feature/good'],
    ['wizard_prompt_bool Value', '\nmaybe\n YES \n', 'true'],
    ['wizard_prompt_bool Value', ' FALSE \n', 'false'],
    ["wizard_choose Value false help '[{\"value\":\"false\",\"label\":\"No\"},{\"value\":\"true\",\"label\":\"Yes\"}]'", '0\n99\n YES \n', 'true'],
    ["wizard_choose Value 2 help '[{\"value\":\"2\",\"label\":\"2\"},{\"value\":\"1\",\"label\":\"1\"}]'", '\n', '2'],
    ["wizard_choose Value 2 help '[{\"value\":\"2\",\"label\":\"2\"},{\"value\":\"1\",\"label\":\"1\"}]'", '1\n', '1'],
    ["wizard_choose Value true help '[{\"value\":\"true\",\"label\":\"true\"},{\"value\":\"yes\",\"label\":\"yes\"}]'", 'yes\n', 'yes'],
    ["wizard_select_packages '[]'", 'unknown-package\n COPILOT \n', '["copilot","workspace"]'],
    ['wizard_select_pilots', '\nunknown\nissue-triage,summaries\n', '["issue-triage","summaries"]'],
    ['wizard_prompt Value', 'bad\x7fvalue\nvalid\n', 'valid'],
    ['wizard_prompt Value', `ghp_${'a'.repeat(20)}\nvalid\n`, 'valid'],
  ];
  for (const [body, input, expected] of cases) {
    const result = f.success(f.shell(
      `source "$1"; ${body} || exit $?; printf '%s' "$WIZARD_REPLY"`, [library], input,
    ));
    assert.equal(result.stdout, expected, body);
  }
  assert.deepEqual(f.calls(), []);
});

test('invalid input is not journaled and replayed answers advance exactly once', t => {
  const f = fixture(t);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/config.sh');
  const journal = path.join(f.directory, 'navigation.json');
  const answers = [
    {key: JSON.stringify({kind: 'text', title: 'Login: ', options: ''}), answer: 'alice'},
    {key: JSON.stringify({kind: 'text', title: 'Enterprise: ', options: ''}), answer: 'acme'},
  ];
  f.write(journal, {answers, cursor: 0, replay_until: 0, back: false});
  f.success(f.shell(
    'source "$1"; WIZARD_INTERVIEW_DIR="$2"; WIZARD_PLAIN=true; wizard_guided() { return 0; }; ' +
    "wizard_prompt_identifier user 'Login: ' '' help",
    [library, f.directory], 'bad/email\nalice\n',
  ));
  assert.deepEqual(f.json(journal).answers, answers);
  assert.equal(f.json(journal).cursor, 1);
  f.write(journal, {answers, cursor: 0, replay_until: 2, back: false});
  f.success(f.shell(
    'source "$1"; WIZARD_INTERVIEW_DIR="$2"; ' +
    "wizard_prompt_identifier user 'Login: ' '' help && wizard_prompt_required 'Enterprise: '",
    [library, f.directory],
  ));
  assert.deepEqual(f.json(journal).answers, answers);
  assert.equal(f.json(journal).cursor, 2);
});

test('agent sources retry missing files, symlinks and credentials without losing the interview', t => {
  const f = fixture(t);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/config.sh');
  const markdown = path.join(f.directory, 'agent.MD');
  const linked = path.join(f.directory, 'linked.md');
  const credentialFile = path.join(f.directory, 'credential.md');
  fs.writeFileSync(markdown, '# Reviewer\nRead changes and suggest tests.\n');
  fs.symlinkSync(markdown, linked);
  fs.writeFileSync(credentialFile, `ghp_${'a'.repeat(20)}`);
  const result = f.success(f.shell(
    'source "$1"; wizard_prompt_agent_source || exit $?; printf "%s" "$WIZARD_REPLY"', [library],
    [path.join(f.directory, 'missing.md'), linked, credentialFile, markdown].join('\n') + '\n',
  ));
  assert.equal(result.stdout, markdown);
  assert.match(result.stderr, /readable Markdown file/);
  assert.deepEqual(f.calls(), []);
});

test('default enterprise agents require selection and use narrow tool sets', t => {
  const f = fixture(t);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/config.sh');
  const agents = JSON.parse(f.success(f.shell(
    'source "$1"; wizard_default_copilot_agents', [library],
  )).stdout);
  assert.deepEqual(agents.map(agent => agent.path), [
    'agents/security-reviewer.md',
    'agents/ci-investigator.md',
    'agents/test-author.md',
    'agents/documentation-maintainer.md',
  ]);
  for (const agent of agents) {
    assert.match(agent.content, /^---\nname: /);
    assert.match(agent.content, /\ndisable-model-invocation: true\n/);
    assert.match(agent.content, /\nuser-invocable: true\n/);
    assert.doesNotMatch(agent.content, /tools: \["\*"\]/);
  }
  const byPath = Object.fromEntries(agents.map(agent => [agent.path, agent.content]));
  assert.match(byPath['agents/security-reviewer.md'], /tools: \[read, search, "github\/\*"\]/);
  assert.doesNotMatch(byPath['agents/security-reviewer.md'], /^tools: .*edit/m);
  assert.match(byPath['agents/ci-investigator.md'], /tools: \[read, search, execute, "github\/\*"\]/);
  assert.match(byPath['agents/test-author.md'], /tools: \[read, search, edit, execute\]/);
  assert.match(byPath['agents/documentation-maintainer.md'], /tools: \[read, search, edit\]/);
  assert.deepEqual(f.calls(), []);
});

test('enterprise policy adapter covers P0 and P1 controls without guarded network settings', t => {
  const c = config();
  c.enterprise.policies = JSON.parse(fs.readFileSync(path.join(__dirname, 'example.json'), 'utf8')).enterprise.policies;
  c.enterprise.policies.copilot.source_organization = 'acme-org';
  c.organizations[0].packages = ['workspace', 'actions', 'copilot'];
  c.organizations[0].copilot = {
    users: [], teams: [], purchase: false,
    agents: [{path: 'agents/security-reviewer.md', content: '# Security Reviewer\n'}],
  };
  const f = fixture(t, c);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/packages/enterprise.sh');
  const result = f.success(f.shell(
    'source "$1"; wizard_enterprise_actions "$(cat "$2")" | jq -s .', [library, f.configFile],
  ));
  const actions = JSON.parse(result.stdout);
  const ids = new Set(actions.map(action => action.id));
  for (const id of [
    'enterprise:policy:repository-policy',
    'enterprise:policy:pat-inventory',
    'enterprise:policy:pat-policy',
    'enterprise:policy:audit-readiness',
    'enterprise:policy:actions-permissions',
    'enterprise:policy:actions-fork-approval',
    'enterprise:policy:actions-private-forks',
    'enterprise:policy:actions-repository-runners',
    'enterprise:policy:actions-cache',
    'enterprise:policy:codespaces-access:acme-org',
    'enterprise:policy:codespaces-policy',
    'enterprise:policy:ruleset:enterprise-repository-observation',
    'enterprise:policy:offboarding',
    'enterprise:policy:application-policy',
    'enterprise:policy:two-factor-authentication',
    'enterprise:policy:copilot-agent-source',
  ]) assert.ok(ids.has(id), id);
  assert.equal(actions.find(action => action.id === 'enterprise:policy:copilot-agent-source').kind, 'copilot_source');
  assert.equal(actions.find(action => action.id === 'enterprise:policy:codespaces-access:acme-org').kind, 'request');
  assert.equal(actions.find(action => action.id === 'enterprise:policy:two-factor-authentication').kind, 'enterprise_setting');
  assert.ok(actions.filter(action => action.id.startsWith('enterprise:policy:property:')).length >= 4);
  assert.ok(actions.every(action => action.id !== 'enterprise:policy:domains'));
  assert.ok(actions.every(action => !JSON.stringify(action).match(/ip allow|conditional access|private network/i)));
  assert.ok(actions.every(action => !`${action.id} ${action.read_path || ''}`.match(/copilot.*usage|usage-record/i)));
});

test('Copilot source executor resolves the organization ID and verifies the enterprise source', t => {
  const f = fixture(t);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/execute.sh');
  const result = f.success(f.shell(`
    source "$1"
    calls=0
    wizard_api() {
      calls=$((calls+1))
      case "$1 $2 $calls" in
        "GET /enterprises/acme/copilot/custom-agents/source 1") API_STATUS=404; return 2 ;;
        "GET /orgs/acme-org 2") API_STATUS=200; API_JSON='{"id":123,"login":"acme-org"}' ;;
        "PUT /enterprises/acme/copilot/custom-agents/source 3")
          [[ "$3" == '{"organization_id":123,"create_ruleset":true}' ]] || return 2
          API_STATUS=200; API_JSON='{}'
          ;;
        "GET /enterprises/acme/copilot/custom-agents/source 4")
          API_STATUS=200
          API_JSON='{"organization":{"id":123,"login":"acme-org"},"repository":{"full_name":"acme-org/.github-private"}}'
          ;;
        *) return 2 ;;
      esac
    }
    action='{"read_path":"/enterprises/acme/copilot/custom-agents/source","source_organization":"acme-org","create_ruleset":true}'
    ACTION_DATA='{}'
    wizard_apply_copilot_source "$action" false
    jq -cn --arg state "$ACTION_STATE" --arg detail "$ACTION_DETAIL" --argjson data "$ACTION_DATA" \
      '{state:$state,detail:$detail,data:$data}'
  `, [library]));
  const output = JSON.parse(result.stdout);
  assert.equal(output.state, 'ready');
  assert.equal(output.data.organization, 'acme-org');
  assert.equal(output.data.repository, 'acme-org/.github-private');
});

test('confirmed Codespaces and personal-account 2FA writes use supported APIs', t => {
  const f = fixture(t);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/execute.sh');
  const result = f.success(f.shell(`
    source "$1"
    calls=0
    wizard_api() {
      calls=$((calls+1))
      if [[ "$calls" == 1 ]]; then
        [[ "$1" == PUT && "$2" == /orgs/acme-org/codespaces/access ]] || return 2
        [[ "$3" == '{"visibility":"all_members"}' ]] || return 2
        API_STATUS=204; API_JSON='{}'
      else
        [[ "$1" == POST && "$2" == graphql ]] || return 2
        jq -e --arg id E1 '
          .variables.input.enterpriseId==$id and
          .variables.input.settingValue=="ENABLED" and
          (.query|contains("updateEnterpriseTwoFactorAuthenticationRequiredSetting"))
        ' <<<"$3" >/dev/null || return 2
        API_STATUS=200; API_JSON='{"data":{"updateEnterpriseTwoFactorAuthenticationRequiredSetting":{"message":"updated","enterprise":{"id":"E1"}}}}'
      fi
    }
    request='{"apply":{"method":"PUT","path":"/orgs/acme-org/codespaces/access","body":{"visibility":"all_members"}},"success_message":"accepted"}'
    wizard_apply_request "$request" false
    first="$ACTION_STATE"
    WIZARD_ENTERPRISE_ID=E1
    setting='{"setting":"two_factor_authentication_required","value":true}'
    wizard_apply_enterprise_setting "$setting" false
    jq -cn --arg first "$first" --arg second "$ACTION_STATE" --arg detail "$ACTION_DETAIL" \
      '{first:$first,second:$second,detail:$detail}'
  `, [library]));
  const output = JSON.parse(result.stdout);
  assert.equal(output.first, 'ready');
  assert.equal(output.second, 'ready');
  assert.match(output.detail, /two-factor authentication/);
});

test('unconfirmed risky controls and EMU never produce enforcement actions', t => {
  const c = config();
  c.enterprise.identity = 'emu';
  c.enterprise.policies = JSON.parse(fs.readFileSync(path.join(__dirname, 'example.json'), 'utf8')).enterprise.policies;
  c.enterprise.policies.pat.enforcement_confirmed = false;
  c.enterprise.policies.codespaces.enforcement_confirmed = false;
  c.enterprise.policies.offboarding = {
    remove_unaffiliated_users: false, impact_review_required: true, enforcement_confirmed: false,
  };
  c.enterprise.policies.applications.enforcement_confirmed = false;
  c.enterprise.policies.authentication = {
    require_two_factor: false, readiness_review_required: true, enforcement_confirmed: false,
  };
  c.organizations[0].packages = ['workspace', 'actions'];
  const f = fixture(t, c);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/packages/enterprise.sh');
  const actions = JSON.parse(f.success(f.shell(
    'source "$1"; wizard_enterprise_actions "$(cat "$2")" | jq -s .', [library, f.configFile],
  )).stdout);
  const ids = actions.map(action => action.id);
  assert.ok(!ids.includes('enterprise:policy:pat-policy'));
  assert.ok(!ids.includes('enterprise:policy:codespaces-policy'));
  assert.ok(!ids.some(id => id.startsWith('enterprise:policy:codespaces-access:')));
  assert.ok(!ids.includes('enterprise:policy:offboarding'));
  assert.ok(!ids.includes('enterprise:policy:application-policy'));
  assert.ok(!ids.includes('enterprise:policy:two-factor-authentication'));
  assert.ok(!ids.includes('enterprise:policy:domains'));
});

test('shared Copilot profiles and agents stay in the case-insensitive private source repository', t => {
  const c = config();
  c.enterprise.policies = JSON.parse(fs.readFileSync(path.join(__dirname, 'example.json'), 'utf8')).enterprise.policies;
  const org = c.organizations[0];
  org.packages = ['workspace', 'copilot'];
  org.copilot = {users: [], teams: [], purchase: false};
  org.repositories.push({name: '.GITHUB-PRIVATE', visibility: 'private', adopt: true, stack: 'none', files: []});
  const f = fixture(t, c);
  const library = path.join(f.directory, 'snapshot/scripts/github-enterprise-wizard/lib/config.sh');
  const agentFile = path.join(f.directory, 'reviewer.md');
  fs.writeFileSync(agentFile, '# Reviewer\nSuggest tests.\n');
  const result = f.success(f.shell(
    'source "$1"; wizard_customize_config "$(cat "$2")"', [library, f.configFile],
    ['no', 'no', 'no', 'no', 'yes', 'yes', 'Company', 'Use the service starter.',
      agentFile, 'Profile/README.md', 'agents/reviewer.agent.md', ''].join('\n') + '\n',
  ));
  const saved = JSON.parse(result.stdout);
  assert.equal(saved.enterprise.policies.copilot.source_organization, 'acme-org');
  const repositories = saved.organizations[0].repositories;
  assert.equal(repositories.length, 2, 'case variants must not create another private source repository');
  assert.deepEqual(repositories[0].files || [], [], 'member profiles must not be copied into project repositories');
  assert.deepEqual(repositories[1].files, [
    {
      path: 'copilot/managed-settings.json',
      content: '{\n  "model": "auto",\n  "permissions": {\n    "disableBypassPermissionsMode": "disable"\n  },\n  "allowedMcpServers": []\n}\n',
    },
    {path: 'profile/README.md', content: '# Company\n\nUse the service starter.\n'},
  ]);
  assert.equal(saved.organizations[0].copilot.instructions, undefined);
  assert.deepEqual(saved.organizations[0].copilot.agents.map(agent => agent.path), [
    'agents/security-reviewer.md',
    'agents/ci-investigator.md',
    'agents/test-author.md',
    'agents/documentation-maintainer.md',
    'agents/reviewer.agent.md',
  ]);
  assert.equal(
    saved.organizations[0].copilot.agents.find(agent => agent.path === 'agents/reviewer.agent.md').content,
    '# Reviewer\nSuggest tests.\n',
  );
  f.saveConfig(saved);
  const plan = f.plan();
  const content = plan.actions.filter(action => action.kind === 'files');
  assert.ok(content.some(action => action.repo === 'acme-org/.GITHUB-PRIVATE' &&
    action.files.some(file => file.path === 'agents/reviewer.agent.md')));
  assert.ok(!content.some(action => action.repo === 'acme-org/service' &&
    action.files.some(file => file.path === 'profile/README.md' || file.path === 'agents/reviewer.agent.md')));
  assert.deepEqual(mutations(f.calls()), []);
});

test('piped init retries invalid scope values and normalizes feature answers', t => {
  const f = fixture(t);
  const output = path.join(f.directory, 'interview.json');
  const input = [' GITHUB.COM ', ' alice ', 'enterprise_slug', ' PERSONAL ', 'unknown', ' WORKSPACE ', ' PRIVATE ',
    'acme-org', ' FALSE ', ' YES ', 'alice@example.com', ' alice ', 'unknown', '', ' NO ', ' FALSE ',
    ' NO ', '', ' TRUE '].join('\n') + '\n';
  f.success(f.command(['init', '--output', output], input));
  const saved = f.json(output);
  assert.equal(saved.host, 'github.com');
  assert.equal(saved.enterprise.slug, 'enterprise_slug');
  assert.deepEqual(saved.organizations[0].owners, ['alice']);
  assert.deepEqual(saved.organizations[0].packages, ['workspace']);
  assert.deepEqual(f.calls(), []);
});

test('init rejects Copilot purchases without recipients at the purchase question', t => {
  for (const purchase of ['yes', 'no']) {
    const f = fixture(t);
    const output = path.join(f.directory, 'interview.json');
    const answers = ['github.com', 'alice', 'acme', 'personal', 'workspace,copilot', '', 'acme-org',
      'no', 'yes', 'alice', '', 'no', 'no', '', '', purchase];
    if (purchase === 'no') answers.push('no', 'no', 'no', '', 'yes');
    const result = f.command(['init', '--output', output], answers.join('\n') + '\n');
    if (purchase === 'yes') {
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, /Copilot seat purchase needs at least one user login or team slug/);
      assert.doesNotMatch(result.stderr, /Add another organization/);
      assert.equal(fs.existsSync(output), false);
    } else {
      f.success(result);
      assert.deepEqual(f.json(output).organizations[0].copilot, {
        users: [],
        teams: [],
        purchase: false,
        code_review: true,
        mcp: {enabled: true, approved_servers_only: true},
        models: {default_availability: true, kimi: false, fable: false},
        features: {
          github_com: true,
          cli: true,
          cloud_agent: 'selected',
          code_review: true,
          review_effort: 'balanced',
          copilot_approvals: false,
          public_code_suggestions: 'block',
          feedback_collection: false,
          preview_features: false,
        },
      });
    }
    assert.deepEqual(f.calls(), []);
  }
});

test('doctor and plan only read, with host-scoped GraphQL queries', t => {
  const c = config();
  c.host = 'acme.ghe.com';
  const f = fixture(t, c);
  f.success(f.command(['doctor', '--config', f.configFile]));
  const plan = f.plan();
  assert.equal(plan.host, c.host);
  assert.equal(plan.actor, 'alice');
  assert.equal(plan.enterprise_id, 'E1');
  assert.match(plan.digest, /^[a-f0-9]{64}$/);
  assert.deepEqual(mutations(f.calls()), []);
  assert.ok(f.calls().some(call => call.endpoint === 'graphql'));
  for (const call of f.calls()) {
    assert.equal(call.host, c.host);
    assert.equal(call.ghHost, c.host);
    assert.ok(call.args.includes('--include'));
    if (call.body) assert.equal(call.args[call.args.indexOf('--input') + 1], '-');
  }
});

test('actor mismatch stops discovery and mutations', t => {
  const f = fixture(t);
  f.changeState(state => { state.actor = 'mallory'; });
  const result = f.command(['doctor', '--config', f.configFile]);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /identity|actor|match/i);
  assert.deepEqual(f.calls().map(call => call.endpoint), ['/user']);
});

test('apply rejects a changed actor or enterprise identity', t => {
  for (const changed of ['actor', 'enterpriseId']) {
    const f = fixture(t);
    const plan = f.plan();
    f.changeState(state => { state[changed] = changed === 'actor' ? 'mallory' : 'E2'; });
    assert.notEqual(f.apply(plan.digest).status, 0);
    assert.deepEqual(mutations(f.calls()), []);
  }
});

test('invalid configs reject unknown keys, secrets, hosts and injection before discovery', t => {
  const changes = [
    c => { c.typo = true; },
    c => { c.organizations[0].repositories[0].token = 'do-not-save'; },
    c => { c.organizations[0].settings = {password: 'do-not-save'}; },
    c => { c.host = 'https://github.com'; },
    c => { c.actor = '$(touch injected)'; },
    c => { c.organizations[0].login = 'acme-org;touch injected'; },
    c => { c.organizations[0].repositories[0].files = [{path: '../injected', content: 'bad'}]; },
  ];
  for (const change of changes) {
    const c = config();
    change(c);
    const f = fixture(t, c);
    assert.notEqual(f.command(['plan', '--config', f.configFile, '--output', f.planFile]).status, 0);
    assert.deepEqual(f.calls(), []);
    assert.equal(fs.existsSync(f.planFile), false);
    assert.equal(fs.existsSync(path.join(f.directory, 'injected')), false);
  }
});

test('organization defaults merge settings and explicit empty packages override defaults', t => {
  const c = config();
  c.defaults.settings = {default_repository_permission: 'read', members_can_create_public_repositories: false};
  c.organizations[0].settings = {default_repository_permission: 'none'};
  c.organizations.push({login: 'empty-org', create: false, adopt: true, owners: ['alice'], packages: []});
  const f = fixture(t, c);
  f.changeState(state => {
    state.orgs.push('empty-org');
    state.resources['/orgs/empty-org'] = {login: 'empty-org'};
  });
  const plan = f.plan();
  const first = plan.config.organizations[0];
  assert.deepEqual(first.packages, ['workspace']);
  assert.deepEqual(first.settings, {default_repository_permission: 'none', members_can_create_public_repositories: false});
  assert.deepEqual(plan.config.organizations[1].packages, []);
  assert.ok(!plan.actions.some(action => action.org === 'empty-org' && action.kind !== 'ensure'));
  assert.ok(!plan.actions.some(action => action.org === 'empty-org' && action.read_path !== '/orgs/empty-org'));
});

test('403 is blocked and cannot be mistaken for a missing repository', t => {
  const f = fixture(t);
  f.changeState(state => { state.failures['GET /repos/acme-org/service'] = 403; });
  const plan = f.plan();
  assert.equal(repositoryAction(plan).operation, 'blocked');
  const result = f.apply(plan.digest);
  f.success(result, 3);
  assert.equal(f.ledger()[repositoryAction(plan).id].status, 'pending');
  assert.deepEqual(mutations(f.calls()), []);
});

test('404 can plan creation but never mutates during planning', t => {
  const c = config();
  c.organizations[0].repositories[0].adopt = false;
  const f = fixture(t, c);
  f.changeState(state => { delete state.resources['/repos/acme-org/service']; });
  const plan = f.plan();
  assert.equal(repositoryAction(plan).operation, 'create');
  assert.deepEqual(mutations(f.calls()), []);
});

test('apply requires exact approval and rejects a tampered plan', t => {
  const f = fixture(t);
  const plan = f.plan();
  const before = f.calls().length;
  assert.notEqual(f.apply('0'.repeat(64)).status, 0);
  assert.notEqual(f.command(['apply', '--plan', f.planFile, '--run', f.runDirectory]).status, 0);
  assert.equal(f.calls().length, before);
  assert.equal(fs.existsSync(f.runDirectory), false);
  plan.actions[0].desired.login = 'changed-org';
  f.write(f.planFile, plan);
  assert.notEqual(f.apply(plan.digest).status, 0);
  assert.equal(f.calls().length, before);
  assert.equal(fs.existsSync(f.runDirectory), false);
});

test('existing settings require adoption and adopted updates preserve unrelated fields', t => {
  for (const adopt of [false, true]) {
    const c = config();
    c.organizations[0].repositories[0].adopt = adopt;
    c.organizations[0].repositories[0].description = 'Approved description';
    const f = fixture(t, c);
    f.changeState(state => {
      state.resources['/repos/acme-org/service'].description = 'Old description';
      state.resources['/repos/acme-org/service'].has_wiki = true;
    });
    const plan = f.plan();
    const action = repositoryAction(plan);
    assert.equal(action.operation, adopt ? 'update' : 'blocked');
    const result = f.apply(plan.digest);
    if (adopt) {
      f.success(result);
      assert.equal(f.state().resources['/repos/acme-org/service'].description, 'Approved description');
      assert.equal(f.state().resources['/repos/acme-org/service'].has_wiki, true);
    } else {
      f.success(result, 3);
      assert.ok(!mutations(f.calls()).some(call => call.endpoint === '/repos/acme-org/service'));
    }
  }
});

test('settings changed after planning reject stale adopted writes', t => {
  const c = config();
  c.organizations[0].repositories[0].description = 'Approved';
  const f = fixture(t, c);
  f.changeState(state => { state.resources['/repos/acme-org/service'].description = 'Before'; });
  const plan = f.plan();
  f.changeState(state => { state.resources['/repos/acme-org/service'].description = 'Concurrent edit'; });
  f.success(f.apply(plan.digest), 2);
  assert.equal(f.ledger()[repositoryAction(plan).id].status, 'failed');
  assert.deepEqual(mutations(f.calls()), []);
});

test('ready runs support apply, status, resume and read-only verify', t => {
  const f = fixture(t);
  const plan = f.plan();
  f.success(f.apply(plan.digest));
  f.success(f.command(['status', '--run', f.runDirectory]));
  f.success(f.resume(plan.digest));
  f.success(f.command(['verify', '--run', f.runDirectory]));
  assert.ok(Object.values(f.ledger()).every(action => action.status === 'ready'));
  assert.deepEqual(mutations(f.calls()), []);
});

test('verify detects drift without repairing it', t => {
  const f = fixture(t);
  const plan = f.plan();
  f.success(f.apply(plan.digest));
  f.changeState(state => { state.resources['/repos/acme-org/service'].visibility = 'public'; });
  f.success(f.command(['verify', '--run', f.runDirectory]), 3);
  assert.equal(f.ledger()[repositoryAction(plan).id].status, 'unverified');
  assert.deepEqual(mutations(f.calls()), []);
});

test('teams, members and labels use approved creation payloads and read-back', t => {
  const c = config();
  c.organizations[0].teams = [{name: 'Platform', slug: 'platform', members: ['alice']}];
  c.organizations[0].repositories[0].labels = [{name: 'needs review', color: '0366d6', description: 'Review requested'}];
  const f = fixture(t, c);
  const plan = f.plan();
  f.success(f.apply(plan.digest));
  const writes = mutations(f.calls());
  assert.ok(writes.some(call => call.endpoint === '/orgs/acme-org/teams' && call.body.name === 'Platform'));
  assert.ok(writes.some(call => call.endpoint === '/orgs/acme-org/teams/platform/memberships/alice' && call.body.role === 'member'));
  assert.ok(writes.some(call => call.endpoint === '/repos/acme-org/service/labels' && call.body.name === 'needs review'));
  assert.ok(Object.values(f.ledger()).every(action => action.status === 'ready'));
});

test('a failed dependency leaves descendants pending and independent actions continue', t => {
  const c = config();
  c.organizations[0].repositories[0].labels = [{name: 'ready', color: '0366d6'}];
  c.organizations.push({login: 'other-org', adopt: true, owners: ['alice']});
  const f = fixture(t, c);
  f.changeState(state => {
    delete state.resources['/repos/acme-org/service'];
    state.failures['POST /orgs/acme-org/repos'] = 422;
    state.orgs.push('other-org');
    state.resources['/orgs/other-org'] = {login: 'other-org'};
    state.resources['/orgs/other-org/memberships/alice'] = {state: 'active', role: 'admin'};
  });
  const plan = f.plan();
  const result = f.apply(plan.digest);
  assert.ok([2, 3].includes(result.status), `${result.stdout}\n${result.stderr}`);
  const ledger = f.ledger();
  assert.ok(['failed', 'unverified'].includes(ledger[repositoryAction(plan).id].status));
  const label = plan.actions.find(action => action.desired && action.desired.name === 'ready');
  assert.equal(ledger[label.id].status, 'pending');
  assert.ok(plan.actions.filter(action => action.org === 'other-org').every(action => ledger[action.id].status === 'ready'));
  assert.ok(!mutations(f.calls()).some(call => call.endpoint.includes('/labels')));
});

test('adopted files open one review PR and resume never duplicates it', t => {
  const c = config();
  c.organizations[0].repositories[0].files = [{path: '.github/CODEOWNERS', content: '* @acme-org/platform\n'}];
  const f = fixture(t, c);
  const plan = f.plan();
  f.success(f.apply(plan.digest), 3);
  const action = plan.actions.find(action => action.kind === 'files');
  assert.equal(f.ledger()[action.id].status, 'pending');
  assert.ok(f.ledger()[action.id].data.pull_request);
  assert.equal(f.state().prs.length, 1);
  const writes = mutations(f.calls());
  assert.ok(writes.some(call => call.endpoint.endsWith('/git/blobs') && call.body.content === '* @acme-org/platform\n'));
  assert.ok(!writes.some(call => call.endpoint.endsWith('/git/refs/heads/main')));
  f.success(f.resume(plan.digest), 3);
  assert.equal(f.state().prs.length, 1);
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/pulls')).length, 1);
  f.changeState(state => { state.files['/repos/acme-org/service/contents/.github/CODEOWNERS'] = '* @acme-org/platform\n'; });
  f.success(f.command(['verify', '--run', f.runDirectory]));
  assert.equal(f.ledger()[action.id].status, 'ready');
});

test('new repositories receive approved initial content without a PR', t => {
  const c = config();
  c.organizations[0].repositories[0].adopt = false;
  const f = fixture(t, c);
  f.changeState(state => { delete state.resources['/repos/acme-org/service']; });
  const plan = f.plan();
  f.success(f.apply(plan.digest));
  assert.equal(f.state().files['/repos/acme-org/service/contents/README.md'], '# service\n');
  assert.deepEqual(f.state().prs, []);
  const update = mutations(f.calls()).find(call => call.endpoint.endsWith('/git/refs/heads/main'));
  assert.ok(update);
  assert.equal(update.body.force, false);
});

test('EMU membership remains a manual IdP handoff', t => {
  const c = config();
  c.enterprise.identity = 'emu';
  c.organizations[0].teams = [{name: 'Platform', slug: 'platform', members: ['alice']}];
  const f = fixture(t, c);
  const plan = f.plan();
  const handoffs = plan.actions.filter(action => action.kind === 'manual');
  assert.ok(handoffs.some(action => /owner/.test(action.id)));
  assert.ok(handoffs.some(action => /member/.test(action.id)));
  f.success(f.apply(plan.digest), 3);
  for (const action of handoffs) assert.equal(f.ledger()[action.id].status, 'pending');
  assert.ok(!mutations(f.calls()).some(call => call.endpoint.includes('/memberships/')));
});

test('node and python starters plan and apply their source, tests and CI offline', t => {
  for (const [stack, required] of [
    ['node', ['package.json', 'src/index.js', 'test/index.test.js', 'scripts/build.js', '.github/workflows/ci.yml']],
    ['python', ['pyproject.toml', 'starter.py', 'test_starter.py', '.github/workflows/ci.yml']],
  ]) {
    const c = config();
    c.defaults.packages.push('actions');
    c.organizations[0].repositories[0].adopt = false;
    c.organizations[0].repositories[0].stack = stack;
    const f = fixture(t, c);
    f.changeState(state => { delete state.resources['/repos/acme-org/service']; });
    const plan = f.plan();
    const content = plan.actions.find(action => action.kind === 'files');
    assert.ok(content);
    for (const name of required) assert.ok(content.files.some(file => file.path === name), `${stack}: ${name}`);
    const result = f.success(f.apply(plan.digest));
    assert.equal(f.ledger()[content.id].status, 'ready', result.stdout + result.stderr);
    for (const file of content.files) {
      assert.equal(f.state().files[`/repos/acme-org/service/contents/${file.path}`], file.content,
        `${stack}: ${file.path}; recorded files: ${Object.keys(f.state().files).join(', ')}\n${result.stdout}\n${result.stderr}`);
    }
    assert.deepEqual(f.state().prs, []);
  }
});

test('a locked run refuses resume without making API calls', t => {
  const f = fixture(t);
  const plan = f.plan();
  f.success(f.apply(plan.digest));
  fs.mkdirSync(path.join(f.runDirectory, '.lock'));
  const before = f.calls().length;
  assert.notEqual(f.resume(plan.digest).status, 0);
  assert.equal(f.calls().length, before);
});

test('runner-group lookup uses the numeric ID and rejects ambiguous matches', t => {
  for (const duplicate of [false, true]) {
    const c = config();
    c.defaults.packages.push('actions');
    c.organizations[0].actions = {runner_groups: [{name: 'Pool', visibility: 'private'}]};
    const f = fixture(t, c);
    f.changeState(state => {
      const groups = [{id: 7, name: 'Pool', visibility: 'all', allows_public_repositories: false}];
      if (duplicate) groups.push({id: 8, name: 'Pool', visibility: 'all'});
      state.resources['/orgs/acme-org/actions/runner-groups'] = {total_count: groups.length, runner_groups: groups};
    });
    const plan = f.plan();
    const group = plan.actions.find(action => action.kind === 'ensure' && action.lookup);
    assert.ok(group);
    assert.equal(group.operation, duplicate ? 'blocked' : 'update');
    f.success(f.apply(plan.digest), 3);
    const writes = mutations(f.calls());
    if (duplicate) {
      assert.deepEqual(writes, []);
      assert.equal(f.ledger()[group.id].status, 'pending');
    } else {
      assert.equal(f.ledger()[group.id].status, 'ready');
      assert.equal(writes.length, 1);
      assert.equal(writes[0].endpoint, '/orgs/acme-org/actions/runner-groups/7');
      assert.equal(writes[0].body.visibility, 'private');
    }
    assert.ok(!f.calls().some(call => (call.endpoint || '').includes('{id}')));
  }
});

test('environment projections preserve unselected reviewers and branch policies on update', t => {
  const c = config();
  c.defaults.packages.push('actions');
  c.organizations[0].repositories[0].environments = [{name: 'production', wait_timer: 10}];
  const f = fixture(t, c);
  f.changeState(state => {
    state.resources['/repos/acme-org/service/environments/production'] = {
      name: 'production', deployment_branch_policy: {protected_branches: false, custom_branch_policies: true},
      protection_rules: [
        {type: 'wait_timer', wait_timer: 30},
        {type: 'required_reviewers', prevent_self_review: true, reviewers: [{type: 'Team', reviewer: {id: 7}}]},
      ],
    };
  });
  const plan = f.plan();
  const environment = plan.actions.find(action => action.read_projection === 'environment');
  assert.ok(environment);
  assert.equal(environment.operation, 'update');
  f.success(f.apply(plan.digest));
  const update = mutations(f.calls()).find(call => call.endpoint.endsWith('/environments/production'));
  assert.ok(update);
  assert.equal(update.body.wait_timer, 10);
  assert.deepEqual(update.body.reviewers, [{type: 'Team', id: 7}]);
  assert.equal(update.body.prevent_self_review, true);
  assert.deepEqual(update.body.deployment_branch_policy, {protected_branches: false, custom_branch_policies: true});
  assert.equal(f.ledger()[environment.id].status, 'ready');
});

test('manual handoff attestation records evidence without claiming API verification', t => {
  const c = config();
  c.organizations[0].manual_handoffs = [{message: 'Verify the existing customer identity provider.'}];
  const f = fixture(t, c);
  const plan = f.plan();
  const manual = plan.actions.find(action => action.kind === 'manual');
  assert.ok(manual);
  f.success(f.apply(plan.digest), 3);
  const evidence = 'https://evidence.example.invalid/change/123';
  f.success(f.command(['attest', '--run', f.runDirectory, '--action', manual.id,
    '--evidence', evidence, '--approve', plan.digest]));
  const attestation = f.ledger()[manual.id];
  assert.equal(attestation.status, 'attested');
  assert.equal(attestation.data.evidence, evidence);
  assert.equal(attestation.data.attested_by, 'alice');
  assert.match(attestation.detail, /not API.verified/i);
  f.success(f.command(['status', '--run', f.runDirectory]));
  f.success(f.command(['verify', '--run', f.runDirectory]));
  assert.equal(f.ledger()[manual.id].status, 'attested');
  assert.deepEqual(mutations(f.calls()), []);
});

test('attestation rejects credentials, query strings, wrong approvals and automated actions', t => {
  const c = config();
  c.organizations[0].manual_handoffs = [{message: 'Verify customer approval.'}];
  const f = fixture(t, c);
  const plan = f.plan();
  const manual = plan.actions.find(action => action.kind === 'manual');
  f.success(f.apply(plan.digest), 3);
  const before = f.calls().length;
  for (const evidence of [
    'http://evidence.example.invalid/change/123',
    'https://user:password@evidence.example.invalid/change/123',
    'https://evidence.example.invalid/change/123?token=credential',
    'https://evidence.example.invalid/change/123\ninjected',
  ]) {
    assert.notEqual(f.command(['attest', '--run', f.runDirectory, '--action', manual.id,
      '--evidence', evidence, '--approve', plan.digest]).status, 0);
  }
  for (const [action, approval] of [[manual.id, 'bad-digest'], [repositoryAction(plan).id, plan.digest]]) {
    assert.notEqual(f.command(['attest', '--run', f.runDirectory, '--action', action,
      '--evidence', 'https://evidence.example.invalid/change/123', '--approve', approval]).status, 0);
  }
  assert.equal(f.calls().length, before);
  assert.equal(f.ledger()[manual.id].status, 'pending');
});

test('selected Copilot seats require explicit purchase and verified read-back', t => {
  const c = config();
  c.defaults.packages.push('copilot');
  c.organizations[0].copilot = {users: ['alice'], teams: [], purchase: true};
  const f = fixture(t, c);
  const plan = f.plan();
  const purchase = plan.actions.find(action => action.kind === 'purchase');
  assert.ok(purchase, 'explicit seat selection must create a purchase action');
  f.incompleteOrReady(f.apply(plan.digest));
  assert.equal(f.ledger()[purchase.id].status, 'ready');
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/copilot/billing/selected_users')).length, 1);
  f.incompleteOrReady(f.resume(plan.digest));
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/copilot/billing/selected_users')).length, 1);
});

test('uncertain purchase response resumes by reading seats, never buying twice', t => {
  const c = config();
  c.defaults.packages.push('copilot');
  c.organizations[0].copilot = {users: ['alice'], teams: [], purchase: true};
  const f = fixture(t, c);
  f.changeState(state => { state.failures['POST /orgs/acme-org/copilot/billing/selected_users'] = 502; });
  const plan = f.plan();
  const purchase = plan.actions.find(action => action.kind === 'purchase');
  assert.ok(purchase);
  f.incompleteOrReady(f.apply(plan.digest));
  assert.equal(f.ledger()[purchase.id].status, 'unverified');
  f.incompleteOrReady(f.resume(plan.digest));
  assert.equal(f.ledger()[purchase.id].status, 'unverified');
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/copilot/billing/selected_users')).length, 1);
  f.changeState(state => { state.seats = [{assignee: {login: 'alice'}, pending_cancellation_date: null}]; });
  f.incompleteOrReady(f.command(['verify', '--run', f.runDirectory]));
  assert.equal(f.ledger()[purchase.id].status, 'ready');
});

test('interrupted dispatching ledgers reconcile purchases and live runs without writes', t => {
  const c = config();
  c.defaults.packages.push('actions', 'copilot');
  c.organizations[0].copilot = {users: ['alice'], teams: [], purchase: true};
  c.organizations[0].repositories[0].workflows = [{workflow: 'ci.yml', ref: 'main'}];
  const f = fixture(t, c);
  const plan = f.plan();
  const purchase = plan.actions.find(action => action.kind === 'purchase');
  const workflow = plan.actions.find(action => action.kind === 'workflow');
  assert.ok(purchase);
  assert.ok(workflow);
  fs.mkdirSync(f.runDirectory);
  fs.copyFileSync(f.planFile, path.join(f.runDirectory, 'plan.json'));
  const actions = Object.fromEntries(plan.actions.map(action => [
    action.id, {status: 'ready', detail: 'Previously verified', data: {}},
  ]));
  actions[purchase.id] = {status: 'dispatching', detail: 'Interrupted purchase', data: {}};
  actions[workflow.id] = {status: 'dispatching', detail: 'Interrupted dispatch', data: {head: 'head1', baseline: []}};
  f.write(path.join(f.runDirectory, 'ledger.json'), {schema_version: 1, actions});
  f.changeState(state => {
    state.seats = [{assignee: {login: 'alice'}, pending_cancellation_date: null}];
    state.runs = [{id: 42, head_sha: 'head1', actor: {login: 'alice'}, status: 'completed', conclusion: 'success'}];
  });
  f.success(f.resume(plan.digest));
  assert.equal(f.ledger()[purchase.id].status, 'ready');
  assert.equal(f.ledger()[workflow.id].status, 'ready');
  assert.deepEqual(mutations(f.calls()), []);
});

test('live workflow records one successful run and resume never redispatches', t => {
  const c = config();
  c.defaults.packages.push('actions');
  c.organizations[0].repositories[0].workflows = [{workflow: 'ci.yml', ref: 'main', inputs: {mode: 'test'}}];
  const f = fixture(t, c);
  const plan = f.plan();
  const workflow = plan.actions.find(action => action.kind === 'workflow');
  assert.ok(workflow);
  f.success(f.apply(plan.digest));
  assert.equal(f.ledger()[workflow.id].status, 'ready');
  f.success(f.resume(plan.digest));
  const dispatches = mutations(f.calls()).filter(call => call.endpoint.endsWith('/dispatches'));
  assert.equal(dispatches.length, 1);
  assert.deepEqual(dispatches[0].body, {ref: 'main', inputs: {mode: 'test'}});
});

test('uncertain workflow dispatch resumes without another paid live run', t => {
  const c = config();
  c.defaults.packages.push('actions');
  c.organizations[0].repositories[0].workflows = [{workflow: 'ci.yml', ref: 'main'}];
  const f = fixture(t, c);
  f.changeState(state => { state.failures['POST /repos/acme-org/service/actions/workflows/ci.yml/dispatches'] = 502; });
  const plan = f.plan();
  const action = plan.actions.find(action => action.kind === 'workflow');
  assert.ok(action);
  f.success(f.apply(plan.digest), 3);
  assert.equal(f.ledger()[action.id].status, 'unverified');
  f.changeState(state => { state.runs = [{id: 42, head_sha: 'head1', actor: {login: 'alice'}, event: 'workflow_dispatch', status: 'completed', conclusion: 'success'}]; });
  f.success(f.resume(plan.digest));
  assert.equal(f.ledger()[action.id].status, 'ready');
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/dispatches')).length, 1);
});

test('every selected catalog package produces an action or explicit handoff', t => {
  const c = config();
  c.defaults.packages = catalog.packages.map(pkg => pkg.id);
  c.organizations[0].repositories = [];
  c.organizations[0].actions = {permissions: {allowed_actions: 'local_only'}};
  const f = fixture(t, c);
  f.changeState(state => {
    state.resources['/orgs/acme-org/actions/permissions'] = {allowed_actions: 'local_only'};
  });
  const plan = f.plan();
  for (const pkg of catalog.packages) {
    assert.ok(plan.actions.some(action => action.package === pkg.id), `${pkg.id} selection must not disappear`);
  }
  for (const action of plan.actions.filter(action => action.kind === 'manual')) {
    assert.equal(typeof action.message, 'string');
    assert.ok(action.message.length > 0);
    assert.ok(action.owner, `${action.id} needs a handoff owner`);
  }
  assert.ok(!plan.actions.some(action => action.kind === 'purchase'), 'package selection alone must not authorize purchases');
  assert.deepEqual(mutations(f.calls()), []);
  f.success(f.apply(plan.digest), 3);
  const ledger = f.ledger();
  for (const action of plan.actions.filter(action => action.kind === 'manual')) {
    assert.equal(ledger[action.id].status, 'pending', `${action.id} must not be reported ready`);
  }
  for (const action of plan.actions.filter(action => action.kind === 'request')) {
    assert.equal(ledger[action.id].status, 'unsupported', `${action.id} needs an honest unsupported status`);
  }
  assert.ok(Object.values(ledger).some(action => action.status !== 'ready'));
});

test('report pagination follows cursor Link headers even when a page has fewer than 100 entries', t => {
  const c = config();
  c.defaults.packages.push('audit');
  c.organizations[0].repositories = [];
  const f = fixture(t, c);
  const plan = f.plan();
  const report = plan.actions.find(action => action.package === 'audit' && action.kind === 'report');
  assert.ok(report);
  const first = report.read_path + '&per_page=100';
  const next = '/orgs/acme-org/audit-log?include=all&after=cursor-2&per_page=100';
  f.changeState(state => {
    state.resources[first] = [{id: 'first-event'}];
    state.resources[next] = [{id: 'second-event'}];
    state.links[`GET ${first}`] = `<https://api.github.com${next}>; rel="next", <https://api.github.com${next}>; rel="last"`;
  });
  f.success(f.apply(plan.digest));
  const recorded = f.ledger()[report.id];
  assert.equal(recorded.status, 'ready');
  assert.deepEqual(f.json(path.join(f.runDirectory, recorded.data.file)), [{id: 'first-event'}, {id: 'second-event'}]);
  assert.deepEqual(f.calls().filter(call => call.endpoint.includes('/audit-log')).map(call => call.endpoint), [first, next]);
  assert.deepEqual(mutations(f.calls()), []);
});

test('pagination rejects foreign and lookalike hosts before issuing the next request', t => {
  for (const host of ['foreign.example.invalid', 'api.github.com.foreign.example.invalid', 'api.github.com@foreign.example.invalid']) {
    const c = config();
    c.defaults.packages.push('audit');
    c.organizations[0].repositories = [];
    const f = fixture(t, c);
    const plan = f.plan();
    const report = plan.actions.find(action => action.package === 'audit' && action.kind === 'report');
    const first = report.read_path + '&per_page=100';
    f.changeState(state => {
      state.resources[first] = [];
      state.links[`GET ${first}`] = `<https://${host}/orgs/acme-org/audit-log?after=stolen>; rel="next"`;
    });
    const result = f.success(f.apply(plan.digest), 2);
    assert.match(result.stderr, /pagination.*host|host.*pagination/i);
    assert.equal(f.ledger()[report.id].status, 'failed');
    assert.deepEqual(f.calls().filter(call => call.endpoint.includes('/audit-log')).map(call => call.endpoint), [first]);
    assert.ok(f.calls().every(call => call.host === 'github.com'));
    assert.deepEqual(mutations(f.calls()), []);
  }
});

test('a repository appearing after planning stays pending without overwrite or content writes', t => {
  const c = config();
  c.organizations[0].repositories[0].adopt = false;
  const f = fixture(t, c);
  f.changeState(state => { delete state.resources['/repos/acme-org/service']; });
  const plan = f.plan();
  const repository = repositoryAction(plan);
  assert.equal(repository.operation, 'create');
  f.changeState(state => {
    state.resources['/repos/acme-org/service'] = {name: 'service', visibility: 'private', default_branch: 'main', description: 'Created by someone else'};
  });
  f.success(f.apply(plan.digest), 3);
  assert.equal(f.ledger()[repository.id].status, 'pending');
  assert.equal(f.state().resources['/repos/acme-org/service'].description, 'Created by someone else');
  assert.deepEqual(mutations(f.calls()), []);
});

test('enterprise organization creation waits for invited owners and resumes without creating again', t => {
  const c = config();
  Object.assign(c.organizations[0], {create: true, adopt: false, billing_email: 'billing@example.invalid', repositories: []});
  const f = fixture(t, c);
  f.changeState(state => {
    state.orgs = [];
    delete state.resources['/orgs/acme-org'];
    delete state.resources['/orgs/acme-org/memberships/alice'];
    state.ownerInvitationPending = true;
  });
  const plan = f.plan();
  const organization = plan.actions.find(action => action.kind === 'organization');
  assert.ok(organization);
  assert.deepEqual(mutations(f.calls()), []);
  f.success(f.apply(plan.digest), 3);
  assert.equal(f.ledger()[organization.id].status, 'pending');
  const creations = mutations(f.calls()).filter(call => call.endpoint === 'graphql');
  assert.equal(creations.length, 1);
  assert.equal(creations[0].body.variables.input.enterpriseId, 'E1');
  assert.deepEqual(creations[0].body.variables.input.adminLogins, ['alice']);
  const beforeVerify = mutations(f.calls()).length;
  f.success(f.command(['verify', '--run', f.runDirectory]), 3);
  assert.equal(mutations(f.calls()).length, beforeVerify);
  f.changeState(state => { state.resources['/orgs/acme-org/memberships/alice'].state = 'active'; });
  f.success(f.resume(plan.digest));
  assert.equal(f.ledger()[organization.id].status, 'ready');
  assert.equal(mutations(f.calls()).filter(call => call.endpoint === 'graphql').length, 1);
});

test('Code Quality 202 setup responses persist and verify the returned live run ID', t => {
  const c = config();
  c.defaults.packages.push('quality');
  c.organizations[0].quality = {state: 'configured', live_analysis: true};
  const f = fixture(t, c);
  f.changeState(state => {
    state.asyncQuality = true;
    state.resources['/repos/acme-org/service/code-quality/setup'] = {state: 'not-configured'};
    state.resources['/repos/acme-org/service/code-quality/findings'] = [];
    state.resources['/repos/acme-org/service/actions/runs/43'] = {id: 43, status: 'completed', conclusion: 'success'};
  });
  const plan = f.plan();
  const run = plan.actions.find(action => action.kind === 'setup_run');
  assert.ok(run);
  f.success(f.apply(plan.digest));
  assert.equal(f.ledger()[run.source_action].data.setup_run_id, 43);
  assert.equal(f.ledger()[run.id].status, 'ready');
  assert.ok(f.calls().some(call => call.method === 'GET' && call.endpoint.endsWith('/actions/runs/43')));
  f.success(f.resume(plan.digest));
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/code-quality/setup')).length, 1);
  f.changeState(state => { state.resources['/repos/acme-org/service/actions/runs/43'].conclusion = 'failure'; });
  f.success(f.command(['verify', '--run', f.runDirectory]), 2);
  assert.equal(f.ledger()[run.id].status, 'failed');
  assert.notEqual(f.command(['attest', '--run', f.runDirectory, '--action', run.id,
    '--evidence', 'https://evidence.example.invalid/change/123', '--approve', plan.digest]).status, 0);
  assert.equal(f.ledger()[run.id].status, 'failed');
});

test('Code Quality evidence can attest an untracked run only after its setup is ready', t => {
  const c = config();
  c.defaults.packages.push('quality');
  c.organizations[0].quality = {state: 'configured', live_analysis: true};
  const f = fixture(t, c);
  f.changeState(state => {
    state.resources['/repos/acme-org/service/code-quality/setup'] = {state: 'configured'};
    state.resources['/repos/acme-org/service/code-quality/findings'] = [];
  });
  const plan = f.plan();
  const run = plan.actions.find(action => action.kind === 'setup_run');
  assert.ok(run);
  f.success(f.apply(plan.digest), 3);
  assert.equal(f.ledger()[run.source_action].status, 'ready');
  assert.equal(f.ledger()[run.source_action].data.setup_run_id, undefined);
  assert.equal(f.ledger()[run.id].status, 'pending');
  const ledgerFile = path.join(f.runDirectory, 'ledger.json');
  const ledger = f.json(ledgerFile);
  ledger.actions[run.source_action].status = 'pending';
  f.write(ledgerFile, ledger);
  const attest = () => f.command(['attest', '--run', f.runDirectory, '--action', run.id,
    '--evidence', 'https://evidence.example.invalid/quality/123', '--approve', plan.digest]);
  assert.notEqual(attest().status, 0);
  assert.equal(f.ledger()[run.id].status, 'pending');
  ledger.actions[run.source_action].status = 'ready';
  f.write(ledgerFile, ledger);
  f.success(attest());
  assert.equal(f.ledger()[run.id].status, 'attested');
  f.success(f.command(['verify', '--run', f.runDirectory]));
  assert.equal(f.ledger()[run.id].status, 'attested');
  assert.deepEqual(mutations(f.calls()), []);
});

test('empty action-policy arrays are cleared and concurrent list additions invalidate approval', t => {
  for (const stale of [false, true]) {
    const c = config();
    c.defaults.packages.push('actions');
    c.organizations[0].actions = {
      selected_actions: {github_owned_allowed: false, verified_allowed: false, patterns_allowed: stale ? ['safe/*'] : []},
    };
    const f = fixture(t, c);
    const endpoint = '/orgs/acme-org/actions/permissions/selected-actions';
    f.changeState(state => {
      state.resources[endpoint] = {github_owned_allowed: false, verified_allowed: false, patterns_allowed: ['old/*']};
    });
    const plan = f.plan();
    const policy = plan.actions.find(action => action.read_path === endpoint);
    assert.ok(policy);
    assert.equal(policy.operation, 'update');
    if (stale) {
      f.changeState(state => { state.resources[endpoint].patterns_allowed.push('concurrent/*'); });
      f.success(f.apply(plan.digest), 2);
      assert.equal(f.ledger()[policy.id].status, 'failed');
      assert.deepEqual(mutations(f.calls()), []);
    } else {
      f.success(f.apply(plan.digest));
      assert.deepEqual(f.state().resources[endpoint].patterns_allowed, []);
      assert.equal(f.ledger()[policy.id].status, 'ready');
    }
  }
});

test('a missing gh-aw compiler produces an explicit pending handoff and no live dispatch', t => {
  const c = config();
  c.defaults.packages.push('actions', 'ghaw');
  c.organizations[0].ghaw = {pilots: ['issue-triage'], engine: 'copilot', run: true};
  const f = fixture(t, c);
  const plan = f.plan();
  const handoff = plan.actions.find(action => action.package === 'ghaw' && action.kind === 'manual');
  assert.ok(handoff);
  assert.match(handoff.message, /compiler|gh-aw/i);
  assert.ok(!plan.actions.some(action => action.package === 'ghaw' && action.kind === 'workflow'));
  assert.ok(f.calls().some(call => call.args[0] === 'aw' && call.args.includes('--version')));
  assert.deepEqual(mutations(f.calls()), []);
  f.success(f.apply(plan.digest), 3);
  assert.equal(f.ledger()[handoff.id].status, 'pending');
  assert.deepEqual(mutations(f.calls()), []);
});

test('ghe.com plans pin standard actions through github.com and customer actions through the tenant', t => {
  const c = config();
  c.host = 'acme.ghe.com';
  c.organizations[0].repositories[0].files = [{
    path: '.github/workflows/customer.yml',
    content: 'name: Customer\non: workflow_dispatch\njobs:\n  check:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: \'actions/checkout@v4\' # standard action\n      - uses: "acme/tool@release/stable" # customer action\n',
  }];
  const f = fixture(t, c);
  const standardSha = 'a'.repeat(40);
  const customerSha = 'b'.repeat(40);
  f.changeState(state => {
    state.actionCommits['actions/checkout@v4'] = standardSha;
    state.actionCommits['acme/tool@release/stable'] = customerSha;
  });
  const plan = f.plan();
  const content = plan.actions.find(action => action.kind === 'files');
  assert.match(content.files[0].content, new RegExp(`actions/checkout@${standardSha}`));
  assert.match(content.files[0].content, new RegExp(`acme/tool@${customerSha}`));
  assert.ok(content.files[0].content.includes(`'actions/checkout@${standardSha}' # standard action`));
  assert.ok(content.files[0].content.includes(`"acme/tool@${customerSha}" # customer action`));
  assert.deepEqual(content.resolved_actions, [
    {action: 'acme/tool', original_ref: 'release/stable', sha: customerSha},
    {action: 'actions/checkout', original_ref: 'v4', sha: standardSha},
  ]);
  const standard = f.calls().find(call => call.endpoint === '/repos/actions/checkout/commits/v4');
  const customer = f.calls().find(call => call.endpoint === '/repos/acme/tool/commits/release%2Fstable');
  assert.equal(standard.host, 'github.com');
  assert.equal(standard.ghHost, 'github.com');
  assert.equal(customer.host, 'acme.ghe.com');
  assert.equal(customer.ghHost, 'acme.ghe.com');
  assert.ok(f.calls().filter(call => ![
    '/repos/actions/checkout/commits/v4', '/repos/acme/tool/commits/release%2Fstable',
  ].includes(call.endpoint)).every(call => call.host === 'acme.ghe.com'));
  assert.deepEqual(mutations(f.calls()), []);
  content.resolved_actions[0].sha = 'c'.repeat(40);
  f.write(f.planFile, plan);
  const before = f.calls().length;
  assert.notEqual(f.apply(plan.digest).status, 0);
  assert.equal(f.calls().length, before);
});

test('unresolved action tags abort planning instead of approving unpinned content', t => {
  const c = config();
  c.organizations[0].repositories[0].files = [{
    path: '.github/workflows/customer.yml',
    content: 'steps:\n  - uses: actions/unknown@v999\n',
  }];
  const f = fixture(t, c);
  const result = f.command(['plan', '--config', f.configFile, '--output', f.planFile]);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /resolve action|unpinned/i);
  assert.equal(fs.existsSync(f.planFile), false);
  assert.deepEqual(mutations(f.calls()), []);
});

test('template generation uses the approved source snapshot and refuses a changed source', t => {
  for (const stale of [false, true]) {
    const c = config();
    Object.assign(c.organizations[0].repositories[0], {adopt: false, template: 'acme/template'});
    const f = fixture(t, c);
    f.changeState(state => {
      delete state.resources['/repos/acme-org/service'];
      state.resources['/repos/acme/template'] = {is_template: true, default_branch: 'main'};
      state.resources['/repos/acme/template/commits/main'] = {sha: 'a'.repeat(40)};
    });
    const plan = f.plan();
    const repository = repositoryAction(plan);
    assert.deepEqual(repository.template_source, {repo: 'acme/template', default_branch: 'main', sha: 'a'.repeat(40)});
    assert.deepEqual(mutations(f.calls()), []);
    if (stale) {
      f.changeState(state => { state.resources['/repos/acme/template/commits/main'].sha = 'b'.repeat(40); });
      f.success(f.apply(plan.digest), 2);
      assert.equal(f.ledger()[repository.id].status, 'failed');
      assert.deepEqual(mutations(f.calls()), []);
    } else {
      f.success(f.apply(plan.digest));
      assert.equal(f.ledger()[repository.id].status, 'ready');
      const generation = mutations(f.calls()).find(call => call.endpoint === '/repos/acme/template/generate');
      assert.ok(generation);
      assert.equal(generation.body.owner, 'acme-org');
      assert.equal(generation.body.name, 'service');
      assert.equal(generation.body.private, true);
    }
  }
});

test('gh-aw stderr version and compiled locks enter the approved plan before a live pilot', t => {
  const c = config();
  c.defaults.packages.push('actions', 'ghaw');
  c.organizations[0].ghaw = {pilots: ['issue-triage'], engine: 'copilot', run: true};
  const f = fixture(t, c);
  const lock = 'name: Offline issue triage\non: workflow_dispatch\npermissions:\n  contents: read\njobs:\n  triage:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo offline\n';
  f.changeState(state => { state.compiler = {version: 'gh-aw version v0.72.1', lock}; });
  const plan = f.plan();
  const compiled = plan.actions.find(action => action.package === 'ghaw' && action.kind === 'files');
  assert.ok(compiled);
  assert.equal(compiled.compiler_version, 'gh-aw version v0.72.1');
  assert.ok(compiled.files.some(file => file.path.endsWith('.md')));
  assert.ok(compiled.files.some(file => file.path.endsWith('.lock.yml') && file.content === lock));
  const live = plan.actions.find(action => action.id === `${compiled.id}:live`);
  assert.ok(live);
  assert.equal(live.kind, 'workflow');
  assert.deepEqual(live.depends_on, [compiled.id]);
  assert.deepEqual(mutations(f.calls()), []);
  f.success(f.apply(plan.digest), 3);
  assert.equal(f.ledger()[compiled.id].status, 'pending');
  assert.equal(f.ledger()[live.id].status, 'pending');
  assert.ok(!mutations(f.calls()).some(call => call.endpoint.endsWith('/dispatches')));
  f.changeState(state => {
    for (const file of compiled.files) state.files[`/repos/${compiled.repo}/contents/${file.path}`] = file.content;
  });
  f.success(f.command(['verify', '--run', f.runDirectory]), 3);
  assert.equal(f.ledger()[compiled.id].status, 'ready');
  f.success(f.resume(plan.digest));
  assert.equal(f.ledger()[live.id].status, 'ready');
  assert.equal(mutations(f.calls()).filter(call => call.endpoint.endsWith('/dispatches')).length, 1);
});

test('ledger persistence failure aborts conditional dispatch before any write marker', t => {
  const f = fixture(t);
  fs.mkdirSync(f.runDirectory);
  const ledgerFile = path.join(f.runDirectory, 'ledger.json');
  f.write(ledgerFile, {schema_version: 1, actions: {}});
  const marker = path.join(f.directory, 'dispatched');
  const lib = path.join(f.directory, 'snapshot', 'scripts', 'github-enterprise-wizard', 'lib');
  const result = f.shell(`
    source "$1"
    source "$2"
    WIZARD_RUN="$3"
    marker="$4"
    wizard_write_json() { return 2; }
    dispatch() {
      wizard_ledger_set probe dispatching "Persist intent before dispatch." '{}'
      printf 'write attempted\\n' >"$marker"
    }
    if dispatch; then exit 0; else exit 1; fi
  `, [path.join(lib, 'api.sh'), path.join(lib, 'execute.sh'), f.runDirectory, marker]);
  f.success(result, 2);
  assert.match(result.stderr, /persist run state|stopping before further changes/i);
  assert.equal(fs.existsSync(marker), false);
  assert.deepEqual(f.json(ledgerFile), {schema_version: 1, actions: {}});
  assert.deepEqual(f.calls(), []);
});

test('replaced repository IDs reject settings and resumed content writes', t => {
  for (const content of [false, true]) {
    const c = config();
    if (content) c.organizations[0].repositories[0].files = [{path: 'NOTICE', content: 'Approved content\n'}];
    const f = fixture(t, c);
    f.changeState(state => { state.resources['/repos/acme-org/service'].id = 7; });
    const plan = f.plan();
    const repository = repositoryAction(plan);
    assert.equal(String(repository.resource_id), '7');
    if (content) {
      const files = plan.actions.find(action => action.kind === 'files');
      assert.equal(String(files.file_repository_id), '7');
      f.success(f.apply(plan.digest), 3);
      const before = mutations(f.calls()).length;
      f.changeState(state => { state.resources['/repos/acme-org/service'].id = 8; });
      f.success(f.resume(plan.digest), 2);
      assert.equal(f.ledger()[files.id].status, 'failed');
      assert.equal(mutations(f.calls()).length, before);
    } else {
      f.changeState(state => { state.resources['/repos/acme-org/service'].id = 8; });
      f.success(f.apply(plan.digest), 2);
      assert.equal(f.ledger()[repository.id].status, 'failed');
      assert.deepEqual(mutations(f.calls()), []);
    }
  }
});

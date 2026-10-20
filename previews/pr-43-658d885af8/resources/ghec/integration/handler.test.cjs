const assert = require('node:assert/strict')
const crypto = require('node:crypto')
const { once } = require('node:events')
const test = require('node:test')
const { verifySignature, createAppJwt, apiRequest, handleEvent, createReceiver } = require('./handler.cjs')

const config = { repository: 'example/test', installationId: '123', webhookSecret: 'local-test-only', label: 'triage' }
const payload = { action: 'opened', repository: { full_name: config.repository }, installation: { id: 123 }, issue: { number: 7 } }
const sign = body => 'sha256=' + crypto.createHmac('sha256', config.webhookSecret).update(body).digest('hex')
const ok = () => new Response('[]', { status: 200 })

test('rejects missing, short, malformed, and incorrect signatures without throwing', () => {
  const raw = Buffer.from(JSON.stringify(payload))
  assert.equal(verifySignature(config.webhookSecret, raw, sign(raw)), true)
  for (const signature of [undefined, '', 'sha256=x', 'sha256=' + 'g'.repeat(64), 'sha256=' + '0'.repeat(64)]) {
    assert.equal(verifySignature(config.webhookSecret, raw, signature), false)
  }
  assert.equal(verifySignature(config.webhookSecret, Buffer.from('{}'), sign(raw)), false)
})

test('signs a short-lived App JWT', () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 })
  const token = createAppJwt('42', privateKey)
  const [header, payload, signature] = token.split('.')
  assert.equal(crypto.verify('RSA-SHA256', Buffer.from(`${header}.${payload}`), publicKey, Buffer.from(signature, 'base64url')), true)
  const claims = JSON.parse(Buffer.from(payload, 'base64url'))
  assert.equal(claims.iss, '42')
  assert.equal(claims.exp - claims.iat, 600)
})

test('replay and concurrent delivery address the same issue and label', async () => {
  const labels = new Set()
  const calls = []
  const deps = {
    mintToken: async () => 'test-token',
    fetchImpl: async (url, options) => {
      calls.push(url)
      JSON.parse(options.body).labels.forEach(label => labels.add(label))
      return ok()
    }
  }
  await Promise.all([handleEvent('issues', payload, config, deps), handleEvent('issues', payload, config, deps)])
  assert.deepEqual(calls, Array(2).fill('https://api.github.com/repos/example/test/issues/7/labels'))
  assert.deepEqual([...labels], ['triage'])
  assert.deepEqual(await handleEvent('issues', { ...payload, action: 'closed' }, config, deps), { handled: false })
  await assert.rejects(handleEvent('issues', { ...payload, installation: { id: 999 } }, config, deps), /unexpected event target/)
})

test('a lost response retries the same target without duplicating the label', async () => {
  const labels = new Set()
  let calls = 0
  const deps = {
    mintToken: async () => 'test-token',
    sleep: async () => {},
    fetchImpl: async (url, options) => {
      JSON.parse(options.body).labels.forEach(label => labels.add(label))
      if (++calls === 1) throw new Error('response lost after write')
      return ok()
    }
  }
  await handleEvent('issues', payload, config, deps)
  assert.equal(calls, 2)
  assert.deepEqual([...labels], ['triage'])
})

test('honors short Retry-After values, bounds retries, and refuses long waits', async () => {
  const delays = []
  let calls = 0
  await apiRequest('/test', 'test-token', {}, {
    fetchImpl: async () => ++calls === 1 ? new Response('', { status: 429, headers: { 'Retry-After': '1' } }) : ok(),
    sleep: async delay => delays.push(delay)
  })
  assert.deepEqual(delays, [1000])
  calls = 0
  await assert.rejects(apiRequest('/test', 'test-token', {}, {
    fetchImpl: async () => { calls++; return new Response('', { status: 503 }) },
    sleep: async () => {}
  }), /destination HTTP 503/)
  assert.equal(calls, 3)
  await assert.rejects(apiRequest('/test', 'test-token', {}, {
    fetchImpl: async () => new Response('', { status: 429, headers: { 'Retry-After': '60' } }),
    sleep: async () => assert.fail('must not retry before Retry-After')
  }), /retry later/)
})

test('HTTP receiver verifies raw bytes before parsing and logs success only after the update', async t => {
  const logs = []
  let failing = false
  let mutations = 0
  const receiver = createReceiver(config, {
    mintToken: async () => 'test-token',
    fetchImpl: async () => {
      mutations++
      return failing ? new Response('', { status: 500 }) : ok()
    },
    sleep: async () => {},
    log: entry => logs.push(JSON.parse(entry))
  })
  receiver.listen(0, '127.0.0.1')
  await once(receiver, 'listening')
  t.after(() => new Promise(resolve => { receiver.close(resolve); receiver.closeAllConnections() }))
  const url = `http://127.0.0.1:${receiver.address().port}/webhook`
  const send = (raw, signature = sign(raw)) => fetch(url, {
    method: 'POST',
    headers: { 'x-hub-signature-256': signature, 'x-github-event': 'issues', 'x-github-delivery': 'delivery-1' },
    body: raw
  })
  assert.equal((await send('{', 'sha256=bad')).status, 401)
  assert.equal((await send('{')).status, 400)
  assert.equal(mutations, 0)
  const raw = JSON.stringify(payload)
  assert.equal((await send(raw)).status, 200)
  assert.equal((await send(raw)).status, 200)
  assert.equal(logs.length, 2)
  failing = true
  assert.equal((await send(raw)).status, 503)
  assert.equal(logs.length, 2)
  failing = false
  assert.equal((await send(raw)).status, 200)
  assert.deepEqual(logs[2], { delivery: 'delivery-1', target: 'example/test#7', result: 'label applied' })
})

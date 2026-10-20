const crypto = require('node:crypto')
const fs = require('node:fs')
const http = require('node:http')

function verifySignature (secret, rawBody, signature) {
  if (!secret || typeof signature !== 'string' || !/^sha256=[0-9a-f]{64}$/.test(signature)) return false
  const expected = 'sha256=' + crypto.createHmac('sha256', secret).update(rawBody).digest('hex')
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))
}

function createAppJwt (appId, pem) {
  const now = Math.floor(Date.now() / 1000)
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url')
  const unsigned = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode({ iat: now - 60, exp: now + 540, iss: String(appId) })}`
  const signature = crypto.createSign('RSA-SHA256').update(unsigned).sign(pem).toString('base64url')
  return `${unsigned}.${signature}`
}

async function apiRequest (path, token, body, { fetchImpl = fetch, sleep = ms => new Promise(resolve => setTimeout(resolve, ms)) } = {}) {
  for (let attempt = 0; attempt < 3; attempt++) {
    let response
    try {
      response = await fetchImpl(`https://api.github.com${path}`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
          'Content-Type': 'application/json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'ghec-ch20-example'
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(2000)
      })
    } catch {
      // Label addition is safe to repeat even if the response was lost.
      if (attempt === 2) throw new Error('destination unavailable')
      await sleep(250 * 2 ** attempt)
      continue
    }
    if (response.ok) return response.json()
    const retryAfter = response.headers.get('retry-after')
    const reset = response.headers.get('x-ratelimit-reset')
    const rateLimited = response.status === 429 ||
      (response.status === 403 && (retryAfter !== null || response.headers.get('x-ratelimit-remaining') === '0'))
    if (attempt === 2 || (!rateLimited && response.status < 500)) throw new Error(`destination HTTP ${response.status}`)
    let delay = 250 * 2 ** attempt
    if (retryAfter !== null) {
      delay = /^\d+$/.test(retryAfter) ? Number(retryAfter) * 1000 : Date.parse(retryAfter) - Date.now()
    } else if (rateLimited) {
      delay = reset ? Number(reset) * 1000 - Date.now() : 60000
    }
    // Longer waits belong in a durable queue. Return failure for manual redelivery.
    if (!Number.isFinite(delay) || delay > 1000) throw new Error('retry later')
    await sleep(Math.max(0, delay))
  }
}

async function mintInstallationToken (config, deps) {
  const pem = fs.readFileSync(config.privateKeyPath, 'utf8')
  const jwt = createAppJwt(config.appId, pem)
  const result = await apiRequest(`/app/installations/${config.installationId}/access_tokens`, jwt, {
    repositories: [config.repository.split('/')[1]],
    permissions: { issues: 'write' }
  }, deps)
  if (typeof result.token !== 'string' || !result.token) throw new Error('missing installation token')
  return result.token
}

async function handleEvent (event, body, config, deps = {}) {
  if (event !== 'issues' || body.action !== 'opened') return { handled: false }
  if (body.repository?.full_name !== config.repository ||
      String(body.installation?.id) !== config.installationId ||
      !Number.isSafeInteger(body.issue?.number) || body.issue.number < 1) {
    throw Object.assign(new Error('unexpected event target'), { status: 400 })
  }
  const token = await (deps.mintToken || (() => mintInstallationToken(config, deps)))()
  const target = `${config.repository}#${body.issue.number}`
  await apiRequest(`/repos/${config.repository}/issues/${body.issue.number}/labels`, token, {
    labels: [config.label]
  }, deps)
  return { handled: true, target }
}

function createReceiver (config, deps = {}) {
  return http.createServer(async (request, response) => {
    const reply = (status, message) => {
      response.writeHead(status, { 'Content-Type': 'text/plain' })
      response.end(message)
    }
    if (request.method !== 'POST' || request.url !== '/webhook') return reply(404, 'not found')
    try {
      const chunks = []
      let size = 0
      for await (const chunk of request) {
        size += chunk.length
        if (size > 1024 * 1024) return reply(413, 'body too large')
        chunks.push(chunk)
      }
      const rawBody = Buffer.concat(chunks)
      if (!verifySignature(config.webhookSecret, rawBody, request.headers['x-hub-signature-256'])) return reply(401, 'invalid signature')
      const delivery = request.headers['x-github-delivery']
      if (typeof delivery !== 'string' || !/^[a-zA-Z0-9-]{1,80}$/.test(delivery)) return reply(400, 'invalid delivery ID')
      let body
      try { body = JSON.parse(rawBody.toString('utf8')) } catch { return reply(400, 'invalid JSON') }
      if (!body || typeof body !== 'object' || Array.isArray(body)) return reply(400, 'invalid payload')
      const result = await handleEvent(request.headers['x-github-event'], body, config, deps)
      if (result.handled) (deps.log || console.log)(JSON.stringify({ delivery, target: result.target, result: 'label applied' }))
      reply(result.handled ? 200 : 202, result.handled ? 'label applied' : 'ignored')
    } catch (error) {
      // Do not expose payloads, credentials, or upstream response bodies.
      reply(error.status || 503, error.status === 400 ? 'unexpected event target' : 'retry delivery after fixing the destination')
    }
  })
}

if (require.main === module) {
  const config = {
    repository: process.env.TARGET_REPOSITORY,
    installationId: process.env.INSTALLATION_ID,
    appId: process.env.APP_ID,
    privateKeyPath: process.env.PRIVATE_KEY_PATH,
    webhookSecret: process.env.WEBHOOK_SECRET,
    label: process.env.TRIAGE_LABEL || 'triage'
  }
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(config.repository || '') ||
      !/^\d+$/.test(config.installationId || '') || !config.appId ||
      !config.privateKeyPath || !config.webhookSecret) {
    throw new Error('Set TARGET_REPOSITORY, INSTALLATION_ID, APP_ID, PRIVATE_KEY_PATH, and WEBHOOK_SECRET')
  }
  fs.accessSync(config.privateKeyPath, fs.constants.R_OK)
  createReceiver(config).listen(3000, '127.0.0.1', () => console.log('Listening on http://127.0.0.1:3000/webhook'))
}

module.exports = { verifySignature, createAppJwt, apiRequest, mintInstallationToken, handleEvent, createReceiver }

// server/test/server.test.js
// Unit and integration test for Node.js Delta-Sync server using native node:test.

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const crypto = require('node:crypto');
process.env.SYNC_API_SECRET = 'test-secret';
const app = require('../src/app');

function tokenFor(studentId) {
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const header = encode({ alg: 'HS256', typ: 'JWT' });
  const payload = encode({ sub: studentId });
  const signature = crypto.createHmac('sha256', process.env.SYNC_API_SECRET)
    .update(`${header}.${payload}`)
    .digest('base64url');
  return `${header}.${payload}.${signature}`;
}

test('Delta-Sync REST API Test Suite', async (t) => {
  let server;
  let baseUrl;

  // Setup: start HTTP server on dynamic port
  await t.test('start test server', async () => {
    await new Promise((resolve) => {
      server = http.createServer(app);
      server.listen(0, '127.0.0.1', () => {
        const port = server.address().port;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve();
      });
    });
    assert.ok(baseUrl);
  });

  await t.test('GET /api/v1/health returns 200 and Haramaya University IT department details', async () => {
    const res = await fetch(`${baseUrl}/api/v1/health`);
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.status, 'ok');
    assert.equal(data.service, 'EthioIT ExitPrep Delta-Sync API');
    assert.equal(data.institution, 'Haramaya University Department of Information Technology');
    assert.ok(data.timestamp);
  });

  await t.test('POST /api/v1/sync/push rejects invalid non-array payloads with 400', async () => {
    const res = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tokenFor('STUDENT_01')}` },
      body: JSON.stringify({ mutations: 'not-an-array' }),
    });
    assert.equal(res.status, 400);
    const data = await res.json();
    assert.equal(data.error, 'Expected mutations array');
  });

  await t.test('POST /api/v1/sync/push accepts empty mutations array gracefully', async () => {
    const res = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tokenFor('STUDENT_01')}` },
      body: JSON.stringify({ mutations: [] }),
    });
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.status, 'success');
    assert.equal(data.syncedCount, 0);
  });

  await t.test('sync endpoints reject missing authentication', async () => {
    const res = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mutations: [] }),
    });
    assert.equal(res.status, 401);
  });

  await t.test('pull rejects malformed watermarks before querying the database', async () => {
    const res = await fetch(`${baseUrl}/api/v1/sync/pull?since=invalid`, {
      headers: { Authorization: `Bearer ${tokenFor('STUDENT_01')}` },
    });
    assert.equal(res.status, 400);
  });

  // Teardown
  await t.test('stop test server', async () => {
    await new Promise((resolve) => server.close(resolve));
  });
});

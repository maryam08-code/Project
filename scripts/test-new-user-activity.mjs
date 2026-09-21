import assert from 'node:assert/strict';

const base = 'http://127.0.0.1:8000/api';
async function call(path, method = 'GET', body, token) {
  const response = await fetch(base + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(15000)
  });
  return { status: response.status, body: await response.json() };
}

const admin = await call('/auth/login', 'POST', {
  username: process.env.TEST_ADMIN_USERNAME || 'admin',
  password: process.env.TEST_ADMIN_PASSWORD || 'admin123'
});
assert.equal(admin.status, 200);
const ids = [];
try {
  for (let index = 0; index < 2; index++) {
    const username = `qa_empty_${Date.now()}_${index}`;
    const password = 'QA-empty-123!';
    const created = await call('/users', 'POST', {
      fullName: 'QA Nama Sama', username, password, role: 'User', unit: 'BAAK'
    }, admin.body.token);
    assert.equal(created.status, 201);
    ids.push(created.body.data.id);
    const login = await call('/auth/login', 'POST', { username, password });
    assert.equal(login.status, 200);
    for (const path of ['/dispositions?perPage=100', '/notifications']) {
      const result = await call(path, 'GET', undefined, login.body.token);
      assert.equal(result.status, 200);
      assert.deepEqual(result.body.data, []);
    }
  }
  assert.equal((await call('/dispositions')).status, 401);
  console.log('PASS: same-name new accounts have empty inboxes; unauthenticated access denied.');
} finally {
  for (const id of ids) {
    assert.equal((await call(`/users/${id}`, 'DELETE', undefined, admin.body.token)).status, 200);
  }
}

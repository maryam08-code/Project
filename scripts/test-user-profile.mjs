import assert from 'node:assert/strict';

const base = 'http://127.0.0.1:8000/api';
async function call(path, method = 'GET', body, token) {
  const response = await fetch(base + path, {
    method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(15000)
  });
  return { status: response.status, body: await response.json() };
}

const admin = await call('/auth/login', 'POST', {
  username: process.env.TEST_ADMIN_USERNAME || 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin123'
});
assert.equal(admin.status, 200);
const username = `qa_profile_${Date.now()}`;
const password = 'Profile-test-123!';
let id;
try {
  const created = await call('/users', 'POST', {
    fullName: 'Budi Santoso', username, password, role: 'User', unit: 'BAAK', position: 'Staf Akademik', email: ''
  }, admin.body.token);
  assert.equal(created.status, 201);
  id = created.body.data.id;
  const login = await call('/auth/login', 'POST', { username, password });
  assert.equal(login.status, 200);
  const token = login.body.token;
  const original = (await call('/auth/me', 'GET', undefined, token)).body.user;
  assert.equal(original.email, null);
  assert.equal(original.unit, 'BAAK');
  assert.equal(original.position, 'Staf Akademik');
  assert.equal(original.full_name, 'Budi Santoso');
  assert.equal(original.username, username);
  assert.equal((await call('/auth/me', 'PUT', { fullName: 'Unauthorized' })).status, 401);
  assert.equal((await call('/auth/me', 'PUT', { fullName: ' ', email: '' }, token)).status, 422);
  assert.equal((await call('/auth/me', 'PUT', { fullName: 'Valid', email: 'invalid' }, token)).status, 422);
  if (admin.body.user.email) {
    assert.equal((await call('/auth/me', 'PUT', { fullName: 'Valid', email: admin.body.user.email }, token)).status, 409);
  }
  const email = `${username}@example.com`;
  const saved = await call('/auth/me', 'PUT', {
    fullName: 'QA Profil Diperbarui', email, id: admin.body.user.id,
    role: 'Administrator', status: 'nonaktif', unit: 'Pusat', position: 'Pimpinan'
  }, token);
  assert.equal(saved.status, 200);
  assert.equal(saved.body.user.id, id);
  assert.equal(saved.body.user.unit, 'BAAK');
  assert.equal(saved.body.user.position, 'Staf Akademik');
  assert.equal(saved.body.user.role_code, 'user');
  assert.equal(saved.body.user.status, 'aktif');
  const restored = (await call('/auth/login', 'POST', { username, password })).body.user;
  assert.equal(restored.email, email);
  assert.equal(restored.full_name, 'QA Profil Diperbarui');
  const adminEdit = await call(`/users/${id}`, 'PUT', {
    fullName: 'QA Profil Admin', email, role: 'User', unit: 'BAUK', position: 'Staf Keuangan', status: 'aktif'
  }, admin.body.token);
  assert.equal(adminEdit.status, 200);
  const refreshed = (await call('/auth/me', 'GET', undefined, token)).body.user;
  assert.equal(refreshed.unit, 'BAUK');
  assert.equal(refreshed.position, 'Staf Keuangan');
  assert.equal(refreshed.full_name, 'QA Profil Admin');
  const logs = await call('/audit-logs?search=update_profile&perPage=100', 'GET', undefined, admin.body.token);
  assert.ok(logs.body.data.some((log) => log.activity === 'update_profile' && log.data_label === 'QA Profil Diperbarui'));
  assert.equal((await call('/auth/me', 'PUT', { fullName: 'QA Profil Admin', email: '' }, token)).status, 200);
  assert.equal((await call('/auth/me', 'GET', undefined, token)).body.user.email, null);
  console.log('PASS: administrator profile data, blank email, persistence, validation, self-only update, protected fields, admin changes, audit.');
} finally {
  if (id) assert.equal((await call(`/users/${id}`, 'DELETE', undefined, admin.body.token)).status, 200);
}

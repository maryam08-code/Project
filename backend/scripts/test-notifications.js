import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createApp } from '../src/app.js';
import { createToken } from '../src/auth/token.js';
import { query, closePool } from '../src/db.js';

test('notification API: all roles, recipient isolation, pagination, persistence and audit', async (t) => {
  const server = createApp().listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api/notifications`;
  const userIds = [];
  const accounts = [];
  async function call(path = '', token, method = 'GET') {
    const response = await fetch(`${base}${path}`, {
      method, headers: token ? { Authorization: `Bearer ${token}` } : {}
    });
    return { status: response.status, body: await response.json() };
  }
  try {
    for (const role of ['administrator', 'operator', 'pimpinan', 'user', 'pegawai']) {
      const id = randomUUID();
      const result = await query(
        `INSERT INTO users (id, role_id, full_name, username, password_hash)
         SELECT $1, id, 'Notification QA', $2, 'disabled-test-password' FROM roles WHERE code = $3 RETURNING id`,
        [id, `notif-qa-${id}`, role]
      );
      assert.equal(result.rowCount, 1, `Role ${role} exists`);
      userIds.push(id);
      const notifications = await query(
        `INSERT INTO notifications (recipient_id, title, message)
         SELECT $1, 'Notification QA ' || n, 'Private test message' FROM generate_series(1, 12) n RETURNING id`, [id]
      );
      accounts.push({ id, role, token: createToken({ sub: id, role }), notification: notifications.rows[0].id });
    }

    await t.test('unauthenticated requests rejected for every action', async () => {
      assert.equal((await call()).status, 401);
      assert.equal((await call('/read-all', null, 'POST')).status, 401);
      assert.equal((await call(`/${accounts[0].notification}/read`, null, 'POST')).status, 401);
    });

    for (const account of accounts) {
      await t.test(`${account.role}: own list, read and read-all persist without exposing another account`, async () => {
        const other = accounts.find(item => item.id !== account.id);
        const first = await call('?perPage=5&page=1', account.token);
        const second = await call('?perPage=5&page=2', account.token);
        assert.equal(first.status, 200);
        assert.equal(first.body.meta.totalCount, 12);
        assert.equal(first.body.meta.unreadCount, 12);
        assert.equal(first.body.meta.totalPages, 3);
        assert.equal(first.body.data.length, 5);
        assert.equal(new Set([...first.body.data, ...second.body.data].map(item => item.id)).size, 10);
        assert.ok(!first.body.data.some(item => item.id === other.notification));
        assert.equal((await call(`/${other.notification}/read`, account.token, 'POST')).status, 404);
        assert.equal((await call('/invalid-id/read', account.token, 'POST')).status, 422);

        const read = await call(`/${account.notification}/read`, account.token, 'POST');
        assert.equal(read.status, 200);
        assert.equal(read.body.data.is_read, true);
        assert.ok(read.body.data.read_at);
        const repeat = await call(`/${account.notification}/read`, account.token, 'POST');
        assert.equal(repeat.body.data.read_at, read.body.data.read_at);
        const unread = await call('?unreadOnly=true', account.token);
        assert.equal(unread.body.meta.unreadCount, 11);
        assert.ok(unread.body.data.every(item => !item.is_read));

        const otherBefore = await call('', other.token);
        const all = await call('/read-all', account.token, 'POST');
        assert.equal(all.body.data.updatedCount, 11);
        assert.equal((await call('', account.token)).body.meta.unreadCount, 0);
        assert.equal((await call('', other.token)).body.meta.unreadCount, otherBefore.body.meta.unreadCount);
        assert.equal((await call('/read-all', account.token, 'POST')).body.data.updatedCount, 0);
        const logs = await query("SELECT activity FROM audit_logs WHERE user_id = $1 AND module = 'notifications'", [account.id]);
        assert.deepEqual(logs.rows.map(row => row.activity).sort(), ['read_all_notifications', 'read_notification']);
      });
    }
  } finally {
    // Remove only the fixtures created by this test run.
    await query('DELETE FROM audit_logs WHERE user_id = ANY($1::uuid[])', [userIds]);
    await query('DELETE FROM users WHERE id = ANY($1::uuid[])', [userIds]);
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    await closePool();
  }
});

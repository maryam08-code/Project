import test from 'node:test';
import assert from 'node:assert/strict';
import { requestLogin } from './login-request.mjs';

test('waits for backend recovery and submits login once without refreshing', async () => {
  const calls = [];
  const payload = { token: 'test-token', user: { role_code: 'administrator' } };
  const result = await requestLogin('/api', 'admin', 'password', {
    wait: async () => {},
    fetchImpl: async (url, options) => {
      calls.push({ url, options });
      if (calls.length === 1) throw new TypeError('Failed to fetch');
      if (calls.length === 2) return new Response('', { status: 503 });
      return Response.json(url.endsWith('/health') ? { status: 'ok' } : payload);
    }
  });
  assert.deepEqual(result, payload);
  assert.equal(calls.filter(call => call.options.method === 'POST').length, 1);
  assert.equal(calls.length, 4);
});

for (const status of [401, 403]) {
  test(`preserves auth rejection ${status} without retrying credentials`, async () => {
    let posts = 0;
    await assert.rejects(requestLogin('/api', 'admin', 'wrong', {
      fetchImpl: async (url) => {
        if (url.endsWith('/health')) return Response.json({ status: 'ok' });
        posts += 1;
        return Response.json({ message: 'Akses ditolak' }, { status });
      }
    }), /Akses ditolak/);
    assert.equal(posts, 1);
  });
}

test('persistent outage stops after bounded probes and sends no credentials', async () => {
  let calls = 0;
  await assert.rejects(requestLogin('/api', 'admin', 'password', {
    attempts: 3, wait: async () => {},
    fetchImpl: async (url) => {
      assert.equal(url, '/api/health');
      calls += 1;
      throw new TypeError('offline');
    }
  }), /tanpa perlu refresh/);
  assert.equal(calls, 3);
});

test('lost login response does not repeat a POST', async () => {
  let posts = 0;
  await assert.rejects(requestLogin('/api', 'admin', 'password', {
    fetchImpl: async (url) => {
      if (url.endsWith('/health')) return Response.json({ status: 'ok' });
      posts += 1;
      throw new TypeError('connection lost');
    }
  }), /tanpa perlu refresh/);
  assert.equal(posts, 1);
});

for (const status of [502, 503, 504]) {
  test(`explains proxy outage ${status} without treating it as wrong credentials`, async () => {
    let posts = 0;
    await assert.rejects(requestLogin('/api', 'operator', 'operator123', {
      fetchImpl: async (url) => {
        if (url.endsWith('/health')) return Response.json({ status: 'ok' });
        posts += 1;
        return new Response('Bad Gateway', { status });
      }
    }), /Server login sedang tidak tersedia/);
    assert.equal(posts, 1);
  });
}

test('reports a non-JSON login error with its HTTP status', async () => {
  await assert.rejects(requestLogin('/api', 'operator', 'operator123', {
    fetchImpl: async (url) => url.endsWith('/health')
      ? Response.json({ status: 'ok' })
      : new Response('<html>Server error</html>', { status: 500 })
  }), /HTTP 500/);
});

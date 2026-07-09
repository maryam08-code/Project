const http = require('http');

async function request(path, options = {}) {
  const url = `http://localhost:8000/api${path}`;
  const { headers: optHeaders, ...restOpts } = options;
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json', ...optHeaders },
    ...restOpts
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, data };
}

async function run() {
  const loginRes = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username: 'admin', password: 'admin123' })
  });
  const token = loginRes.data?.token;
  const headers = { Authorization: `Bearer ${token}` };

  const createUserRes = await request('/users', {
    method: 'POST',
    headers,
    body: JSON.stringify({
      fullName: 'Test User',
      username: 'testuser2',
      password: 'password123',
      role: 'User',
      status: 'aktif'
    })
  });
  console.log('Create User:', createUserRes.status, JSON.stringify(createUserRes.data));
  const newUserId = createUserRes.data?.data?.id;

  if (newUserId) {
    const deleteUserRes = await request(`/users/${newUserId}`, { method: 'DELETE', headers });
    console.log('Delete User:', deleteUserRes.status, JSON.stringify(deleteUserRes.data));
  }
}
run();

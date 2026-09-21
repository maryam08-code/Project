import test from 'node:test';
import assert from 'node:assert/strict';
import { userProfile } from './user-profile.mjs';

test('profile uses administrator account data even when a name matches a demo account', () => {
  assert.deepEqual(userProfile({
    full_name: 'Budi Santoso', username: 'budi_baru', email: 'budi@example.com',
    unit: 'BAAK', position: 'Staf Akademik', role_name: 'User', status: 'aktif'
  }), {
    name: 'Budi Santoso', username: 'budi_baru', email: 'budi@example.com',
    unit: 'BAAK', position: 'Staf Akademik', role: 'User', status: 'Aktif'
  });
});

test('missing fields stay empty without fabricated contact details', () => {
  const profile = userProfile({ full_name: 'Nooraini', email: null, status: 'nonaktif' });
  assert.equal(profile.email, '');
  assert.equal(profile.unit, '');
  assert.equal(profile.position, '');
  assert.equal(profile.status, 'Nonaktif');
  assert.equal(userProfile(null).name, '');
});

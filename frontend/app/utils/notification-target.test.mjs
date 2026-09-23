import test from 'node:test';
import assert from 'node:assert/strict';
import { notificationTarget } from './notification-target.mjs';

test('notification destinations respect portal access', () => {
  assert.equal(notificationTarget('incoming_letters', 'Pimpinan', ['Surat Masuk']), 'Surat Masuk');
  assert.equal(notificationTarget('dispositions', 'User', ['Disposisi Masuk']), 'Disposisi Masuk');
  assert.equal(notificationTarget('letter_requests', 'Operator', ['Ajuan Masuk']), 'Ajuan Masuk');
  assert.equal(notificationTarget('backups', 'Administrator', ['Backup']), 'Backup');
  assert.equal(notificationTarget('dispositions', 'Pegawai', ['Disposisi']), 'Disposisi');
  assert.equal(notificationTarget('incoming_letters', 'Administrator', ['Pengguna', 'Backup']), null);
  assert.equal(notificationTarget('backups', 'User', ['Ajuan Surat']), null);
  assert.equal(notificationTarget('unknown', 'User', ['Dashboard']), null);
});

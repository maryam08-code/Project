import test from 'node:test';
import assert from 'node:assert/strict';
import { ownedRequests, activitySummary } from './user-activity.mjs';

test('new account never inherits demo or another account activity, even with the same name', () => {
  const records = [
    { pemohon: 'Nama Sama', status: 'Disetujui' },
    { ownerId: 'existing', pemohon: 'Nama Sama', status: 'Menunggu Approval' }
  ];
  const mine = ownedRequests(records, 'new');
  assert.deepEqual(mine, []);
  assert.deepEqual(activitySummary(mine, []), {
    total: 0, processing: 0, approved: 0, rejected: 0,
    draft: 0, cancelled: 0, newDispositions: 0
  });
  assert.equal(records.length, 2);
});

test('activity remains owned after reload and name changes; switching accounts isolates it', () => {
  const records = JSON.parse(JSON.stringify([
    { ownerId: 'a', pemohon: 'Nama Lama', status: 'Menunggu Approval' },
    { ownerId: 'a', status: 'Selesai' },
    { ownerId: 'a', status: 'Ditolak' },
    { ownerId: 'b', status: 'Draft' }
  ]));
  assert.deepEqual(activitySummary(ownedRequests(records, 'a'), [{ status: 'dikirim' }, { status: 'selesai' }]), {
    total: 3, processing: 1, approved: 1, rejected: 1,
    draft: 0, cancelled: 0, newDispositions: 1
  });
  assert.equal(ownedRequests(records, 'b').length, 1);
  assert.deepEqual(ownedRequests(records, undefined), []);
});

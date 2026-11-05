import test from 'node:test';
import assert from 'node:assert/strict';
import { compactLetterPayload, letterIdentityKey } from './letter-persistence.mjs';

test('two database letters with identical content retain distinct identities', () => {
  const content = { ownerId: 'owner', jenis: 'Surat Tugas', judul: 'Penugasan', tujuan: 'Internal' };
  const first = { ...content, id: 'first' }, second = { ...content, id: 'second' };
  assert.notEqual(letterIdentityKey(first), letterIdentityKey(second));
  assert.equal(letterIdentityKey(first), letterIdentityKey({ ...first, judul: 'Perbaikan judul' }));
});

test('a 10 MB final PDF fits the JSON request limit without losing its identity', () => {
  const document = ['letter.pdf', '10 MB', 'Final', `data:application/pdf;base64,${Buffer.alloc(10 * 1024 * 1024).toString('base64')}`, 'application/pdf'];
  const record = { version: 3, status: 'Selesai', suratFinalOperator: document, lampiranFinal: [document] };
  assert.ok(Buffer.byteLength(JSON.stringify(record)) > 15 * 1024 * 1024);
  const payload = compactLetterPayload(record);
  assert.ok(Buffer.byteLength(JSON.stringify(payload)) < 15 * 1024 * 1024);
  assert.equal(payload.lampiranFinal[0], document);
  assert.equal(payload.version, 3);
  assert.equal(record.suratFinalOperator, document);
});

test('different approval and final documents are both retained', () => {
  const approval = ['approved.pdf', '1 KB', 'Approval', '', 'application/pdf', '', '/letter-documents/approval'];
  const final = ['final.pdf', '1 KB', 'Final', '', 'application/pdf', '', '/letter-documents/final'];
  const payload = compactLetterPayload({ dokumenApprovalPimpinan: approval, lampiranApproval: [approval], suratFinalOperator: final, lampiranFinal: [approval] });
  assert.equal(payload.dokumenApprovalPimpinan, undefined);
  assert.equal(payload.suratFinalOperator, final);
});

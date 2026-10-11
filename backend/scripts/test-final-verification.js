import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createRequire } from 'node:module';
import { createApp } from '../src/app.js';
import { query, closePool } from '../src/db.js';
import { createToken } from '../src/auth/token.js';

const require = createRequire(import.meta.url);
const express = require('express');
const { createEofficeRouter } = require('../../../keabsahan-surat/src/eoffice.js');
const reference = `QA-FINAL-${randomUUID()}`;
const number = `${reference}/2026`, code = `QA-CODE-${randomUUID()}`;
let office, verifier;
async function serve(app) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  return server;
}
async function call(base, path, body, token) {
  const response = await fetch(`${base}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify(body) });
  return { status: response.status, body: await response.json() };
}
try {
  const users = (await query(`SELECT users.id, roles.code FROM users JOIN roles ON roles.id=users.role_id WHERE users.status='aktif' AND users.deleted_at IS NULL`)).rows;
  const tokenFor = role => {
    const user = users.find(item => item.code === role);
    assert.ok(user, `Seed user for ${role} required`);
    return createToken({ sub: user.id, role });
  };
  office = await serve(createApp());
  const officeUrl = `http://127.0.0.1:${office.address().port}`;
  const app = express(); app.use(express.json());
  app.use('/api/e-office', createEofficeRouter({ apiUrl: `${officeUrl}/api`, database: { findByToken: async () => null } }));
  verifier = await serve(app);
  const verifyUrl = `http://127.0.0.1:${verifier.address().port}`;
  const payload = { sourceType: 'outgoing', sourceReference: reference, nomorSurat: number, kodeUnik: code, status: 'Disetujui', perihal: 'QA verification fixture', document: { name: 'qa.pdf', type: 'application/pdf', dataUrl: `data:application/pdf;base64,${Buffer.from('%PDF-1.4\n%%EOF').toString('base64')}` } };
  assert.equal((await call(officeUrl, '/api/final-letters', payload)).status, 401);
  for (const role of ['user', 'pimpinan', 'administrator']) assert.equal((await call(officeUrl, '/api/final-letters', payload, tokenFor(role))).status, 403);
  const operator = tokenFor('operator');
  for (const invalid of [{ kodeUnik: '' }, { status: 'Draft' }, { document: { ...payload.document, type: 'image/png' } }, { document: { ...payload.document, dataUrl: 'data:application/pdf;base64,YmFk' } }]) {
    assert.equal((await call(officeUrl, '/api/final-letters', { ...payload, ...invalid }, operator)).status, 422);
  }
  const saved = await call(officeUrl, '/api/final-letters', payload, operator);
  assert.equal(saved.status, 201);
  assert.equal((await call(officeUrl, '/api/final-letters', payload, operator)).status, 200);
  assert.equal((await call(officeUrl, '/api/final-letters', { ...payload, kodeUnik: 'different' }, operator)).status, 409);
  assert.equal((await call(officeUrl, '/api/final-letters', { ...payload, sourceReference: `${reference}-duplicate` }, operator)).status, 409);
  const valid = await call(verifyUrl, '/api/e-office/verify-pair', { nomorSurat: ` ${number.toLowerCase()} `, kodeUnik: ` ${code} ` });
  assert.equal(valid.status, 200); assert.equal(valid.body.valid, true); assert.equal(valid.body.data.nomorSurat, number);
  assert.equal(valid.body.data.kodeUnik, undefined); assert.equal(valid.body.data.document_pdf, undefined);
  const pdf = await fetch(`${verifyUrl}/api/e-office/verify-document`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nomorSurat: number, kodeUnik: code }) });
  assert.equal(pdf.status, 200);
  assert.ok(pdf.headers.get('content-type').includes('application/pdf'));
  assert.equal(pdf.headers.get('cache-control'), 'no-store');
  assert.equal(Buffer.from(await pdf.arrayBuffer()).toString(), '%PDF-1.4\n%%EOF');
  assert.equal((await call(verifyUrl, '/api/e-office/verify-document', { nomorSurat: number, kodeUnik: 'wrong' })).status, 404);
  for (const pair of [{ nomorSurat: number, kodeUnik: 'wrong-code' }, { nomorSurat: 'wrong-number', kodeUnik: code }]) {
    const invalid = await call(verifyUrl, '/api/e-office/verify-pair', pair);
    assert.equal(invalid.body.valid, false); assert.equal(invalid.body.data, null);
  }
  const audit = await query("SELECT count(*)::int AS count FROM audit_logs WHERE data_id=$1 AND activity='publish_final_letter'", [saved.body.data.id]);
  assert.equal(audit.rows[0].count, 1);
  const notification = await query('SELECT count(*)::int AS count FROM notifications WHERE source_id=$1', [saved.body.data.id]);
  assert.equal(notification.rows[0].count, 1);
  await query('UPDATE final_letter_publications SET deleted_at=now() WHERE id=$1', [saved.body.data.id]);
  assert.equal((await call(verifyUrl, '/api/e-office/verify-pair', { nomorSurat: number, kodeUnik: code })).body.valid, false);
  assert.equal((await call(verifyUrl, '/api/e-office/verify-document', { nomorSurat: number, kodeUnik: code })).status, 404);
  console.log('PASS: publication, role access, validation, duplicate prevention, external paired verification, audit, notifications, and deleted records.');
} finally {
  if (verifier) await new Promise(resolve => verifier.close(resolve));
  if (office) await new Promise(resolve => office.close(resolve));
  await query('DELETE FROM notifications WHERE source_id IN (SELECT id FROM final_letter_publications WHERE source_reference=$1)', [reference]);
  await query('DELETE FROM audit_logs WHERE data_id IN (SELECT id FROM final_letter_publications WHERE source_reference=$1)', [reference]);
  await query('DELETE FROM final_letter_publications WHERE source_reference=$1', [reference]);
  await closePool();
}

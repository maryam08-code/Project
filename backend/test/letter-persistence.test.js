import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import pg from 'pg';
import { config } from '../src/config.js';
import { createApp } from '../src/app.js';
import { createToken } from '../src/auth/token.js';
import { query, closePool, pool } from '../src/db.js';

test('database letter workflows, numbering, documents, archives and role isolation', async (t) => {
  const prefix = `persist-${randomUUID().slice(0, 12)}`;
  const users = [], records = [];
  const schema = `test_letters_${randomUUID().replaceAll('-', '')}`;
  assert.match(schema, /^test_letters_[a-f0-9]{32}$/);
  const admin = new pg.Pool(config.db);
  await admin.query(`CREATE SCHEMA "${schema}"`);
  t.after(async () => {
    await closePool();
    await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
    await admin.end();
  });
  pool.options.options = `-c search_path=${schema},public`;
  const migrations = (await readdir(new URL('../database/', import.meta.url))).filter(file => /^(00[1-8]|010|011|014)_.*\.sql$/.test(file)).sort();
  for (const migration of migrations) await query(await readFile(new URL(`../database/${migration}`, import.meta.url), 'utf8'));

  const server = createApp().listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api`;
  const pdf = Buffer.from('%PDF-1.4\n1 0 obj<</Type /Catalog>>endobj\n%%EOF');
  const attachment = ['letter.pdf', '48 B', 'Test PDF', `data:application/pdf;base64,${pdf.toString('base64')}`, 'application/pdf'];
  const tokens = {};
  async function api(role, path, method = 'GET', body, expected = 200) {
    const response = await fetch(`${base}${path}`, { method, headers: { 'Content-Type': 'application/json', ...(role ? { Authorization: `Bearer ${tokens[role]}` } : {}) }, body: body ? JSON.stringify(body) : undefined });
    const payload = response.headers.get('content-type')?.includes('json') ? await response.json() : await response.arrayBuffer();
    assert.equal(response.status, expected, `${method} ${path}: ${JSON.stringify(payload)}`);
    return payload;
  }
  try {
    for (const [name, role] of [['user','user'],['other','user'],['operator','operator'],['pimpinan','pimpinan'],['admin','administrator'],['pegawai','pegawai']]) {
      const result = await query(`INSERT INTO users (role_id,full_name,username,password_hash,status)
        SELECT id,$1,$1,'test-only','aktif' FROM roles WHERE code=$2 RETURNING id`, [`${prefix}-${name}`,role]);
      const id = result.rows[0].id; users.push(id); tokens[name] = createToken({ sub: id, role });
    }
    await api(null, '/letter-requests', 'GET', null, 401);
    await api('user', '/outgoing-letters', 'GET', null, 403);
    await api('operator', '/letter-requests', 'POST', {}, 403);
    await api('user', '/letter-requests', 'POST', { jenis: 'Surat Tugas', judul: 'Invalid', tujuan: 'Test', status: 'Disetujui' }, 422);
    await api('user', '/letter-requests', 'POST', { jenis: 'Surat Tugas', judul: 'Missing PDF', tujuan: 'Test', status: 'Menunggu Approval' }, 422);
    const invalid = [...attachment]; invalid[0] = 'script.exe';
    await api('user', '/letter-requests', 'POST', { jenis: 'Surat Tugas', judul: 'Bad PDF', tujuan: 'Test', lampiran: [invalid], status: 'Menunggu Approval' }, 422);
    const limit = config.app.maxUploadSize;
    try {
      config.app.maxUploadSize = 10;
      await api('user', '/letter-requests', 'POST', { jenis: 'Surat Tugas', judul: 'Oversize PDF', tujuan: 'Test', lampiran: [attachment], status: 'Menunggu Approval' }, 422);
    } finally { config.app.maxUploadSize = limit; }
    const legacy = { jenis: 'Surat Tugas', judul: 'Imported draft', tujuan: 'Test', status: 'Draft', clientReference: `${prefix}-legacy`, legacyReference: 'AJ/OLD/1', legacyStatus: 'Selesai' };
    const imported = (await api('user', '/letter-requests', 'POST', legacy, 201)).data;
    records.push(imported.id);
    assert.equal(imported.status, 'Draft');
    assert.equal(imported.legacyReference, 'AJ/OLD/1');
    const retried = (await api('user', '/letter-requests', 'POST', legacy, 201)).data;
    assert.equal(retried.id, imported.id);
    assert.equal(retried.number, imported.number);
    const submitted = (await api('user', `/letter-requests/${encodeURIComponent(imported.nomor)}`, 'PATCH', { version: imported.version, status: 'Menunggu Approval', lampiran: [attachment] })).data;
    assert.equal(submitted.status, 'Menunggu Approval');
    assert.equal(submitted.number, imported.number);

    const concurrent = await Promise.all(['user','other'].map(role => api(role, '/letter-requests', 'POST', { jenis: 'Surat Tugas', judul: 'Concurrent create', tujuan: 'Test', status: 'Draft' }, 201)));
    concurrent.forEach(item => records.push(item.data.id));
    assert.notEqual(concurrent[0].data.number, concurrent[1].data.number);
    const foreign = concurrent[1].data;
    await api('other', `/letter-requests/${encodeURIComponent(foreign.nomor)}`, 'PATCH', { version: foreign.version, lampiran: submitted.lampiran }, 422);

    let request = (await api('user', '/letter-requests', 'POST', { jenis: 'Surat Tugas', judul: prefix, tujuan: 'Test', lampiran: [attachment], status: 'Menunggu Approval', ownerId: users[1], nomor: 'client-number' }, 201)).data;
    records.push(request.id);
    assert.equal(request.ownerId, users[0]);
    assert.match(request.nomor, /^AJ\/\d+$/);
    assert.ok(Number(request.number) > 0);
    assert.equal(request.lampiran[0][3], '');
    const docPath = request.lampiran[0][6];
    await api(null, docPath, 'GET', null, 401);
    await api('other', docPath, 'GET', null, 404);
    assert.deepEqual(Buffer.from(await api('user', docPath)), pdf);
    assert.ok(!(await api('other', '/letter-requests')).data.some(item => item.id === request.id));
    const paged = await api('user', '/letter-requests?perPage=1&page=1');
    assert.equal(paged.data.length, 1);
    assert.ok(paged.meta.totalCount >= 3);
    const reloaded = (await api('user', '/letter-requests')).data.find(item => item.id === request.id);
    assert.equal(reloaded.number, request.number);
    await api('other', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Draft' }, 404);
    await api('user', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Disetujui' }, 403);
    await api('admin', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Disetujui' }, 403);
    await api('pimpinan', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Ditolak' }, 422);
    await api('operator', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Selesai' }, 409);
    request = (await api('pimpinan', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Disetujui', lampiranApproval: [attachment], dokumenApprovalPimpinan: attachment })).data;
    await api('pimpinan', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: 1, status: 'Ditolak', catatanPimpinan: 'Stale' }, 409);
    const official = `${prefix}/AJ`;
    await api('operator', '/final-letters', 'POST', { sourceType: 'ajuan', sourceReference: request.nomor, nomorSurat: official, kodeUnik: prefix, status: 'Selesai', document: { name: 'letter.pdf', type: 'application/pdf', dataUrl: attachment[3] } }, 201);
    request = (await api('operator', `/letter-requests/${encodeURIComponent(request.nomor)}`, 'PATCH', { version: request.version, status: 'Selesai', nomorSuratFinal: official, kodeUnik: prefix, suratFinalOperator: attachment, lampiranFinal: [attachment] })).data;
    const archive = (await api('user', '/archives')).data.find(item => item.letterNumber === official);
    assert.ok(archive?.number);
    assert.ok(!(await api('other', '/archives')).data.some(item => item.id === archive.id));
    assert.deepEqual(Buffer.from(await api('user', archive.attachment[6])), pdf);
    const verified = await api(null, '/public/verify-final', 'POST', { nomorSurat: official, kodeUnik: prefix });
    assert.equal(verified.valid, true);

    let outgoing = (await api('operator', '/outgoing-letters', 'POST', { jenis: 'Surat Undangan', perihal: prefix, tujuan: 'Internal', status: 'Menunggu Approval', lampiran: [attachment] }, 201)).data;
    records.push(outgoing.id);
    assert.match(outgoing.nomor, /^DRAFT\/SK\/\d+$/);
    await api('user', outgoing.lampiran[0][6], 'GET', null, 404);
    outgoing = (await api('pimpinan', `/outgoing-letters/${encodeURIComponent(outgoing.nomor)}`, 'PATCH', { version: outgoing.version, status: 'Ditolak', catatanPimpinan: 'Revisi isi' })).data;
    outgoing = (await api('operator', `/outgoing-letters/${encodeURIComponent(outgoing.nomor)}`, 'PATCH', { version: outgoing.version, status: 'Menunggu Approval', lampiran: [attachment], catatanOperator: 'Direvisi' })).data;
    outgoing = (await api('pimpinan', `/outgoing-letters/${encodeURIComponent(outgoing.nomor)}`, 'PATCH', { version: outgoing.version, status: 'Disetujui', lampiranApproval: [attachment] })).data;
    await api('operator', '/final-letters', 'POST', { sourceType: 'outgoing', sourceReference: outgoing.nomor, nomorSurat: `${prefix}/SK`, kodeUnik: `${prefix}-SK`, status: 'Dikirim', document: { name: 'letter.pdf', type: 'application/pdf', dataUrl: attachment[3] } }, 201);
    outgoing = (await api('operator', `/outgoing-letters/${encodeURIComponent(outgoing.nomor)}`, 'PATCH', { version: outgoing.version, status: 'Dikirim', nomorFinal: `${prefix}/SK`, kodeUnik: `${prefix}-SK`, suratFinalOperator: attachment, lampiranFinal: [attachment] })).data;
    assert.ok((await api('operator', '/archives')).data.some(item => item.letterNumber === `${prefix}/SK`));
    const counts = await query('SELECT (SELECT count(*) FROM audit_logs WHERE data_id=ANY($1::uuid[])) AS audits,(SELECT count(*) FROM notifications WHERE source_id=ANY($1::uuid[])) AS notifications', [records]);
    assert.ok(Number(counts.rows[0].audits) >= 7);
    assert.ok(Number(counts.rows[0].notifications) >= 3);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
});

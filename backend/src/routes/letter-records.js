import { Router } from 'express';
import { createHash, randomUUID } from 'node:crypto';
import { query, withTransaction } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { config } from '../config.js';

export const letterRecordsRouter = Router();
const staff = user => ['administrator', 'operator', 'pimpinan'].includes(user.role_code);
const text = value => typeof value === 'string' ? value.trim() : '';
const fail = (status, message) => { throw Object.assign(new Error(message), { status }); };
const kinds = {
  'letter-requests': { table: 'letter_requests', reference: 'request_number', owner: 'applicant_id', source: 'letter_request' },
  'outgoing-letters': { table: 'outgoing_letters', reference: 'letter_number', owner: 'created_by', source: 'outgoing_letter' }
};
const requestStatuses = { Draft: 'draft', 'Ajuan Baru': 'dikirim', Diproses: 'diproses_operator', 'Menunggu Approval': 'menunggu_approval', Disetujui: 'disetujui', Ditolak: 'ditolak', 'Perlu Revisi': 'ditolak', Selesai: 'selesai' };
const outgoingStatuses = { Draft: 'draft', Diperiksa: 'diperiksa', 'Menunggu Approval': 'menunggu_approval', Disetujui: 'disetujui', Ditolak: 'ditolak', Dikirim: 'dikirim' };
const labels = { draft: 'Draft', dikirim: 'Menunggu Approval', diproses_operator: 'Diproses', menunggu_approval: 'Menunggu Approval', disetujui: 'Disetujui', ditolak: 'Ditolak', selesai: 'Selesai', diperiksa: 'Menunggu Approval', dikirim_outgoing: 'Dikirim' };
const lists = ['lampiran', 'lampiranApproval', 'lampiranRevisiDraft', 'lampiranFinal'];
const singles = ['dokumenApprovalPimpinan', 'dokumenPendukungRevisi', 'suratFinalOperator'];
const contentFields = ['jenis', 'judul', 'perihal', 'tujuan', 'keterangan', 'ringkasan', 'penerima', 'tembusan', 'tanggalInput', 'lampiran', 'dokumenDiunggahUser', 'sifat', 'penandatangan', 'nim', 'nik', 'email', 'phone'];
const operatorFields = ['catatanOperator', 'kategoriRevisi', 'direvisiOleh', 'direvisiPada', 'nomorSuratFinal', 'nomorFinal', 'kodeUnik', 'suratFinalOperator', 'lampiranFinal', 'dinomoriOleh', 'dinomoriPada', 'dokumenPendukungRevisi', 'lampiranRevisiDraft', 'riwayat', 'hasilPemeriksaan', 'diteruskanKe', 'diperiksaOleh', 'diperiksaPada'];
const leaderFields = ['catatanPimpinan', 'alasanPenolakanPimpinan', 'dokumenApprovalPimpinan', 'lampiranApproval', 'diputuskanOleh', 'diputuskanPada', 'riwayat'];

function validateFields(data) {
  for (const [key, value] of Object.entries(data)) {
    if (lists.includes(key) || singles.includes(key) || key === 'dokumenDiunggahUser') continue;
    if (key === 'tembusan') {
      if (!Array.isArray(value) || value.length > 30 || value.some(item => typeof item !== 'string' || item.length > 255)) fail(422, 'Daftar tembusan tidak valid.');
    } else if (key === 'riwayat') {
      if (!Array.isArray(value) || value.length > 200 || value.some(item => !Array.isArray(item) || item.length !== 2 || item.some(part => typeof part !== 'string' || part.length > 2000))) fail(422, 'Riwayat surat tidak valid.');
    } else if (typeof value !== 'string' || value.length > 20000) fail(422, `Field ${key} tidak valid atau terlalu panjang.`);
  }
}

export function recordToUI(row, kind) {
  const request = kind.table === 'letter_requests';
  return { ...row.frontend_data,
    id: row.id, number: row.number, version: row.version,
    nomor: row[kind.reference], ownerId: row[kind.owner],
    jenis: row.frontend_data?.jenis || row.type_name || 'Surat Lainnya',
    judul: row.subject, perihal: row.subject, tujuan: row.destination,
    keterangan: request ? row.body : row.summary,
    pemohon: row.applicant_name || row.frontend_data?.pemohon,
    unit: row.unit_name || row.frontend_data?.unit,
    tanggal: row.frontend_data?.tanggal || new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', dateStyle: 'long' }).format(new Date(row.created_at)),
    status: !request && row.status === 'dikirim' ? 'Dikirim' : row.status === 'ditolak' && row.frontend_data?.status === 'Perlu Revisi' ? 'Perlu Revisi' : labels[row.status]
  };
}

async function audit(client, user, activity, module, row) {
  await client.query(`INSERT INTO audit_logs (user_id, activity, module, data_id, data_label)
    VALUES ($1,$2,$3,$4,$5)`, [user.id, activity, module, row.id, row.request_number || row.letter_number]);
}

async function visibleRecord(client, kind, reference, user, lock = false) {
  const result = await client.query(`SELECT * FROM ${kind.table} WHERE ${kind.reference} = $1 AND deleted_at IS NULL ${lock ? 'FOR UPDATE' : ''}`, [reference]);
  const row = result.rows[0];
  if (!row || (!staff(user) && (kind.table !== 'letter_requests' || row.applicant_id !== user.id))) fail(404, 'Surat tidak ditemukan.');
  return row;
}

// Store actual bytes in documents. UI JSON contains only authorized download references.
async function saveAttachment(client, attachment, kind, ownerId, user) {
  if (attachment == null) return null;
  if (!Array.isArray(attachment) || attachment.length > 9) fail(422, 'Format lampiran tidak valid.');
  const [name, size, metadata, dataUrl, mime] = attachment;
  if (typeof name !== 'string' || typeof size !== 'string' || typeof metadata !== 'string' || metadata.length > 2000) fail(422, 'Metadata lampiran tidak valid.');
  if (!dataUrl) {
    const path = text(attachment[6]);
    if (!path) {
      if (name === 'Dokumen pendukung belum diunggah') return attachment.slice(0, 3);
      fail(422, 'Isi lampiran belum tersedia. Unggah kembali dokumen surat.');
    }
    const match = /^\/letter-documents\/([a-f0-9-]{36})$/.exec(path);
    if (!match) fail(422, 'Referensi dokumen tidak valid.');
    const existing = await client.query('SELECT id FROM documents WHERE id=$1 AND owner_type=$2 AND owner_id=$3 AND deleted_at IS NULL', [match[1], kind.source, ownerId]);
    if (!existing.rows[0]) fail(422, 'Dokumen bukan milik surat ini.');
    return [name, size, metadata, '', mime, '', path];
  }
  const match = /^data:application\/pdf;base64,([A-Za-z0-9+/=\r\n]+)$/.exec(text(dataUrl));
  const bytes = match && Buffer.from(match[1], 'base64');
  if (!/\.pdf$/i.test(text(name)) || text(name).length > 255 || mime !== 'application/pdf' || !bytes || bytes.subarray(0, 5).toString() !== '%PDF-') fail(422, 'Lampiran wajib berupa PDF yang valid.');
  if (!bytes.length || bytes.length > config.app.maxUploadSize) fail(422, 'Ukuran lampiran maksimal 10 MB.');
  const hash = createHash('sha256').update(bytes).digest('hex');
  const saved = await client.query(`INSERT INTO documents
    (owner_type, owner_id, original_name, stored_name, storage_path, mime_type, file_extension, file_size_bytes, checksum_sha256, previewable, uploaded_by, content)
    VALUES ($1,$2,$3,$4,'database','application/pdf','pdf',$5,$6,true,$7,$8)
    ON CONFLICT (owner_type, owner_id, checksum_sha256) WHERE content IS NOT NULL AND deleted_at IS NULL
    DO UPDATE SET original_name = documents.original_name RETURNING id`,
  [kind.source, ownerId, text(name), `${randomUUID()}.pdf`, bytes.length, hash, user.id, bytes]);
  return [text(name), size, metadata, '', 'application/pdf', '', `/letter-documents/${saved.rows[0].id}`];
}

async function attachments(client, data, kind, id, user) {
  for (const field of lists) {
    if (data[field] === undefined) continue;
    if (!Array.isArray(data[field]) || data[field].length > 10) fail(422, 'Maksimal 10 lampiran per bagian.');
    data[field] = await Promise.all(data[field].map(item => saveAttachment(client, item, kind, id, user)));
  }
  for (const field of singles) if (data[field] !== undefined) data[field] = await saveAttachment(client, data[field], kind, id, user);
  for (const [single, list] of [['dokumenApprovalPimpinan','lampiranApproval'],['suratFinalOperator','lampiranFinal'],['dokumenPendukungRevisi','lampiranRevisiDraft']]) {
    if (data[list] !== undefined && data[single] === undefined) data[single] = data[list][0] || null;
  }
  return data;
}
const hasDocument = items => Array.isArray(items) && items.some(item => item?.[6]);

async function notify(client, kind, row, user, status) {
  const recipients = new Set();
  if (kind.table === 'letter_requests') recipients.add(row.applicant_id);
  const roles = status === 'menunggu_approval' || status === 'dikirim' && kind.table === 'letter_requests' ? ['pimpinan', 'operator'] : ['operator'];
  const staffUsers = await client.query('SELECT users.id FROM users JOIN roles ON roles.id=users.role_id WHERE roles.code=ANY($1) AND users.status=\'aktif\' AND users.deleted_at IS NULL', [roles]);
  staffUsers.rows.forEach(item => recipients.add(item.id));
  for (const id of recipients) if (id !== user.id) await client.query(`INSERT INTO notifications (recipient_id,title,message,source_type,source_id)
    VALUES ($1,'Status surat diperbarui',$2,$3,$4)`, [id, `Surat ${row[kind.reference]}: ${recordToUI(row, kind).status}`, kind.table, row.id]);
}

async function archive(client, kind, row, user) {
  const data = row.frontend_data;
  if (!(data.nomorSuratFinal || data.nomorFinal) || !['selesai', 'dikirim'].includes(row.status)) return;
  const final = data.suratFinalOperator || data.lampiranFinal?.[0];
  const documentId = final?.[6]?.split('/').pop();
  if (!documentId) fail(422, 'Dokumen final wajib tersedia sebelum pengarsipan.');
  await client.query(`INSERT INTO archives (archive_number,source_type,source_id,document_id,letter_type_id,subject,status,archived_by)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (source_type,source_id) DO UPDATE SET document_id=EXCLUDED.document_id,subject=EXCLUDED.subject,status=EXCLUDED.status,updated_at=now()`,
  [`ARS/${kind.table === 'letter_requests' ? 'AJ' : 'SK'}/${row.number}`, kind.source, row.id, documentId, row.letter_type_id, row.subject, row.status, user.id]);
}

for (const [route, kind] of Object.entries(kinds)) {
  letterRecordsRouter.get(`/${route}`, requireAuth, async (req, res, next) => {
    try {
      if (kind.table === 'outgoing_letters' && !staff(req.user)) fail(403, 'Anda tidak memiliki akses ke surat keluar.');
      const page = Math.max(1, Number.parseInt(req.query.page) || 1);
      const perPage = Math.min(100, Math.max(1, Number.parseInt(req.query.perPage) || 50));
      const own = !staff(req.user);
      const result = await query(`SELECT records.*, types.name AS type_name, users.full_name AS applicant_name, units.name AS unit_name,
          count(*) OVER() AS total_count
        FROM ${kind.table} records LEFT JOIN letter_types types ON types.id=records.letter_type_id
        LEFT JOIN users ON users.id=records.${kind.owner} LEFT JOIN units ON units.id=users.unit_id
        WHERE records.deleted_at IS NULL ${own ? 'AND records.applicant_id=$3' : ''}
        ORDER BY records.created_at DESC,records.id LIMIT $1 OFFSET $2`, own ? [perPage, (page - 1) * perPage, req.user.id] : [perPage, (page - 1) * perPage]);
      res.json({ data: result.rows.map(row => recordToUI(row, kind)), meta: { page, perPage, totalCount: Number(result.rows[0]?.total_count || 0) } });
    } catch (error) { next(error); }
  });

  letterRecordsRouter.post(`/${route}`, requireAuth, async (req, res, next) => {
    try {
      const request = kind.table === 'letter_requests';
      if (request ? !['user', 'pegawai'].includes(req.user.role_code) : req.user.role_code !== 'operator') fail(403, 'Peran Anda tidak dapat membuat surat ini.');
      const body = req.body || {};
      const status = (request ? requestStatuses : outgoingStatuses)[body.status || 'Draft'];
      if (!['draft', 'menunggu_approval'].includes(status)) fail(422, 'Surat baru hanya dapat berupa Draft atau Menunggu Approval.');
      const saved = await withTransaction(async client => {
        const clientReference = text(body.clientReference);
        if (clientReference.length > 200) fail(422, 'Referensi pengiriman terlalu panjang.');
        if (clientReference) {
          await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`${kind.table}:${req.user.id}:${clientReference}`]);
          const previous = await client.query(`SELECT * FROM ${kind.table} WHERE ${kind.owner}=$1 AND client_reference=$2 AND deleted_at IS NULL`, [req.user.id,clientReference]);
          if (previous.rows[0]) return recordToUI(previous.rows[0], kind);
        }
        const type = await client.query(`SELECT id FROM letter_types WHERE is_active=true ORDER BY (name=$1) DESC,(name='Surat Lainnya') DESC,name LIMIT 1`, [text(body.jenis)]);
        if (!type.rows[0]) fail(422, 'Jenis surat belum tersedia.');
        const subject = text(body.judul || body.perihal), destination = text(body.tujuan);
        if (!subject || subject.length > 255 || !destination || destination.length > 255 || !text(body.jenis)) fail(422, 'Jenis surat, perihal dan tujuan wajib diisi (perihal/tujuan maksimal 255 karakter).');
        const id = randomUUID();
        const unit = await client.query('SELECT unit_id FROM users WHERE id=$1', [req.user.id]);
        const data = Object.fromEntries(contentFields.filter(field => body[field] !== undefined).map(field => [field, body[field]]));
        if (body.legacyReference) { data.legacyReference = text(body.legacyReference).slice(0,200); data.legacyStatus = text(body.legacyStatus).slice(0,100); }
        validateFields(data);
        data.status = body.status || 'Draft';
        if (request) { data.pemohon = req.user.full_name; data.unit = req.user.unit; }
        else data.pembuat = req.user.full_name;
        const letterDate = !request && text(body.tanggalInput) ? new Date(`${text(body.tanggalInput)}T00:00:00+07:00`) : new Date();
        if (Number.isNaN(letterDate.getTime())) fail(422, 'Tanggal surat tidak valid.');
        data.tanggal = new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', dateStyle: 'long' }).format(letterDate);
        await attachments(client, data, kind, id, req.user);
        if (status !== 'draft' && !hasDocument(data.lampiran)) fail(422, 'Unggah dokumen sebelum mengirim surat.');
        let inserted;
        if (request) inserted = await client.query(`INSERT INTO letter_requests
          (id,request_number,letter_type_id,subject,destination,body,applicant_id,applicant_unit_id,status,created_by,updated_by,frontend_data,submitted_at)
          VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::letter_request_status,$7,$7,$10,CASE WHEN $9::text='draft' THEN NULL ELSE now() END) RETURNING *`,
        [id, `AJ/${id}`, type.rows[0].id, subject, destination, text(body.keterangan), req.user.id, unit.rows[0].unit_id, status, JSON.stringify(data)]);
        else inserted = await client.query(`INSERT INTO outgoing_letters
          (id,letter_number,letter_date,letter_type_id,destination,subject,summary,status,created_by,frontend_data,approval_requested_at)
          VALUES ($1,$2,COALESCE($3::date,(now() AT TIME ZONE 'Asia/Jakarta')::date),$4,$5,$6,$7,$8::outgoing_letter_status,$9,$10,CASE WHEN $8::text='draft' THEN NULL ELSE now() END) RETURNING *`,
        [id, `DRAFT/${id}`, text(body.tanggalInput) || null, type.rows[0].id, destination, subject, text(body.ringkasan), status, req.user.id, JSON.stringify(data)]);
        const row = inserted.rows[0];
        // References and visible numbers are allocated by the database, never by the browser.
        const reference = `${request ? 'AJ' : 'DRAFT/SK'}/${row.number}`;
        row[kind.reference] = reference;
        await client.query(`UPDATE ${kind.table} SET ${kind.reference}=$1,client_reference=$3 WHERE id=$2`, [reference, id,clientReference || null]);
        await audit(client, req.user, 'create', kind.table, row);
        if (status !== 'draft') await notify(client, kind, row, req.user, status);
        return recordToUI({ ...row, applicant_name: req.user.full_name, unit_name: req.user.unit }, kind);
      });
      res.status(201).json({ data: saved });
    } catch (error) { next(error); }
  });

  letterRecordsRouter.patch(`/${route}/:reference`, requireAuth, async (req, res, next) => {
    try {
      const saved = await withTransaction(async client => {
        const row = await visibleRecord(client, kind, req.params.reference, req.user, true);
        const request = kind.table === 'letter_requests', body = req.body || {}, role = req.user.role_code;
        if (!Number.isInteger(body.version) || body.version !== row.version) fail(409, 'Surat telah berubah. Muat ulang data sebelum menyimpan kembali.');
        const status = body.status ? (request ? requestStatuses : outgoingStatuses)[body.status] : row.status;
        if (!status) fail(422, 'Status surat tidak valid.');
        let allowed;
        if (request && ['user', 'pegawai'].includes(role)) {
          if (row.applicant_id !== req.user.id || !['draft', 'ditolak'].includes(row.status) || !['draft', 'menunggu_approval'].includes(status)) fail(403, 'Ajuan hanya dapat diedit pemilik saat draft atau revisi.');
          allowed = contentFields;
        } else if (role === 'pimpinan') {
          if (!['menunggu_approval', 'dikirim', 'diperiksa'].includes(row.status) || !['disetujui', 'ditolak'].includes(status)) fail(409, 'Surat belum menunggu keputusan pimpinan.');
          allowed = leaderFields;
        } else if (role === 'operator') {
          const permitted = request
            ? { dikirim: ['diproses_operator', 'menunggu_approval', 'ditolak'], diproses_operator: ['diproses_operator', 'menunggu_approval', 'ditolak'], menunggu_approval: ['menunggu_approval', 'ditolak'], disetujui: ['disetujui', 'selesai'], selesai: ['selesai'] }
            : { draft: ['draft', 'menunggu_approval'], ditolak: ['ditolak', 'menunggu_approval'], diperiksa: ['menunggu_approval'], menunggu_approval: ['menunggu_approval'], disetujui: ['disetujui', 'dikirim'], dikirim: ['dikirim'] };
          if (!permitted[row.status]?.includes(status)) fail(409, 'Tahapan surat tidak mengizinkan perubahan ini.');
          allowed = [...operatorFields, ...(!request && ['draft', 'ditolak'].includes(row.status) ? contentFields : [])];
          if (body.nomorFinal || body.nomorSuratFinal || body.suratFinalOperator || body.lampiranFinal) {
            if (!['disetujui'].includes(row.status)) fail(409, 'Penomoran hanya dapat dilakukan setelah persetujuan pimpinan.');
          }
        } else fail(403, 'Peran Anda tidak dapat mengubah surat ini.');
        const changes = Object.fromEntries(allowed.filter(field => body[field] !== undefined).map(field => [field, body[field]]));
        validateFields(changes);
        await attachments(client, changes, kind, row.id, req.user);
        const data = { ...row.frontend_data, ...changes, status: body.status || row.frontend_data.status };
        if (role === 'pimpinan') data.diputuskanOleh = req.user.full_name;
        if (role === 'operator' && (changes.nomorFinal || changes.nomorSuratFinal)) data.dinomoriOleh = req.user.full_name;
        if (changes.riwayat) data.riwayat = [...(row.frontend_data.riwayat || []), ...changes.riwayat];
        const rejection = text(data.alasanPenolakanPimpinan || data.catatanPimpinan || data.catatanOperator);
        if (status === 'ditolak' && !rejection) fail(422, 'Catatan penolakan atau revisi wajib diisi.');
        if (status === 'disetujui' && row.status !== status && !hasDocument(data.lampiranApproval)) fail(422, 'Unggah surat persetujuan pimpinan.');
        if (status === 'menunggu_approval' && row.status !== status && !hasDocument(data.lampiran)) fail(422, 'Unggah dokumen sebelum mengajukan approval.');
        if ((request && status === 'selesai' || !request && status === 'dikirim') && row.status !== status) {
          if (!text(data.nomorSuratFinal || data.nomorFinal) || !text(data.kodeUnik) || !hasDocument(data.lampiranFinal)) fail(422, 'Nomor surat, kode unik, dan dokumen final wajib diisi.');
          const final = data.suratFinalOperator || data.lampiranFinal[0];
          const publication = await client.query(`SELECT p.id FROM final_letter_publications p JOIN documents d ON d.id=$4
            WHERE p.source_type=$1 AND p.source_reference=$2 AND p.letter_number=$3 AND p.deleted_at IS NULL
              AND p.document_hash=d.checksum_sha256 AND p.code_hash=$5`,
          [request ? 'ajuan' : 'outgoing', row[kind.reference], data.nomorSuratFinal || data.nomorFinal, final[6].split('/').pop(), createHash('sha256').update(text(data.kodeUnik)).digest('hex')]);
          if (!publication.rows[0]) fail(409, 'Daftarkan surat final untuk verifikasi sebelum menyelesaikan surat.');
        }
        const subject = text(data.judul || data.perihal || row.subject), destination = text(data.tujuan || row.destination);
        if (!subject || subject.length > 255 || !destination || destination.length > 255) fail(422, 'Perihal dan tujuan wajib diisi, maksimal 255 karakter.');
        const actor = role === 'pimpinan' ? ',approver_id=$8' : request ? ',operator_id=CASE WHEN $9=\'operator\' THEN $8 ELSE operator_id END,updated_by=$8' : ',checked_by=$8';
        const result = await client.query(`UPDATE ${kind.table} SET subject=$1,destination=$2,${request ? 'body' : 'summary'}=$3,status=$4::${request ? 'letter_request_status' : 'outgoing_letter_status'},
          rejection_note=$5,frontend_data=$6,version=version+1,updated_at=now(),
          approved_at=CASE WHEN $4::text='disetujui' AND approved_at IS NULL THEN now() ELSE approved_at END,
          rejected_at=CASE WHEN $4::text='ditolak' THEN now() ELSE rejected_at END
          ${request ? ",submitted_at=CASE WHEN $4::text='menunggu_approval' AND submitted_at IS NULL THEN now() ELSE submitted_at END,completed_at=CASE WHEN $4::text='selesai' THEN COALESCE(completed_at,now()) ELSE completed_at END" : ",sent_at=CASE WHEN $4::text='dikirim' THEN COALESCE(sent_at,now()) ELSE sent_at END"}
          ${actor} WHERE id=$7 RETURNING *`,
        request && role !== 'pimpinan'
          ? [subject,destination,text(data.keterangan || row.body),status,status === 'ditolak' ? rejection : null,JSON.stringify(data),row.id,req.user.id,role]
          : [subject,destination,text(request ? data.keterangan || row.body : data.ringkasan || row.summary),status,status === 'ditolak' ? rejection : null,JSON.stringify(data),row.id,req.user.id]);
        const updated = result.rows[0];
        await archive(client, kind, updated, req.user);
        await audit(client, req.user, 'update', kind.table, updated);
        if (status !== row.status) await notify(client, kind, updated, req.user, status);
        const owner = await client.query('SELECT users.full_name,units.name AS unit FROM users LEFT JOIN units ON units.id=users.unit_id WHERE users.id=$1', [updated[kind.owner]]);
        return recordToUI({ ...updated, applicant_name: owner.rows[0]?.full_name, unit_name: owner.rows[0]?.unit }, kind);
      });
      res.json({ data: saved });
    } catch (error) { next(error); }
  });
}

letterRecordsRouter.get('/letter-documents/:id', requireAuth, async (req, res, next) => {
  try {
    if (!/^[a-f0-9-]{36}$/.test(req.params.id)) fail(404, 'Dokumen tidak ditemukan.');
    const result = await query(`SELECT * FROM documents WHERE id=$1 AND content IS NOT NULL AND deleted_at IS NULL`, [req.params.id]);
    const doc = result.rows[0];
    const kind = Object.values(kinds).find(item => item.source === doc?.owner_type);
    if (!doc || !kind) fail(404, 'Dokumen tidak ditemukan.');
    const owner = await query(`SELECT ${kind.reference} FROM ${kind.table} WHERE id=$1 AND deleted_at IS NULL`, [doc.owner_id]);
    if (!owner.rows[0]) fail(404, 'Dokumen tidak ditemukan.');
    await visibleRecord({ query }, kind, owner.rows[0][kind.reference], req.user);
    await withTransaction(client => audit(client, req.user, 'download', 'documents', { id: doc.id, letter_number: doc.original_name }));
    res.set('Content-Type', doc.mime_type).set('Cache-Control', 'private, no-store').set('Content-Disposition', `inline; filename*=UTF-8''${encodeURIComponent(doc.original_name)}`).send(doc.content);
  } catch (error) { next(error); }
});

letterRecordsRouter.get('/archives', requireAuth, async (req, res, next) => {
  try {
    const page = Math.max(1, Number.parseInt(req.query.page) || 1), perPage = Math.min(100, Math.max(1, Number.parseInt(req.query.perPage) || 50));
    const privileged = ['administrator', 'operator'].includes(req.user.role_code);
    const result = await query(`SELECT a.*, lr.frontend_data AS request_data, ol.frontend_data AS outgoing_data,
        lr.request_number, ol.letter_number AS outgoing_reference, il.letter_number AS incoming_number,
        lr.applicant_id, ol.created_by, il.id AS incoming_id, d.id AS linked_document_id, d.original_name, d.mime_type, d.file_size_bytes, d.content IS NOT NULL AS database_document,
        count(*) OVER() AS total_count
      FROM archives a
      LEFT JOIN letter_requests lr ON a.source_type='letter_request' AND lr.id=a.source_id AND lr.deleted_at IS NULL
      LEFT JOIN outgoing_letters ol ON a.source_type='outgoing_letter' AND ol.id=a.source_id AND ol.deleted_at IS NULL
      LEFT JOIN incoming_letters il ON a.source_type='incoming_letter' AND il.id=a.source_id AND il.deleted_at IS NULL
        LEFT JOIN documents d ON d.id=COALESCE(a.document_id,
          (SELECT id FROM documents WHERE owner_type='incoming_letter' AND owner_id=il.id AND deleted_at IS NULL ORDER BY uploaded_at DESC LIMIT 1)) AND d.deleted_at IS NULL
      WHERE a.deleted_at IS NULL AND (lr.id IS NOT NULL OR ol.id IS NOT NULL OR il.id IS NOT NULL)
        AND ($1::boolean OR lr.applicant_id=$2 OR ($3='pimpinan' AND (lr.id IS NOT NULL OR ol.id IS NOT NULL OR il.forwarded_to=$2))
          OR EXISTS (SELECT 1 FROM dispositions dp WHERE dp.incoming_letter_id=il.id AND dp.target_user_id=$2 AND dp.deleted_at IS NULL))
        AND ($4='' OR a.subject ILIKE '%' || $4 || '%')
      ORDER BY a.archived_at DESC,a.id LIMIT $5 OFFSET $6`, [privileged,req.user.id,req.user.role_code,text(req.query.search),perPage,(page-1)*perPage]);
    const data = result.rows.map(row => {
      const source = row.request_data || row.outgoing_data || {};
      return { id: row.id, number: row.number, sourceType: row.source_type,
        letterNumber: source.nomorSuratFinal || source.nomorFinal || row.incoming_number || row.request_number || row.outgoing_reference,
        subject: row.subject, archivedAt: row.archived_at, status: row.source_type === 'outgoing_letter' && row.status === 'dikirim' ? 'Dikirim' : labels[row.status] || row.status,
        detail: { ...source, nomor: row.request_number || row.outgoing_reference, ownerId: row.applicant_id },
        attachment: row.linked_document_id ? [row.original_name, `${row.file_size_bytes} B`, 'Arsip database', '', row.mime_type, '', row.database_document ? `/letter-documents/${row.linked_document_id}` : `/incoming-letters/${row.incoming_id}/documents/${row.linked_document_id}/download`] : null };
    });
    res.json({ data, meta: { page,perPage,totalCount: Number(result.rows[0]?.total_count || 0) } });
  } catch (error) { next(error); }
});

letterRecordsRouter.use((error, req, res, next) => {
  if (error.status && error.status < 500) return res.status(error.status).json({ message: error.message });
  if (error.code === '23505') return res.status(409).json({ message: 'Nomor atau referensi surat sudah digunakan.' });
  if (['22001', '22007', '22008', '22P02'].includes(error.code)) return res.status(422).json({ message: 'Format atau panjang data surat tidak valid.' });
  next(error);
});

import { createHash } from 'node:crypto';
import { Router } from 'express';
import { query, withTransaction } from '../db.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { config } from '../config.js';

export const finalLettersRouter = Router();
export const normalizeNumber = value => value.trim().toLowerCase().replace(/\s+/g, '');
export const hashCode = value => createHash('sha256').update(value.trim()).digest('hex');
const text = value => typeof value === 'string' ? value.trim() : '';

export function validatePublication(body) {
  const number = text(body.nomorSurat), code = text(body.kodeUnik), reference = text(body.sourceReference);
  if (!number || number.length > 200 || !code || code.length > 200 || !reference || reference.length > 200) {
    throw Object.assign(new Error('Nomor surat, kode unik, dan referensi surat wajib diisi (maksimal 200 karakter).'), { status: 422 });
  }
  if (!['ajuan', 'outgoing'].includes(body.sourceType) || !['Disetujui', 'Dikirim', 'Selesai'].includes(body.status)) {
    throw Object.assign(new Error('Hanya surat yang sudah disetujui atau selesai yang dapat didaftarkan.'), { status: 422 });
  }
  const document = body.document || {};
  const match = /^data:application\/pdf;base64,([A-Za-z0-9+/=\r\n]+)$/.exec(text(document.dataUrl));
  const pdf = match ? Buffer.from(match[1], 'base64') : null;
  if (!/\.pdf$/i.test(text(document.name)) || text(document.name).length > 255 || document.type !== 'application/pdf' || !pdf || pdf.subarray(0, 5).toString() !== '%PDF-') {
    throw Object.assign(new Error('Dokumen final wajib berupa PDF yang valid.'), { status: 422 });
  }
  if (pdf.length > config.app.maxUploadSize) throw Object.assign(new Error('Dokumen final maksimal 10 MB.'), { status: 422 });
  const metadata = {
    nomorSurat: number, perihal: text(body.perihal).slice(0, 255),
    instansi: 'STT Pekerjaan Umum Jakarta', penerima: text(body.penerima).slice(0, 255),
    jenisSurat: text(body.jenisSurat).slice(0, 100) || 'Surat Keluar',
    tanggalSurat: text(body.tanggalSurat).slice(0, 100),
    penandatangan: { nama: text(body.penandatanganNama).slice(0, 200), jabatan: text(body.penandatanganJabatan).slice(0, 200) },
    status: 'SAH', statusVerifikasi: 'Valid / Resmi Diterbitkan'
  };
  return { number, code, reference, pdf, metadata, documentName: document.name.trim(), documentHash: createHash('sha256').update(pdf).digest('hex') };
}

finalLettersRouter.post('/', requireAuth, requireRole('operator'), async (request, response, next) => {
  try {
    const publication = validatePublication(request.body);
    const result = await withTransaction(async client => {
      await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`final-letter:${request.body.sourceType}:${publication.reference}`]);
      const source = request.body.sourceType === 'ajuan'
        ? await client.query('SELECT status::text FROM letter_requests WHERE request_number=$1 AND deleted_at IS NULL', [publication.reference])
        : await client.query('SELECT status::text FROM outgoing_letters WHERE letter_number=$1 AND deleted_at IS NULL', [publication.reference]);
      if (source.rows[0] && !['disetujui', 'dikirim', 'completed', 'selesai'].includes(source.rows[0].status)) {
        throw Object.assign(new Error('Surat pada database belum disetujui pimpinan.'), { status: 409 });
      }
      const existing = await client.query('SELECT id, code_hash, number_normal, document_hash FROM final_letter_publications WHERE source_type=$1 AND source_reference=$2 AND deleted_at IS NULL FOR UPDATE', [request.body.sourceType, publication.reference]);
      if (existing.rows[0]) {
        const row = existing.rows[0];
        if (row.code_hash !== hashCode(publication.code) || row.number_normal !== normalizeNumber(publication.number) || row.document_hash !== publication.documentHash) {
          throw Object.assign(new Error('Surat ini sudah didaftarkan dengan nomor, kode, atau dokumen yang berbeda.'), { status: 409 });
        }
        return { id: row.id, alreadyRegistered: true };
      }
      const inserted = await client.query(`INSERT INTO final_letter_publications
        (source_type, source_reference, letter_number, number_normal, code_hash, metadata, document_name, document_pdf, document_hash, published_by)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id`,
      [request.body.sourceType, publication.reference, publication.number, normalizeNumber(publication.number), hashCode(publication.code), JSON.stringify(publication.metadata), publication.documentName, publication.pdf, publication.documentHash, request.user.id]);
      const id = inserted.rows[0].id;
      await client.query(`INSERT INTO audit_logs (user_id,activity,module,data_id,data_label,metadata,ip_address,user_agent)
        VALUES ($1,'publish_final_letter','final_letters',$2,$3,$4,$5,$6)`,
      [request.user.id, id, publication.number, JSON.stringify({sourceType:request.body.sourceType,sourceReference:publication.reference,documentHash:publication.documentHash}), request.ip, request.get('user-agent') || null]);
      await client.query(`INSERT INTO notifications (recipient_id,title,message,source_type,source_id)
        VALUES ($1,'Surat final terdaftar',$2,'final_letters',$3)`, [request.user.id, `Surat ${publication.number} dapat diverifikasi melalui portal keabsahan surat.`, id]);
      return { id, alreadyRegistered: false };
    });
    response.status(result.alreadyRegistered ? 200 : 201).json({ data: result });
  } catch (error) {
    if (error.code === '23505') return response.status(409).json({ message: 'Nomor surat atau kode unik sudah digunakan oleh surat lain.' });
    if (error.status && error.status < 500) return response.status(error.status).json({ message: error.message });
    next(error);
  }
});

export async function verifyFinalLetter(request, response, next) {
  const number = text(request.body?.nomorSurat), code = text(request.body?.kodeUnik);
  if (!number || number.length > 200 || !code || code.length > 200) return response.status(400).json({ message: 'Nomor surat dan kode unik wajib diisi (maksimal 200 karakter).' });
  try {
    const result = await query(`SELECT metadata FROM final_letter_publications WHERE number_normal=$1 AND code_hash=$2 AND deleted_at IS NULL`, [normalizeNumber(number), hashCode(code)]);
    if (!result.rows[0]) return response.status(404).json({ valid: false, data: null, message: 'Nomor surat dan kode unik tidak cocok atau surat belum tersinkron dari E-Office.' });
    response.json({ valid: true, source: 'e-office', message: 'Nomor surat dan kode unik cocok dengan surat final yang terdaftar di E-Office.', data: result.rows[0].metadata });
  } catch (error) { next(error); }
}

export async function previewFinalDocument(request, response, next) {
  const number = text(request.body?.nomorSurat), code = text(request.body?.kodeUnik);
  if (!number || number.length > 200 || !code || code.length > 200) return response.status(400).json({ message: 'Nomor surat dan kode unik wajib diisi.' });
  try {
    const result = await query('SELECT document_pdf FROM final_letter_publications WHERE number_normal=$1 AND code_hash=$2 AND deleted_at IS NULL', [normalizeNumber(number), hashCode(code)]);
    if (!result.rows[0]) return response.status(404).json({ message: 'Dokumen tidak ditemukan atau nomor surat dan kode unik tidak cocok.' });
    response.set({ 'Content-Type': 'application/pdf', 'Content-Disposition': 'inline; filename="surat-final.pdf"', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
    response.send(result.rows[0].document_pdf);
  } catch (error) { next(error); }
}

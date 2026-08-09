import { pool } from '../db.js';

export const verifyLetter = async (req, res) => {
  try {
    const { letterNumber } = req.params;
    // Hapus spasi dan ubah ke huruf kecil untuk pencarian fleksibel
    const rawInput = decodeURIComponent(letterNumber).trim();
    const searchPattern = `%${rawInput}%`;

    // Query pencarian pencocokan pola (LIKE) di semua skema tabel surat
    const query = `
      SELECT 
        letter_number AS "nomorSurat",
        subject AS "perihal",
        origin AS "instansiPenerbit",
        destination AS "unitBagian",
        letter_date AS "tanggalSurat",
        status AS "statusVerifikasi",
        'Surat Masuk' AS "jenisSurat",
        file_path AS "filePath"
      FROM documents
      WHERE letter_number ILIKE $1 OR agenda_number ILIKE $1

      UNION ALL

      SELECT 
        letter_number AS "nomorSurat",
        subject AS "perihal",
        COALESCE(sender, 'STT Pekerjaan Umum Jakarta') AS "instansiPenerbit",
        COALESCE(recipient, 'Eksternal') AS "unitBagian",
        letter_date AS "tanggalSurat",
        status AS "statusVerifikasi",
        'Surat Keluar' AS "jenisSurat",
        file_path AS "filePath"
      FROM outgoing_letters
      WHERE letter_number ILIKE $1 OR agenda_number ILIKE $1

      LIMIT 1;
    `;

    let result = await db.query(query, [searchPattern]);

    // Jika tabel outgoing_letters belum ada, cari ke tabel documents saja
    if (result.rows.length === 0) {
      const fallbackQuery = `
        SELECT 
          letter_number AS "nomorSurat",
          subject AS "perihal",
          origin AS "instansiPenerbit",
          destination AS "unitBagian",
          letter_date AS "tanggalSurat",
          status AS "statusVerifikasi",
          'Surat Resmi' AS "jenisSurat",
          file_path AS "filePath"
        FROM documents
        WHERE letter_number ILIKE $1 OR agenda_number ILIKE $1 OR subject ILIKE $1
        LIMIT 1;
      `;
      result = await db.query(fallbackQuery, [searchPattern]);
    }

    if (result.rows.length === 0) {
      return res.status(404).json({
        valid: false,
        message: 'Surat dengan nomor/kode tersebut tidak ditemukan atau belum terdaftar.'
      });
    }

    const letter = result.rows[0];

    return res.status(200).json({
      valid: true,
      data: {
        nomorSurat: letter.nomorSurat || rawInput,
        tanggalSurat: letter.tanggalSurat ? new Date(letter.tanggalSurat).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : '-',
        jenisSurat: letter.jenisSurat || 'Surat Keluar / Resmi',
        perihal: letter.perihal || '-',
        instansiPenerbit: letter.instansiPenerbit || 'STT Pekerjaan Umum Jakarta',
        unitBagian: letter.unitBagian || 'Bagian Akademik',
        penandatangan: 'Kepala Bagian / Pimpinan',
        statusVerifikasi: 'Valid / Resmi Diterbitkan',
        pdfUrl: letter.filePath ? `http://localhost:8000/storage/${letter.filePath}` : null
      }
    });
  } catch (error) {
    console.error('Error verification:', error);
    return res.status(500).json({
      valid: false,
      message: 'Terjadi kesalahan sistem saat memeriksa data surat.'
    });
  }
};
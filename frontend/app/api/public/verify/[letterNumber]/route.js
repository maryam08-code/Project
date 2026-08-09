import { NextResponse } from 'next/server';
import { Pool } from 'pg';

// Inisialisasi koneksi PostgreSQL langsung di Next.js
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'eoffice_db',
});

export async function GET(request, { params }) {
  try {
    const { letterNumber } = params;
    const cleanNumber = decodeURIComponent(decodeURIComponent(letterNumber)).trim();
    const searchPattern = `%${cleanNumber}%`;

    const query = `
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
      WHERE letter_number ILIKE $1 OR agenda_number ILIKE $1 OR reference_number ILIKE $1

      UNION ALL

      SELECT 
        letter_number AS "nomorSurat",
        subject AS "perihal",
        'STT Pekerjaan Umum Jakarta' AS "instansiPenerbit",
        'Eksternal' AS "unitBagian",
        letter_date AS "tanggalSurat",
        status AS "statusVerifikasi",
        'Surat Keluar' AS "jenisSurat",
        file_path AS "filePath"
      FROM outgoing_letters
      WHERE letter_number ILIKE $1 OR agenda_number ILIKE $1

      LIMIT 1;
    `;

    let result;
    try {
      result = await pool.query(query, [searchPattern]);
    } catch (dbErr) {
      // Fallback jika tabel outgoing_letters belum ada
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
        WHERE letter_number ILIKE $1 OR agenda_number ILIKE $1
        LIMIT 1;
      `;
      result = await pool.query(fallbackQuery, [searchPattern]);
    }

    if (result.rows.length === 0) {
      return NextResponse.json(
        {
          valid: false,
          message: 'Surat dengan nomor/kode tersebut tidak ditemukan atau belum terdaftar dalam sistem resmi.'
        },
        { status: 404 }
      );
    }

    const letter = result.rows[0];

    return NextResponse.json({
      valid: true,
      data: {
        nomorSurat: letter.nomorSurat || cleanNumber,
        tanggalSurat: letter.tanggalSurat
          ? new Date(letter.tanggalSurat).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })
          : '-',
        jenisSurat: letter.jenisSurat || 'Surat Keluar / Resmi',
        perihal: letter.perihal || '-',
        instansiPenerbit: letter.instansiPenerbit || 'STT Pekerjaan Umum Jakarta',
        unitBagian: letter.unitBagian || 'Bagian Akademik',
        penandatangan: 'Kepala Bagian / Pimpinan',
        statusVerifikasi: 'Valid / Resmi Diterbitkan',
        pdfUrl: letter.filePath ? `/storage/${letter.filePath}` : null
      }
    });
  } catch (error) {
    console.error('Error verification API:', error);
    return NextResponse.json(
      {
        valid: false,
        message: 'Terjadi kesalahan sistem saat memeriksa data surat.'
      },
      { status: 500 }
    );
  }
}
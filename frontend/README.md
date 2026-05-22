# Frontend E-Office Next.js

Front-end ini sudah dibuat sebagai aplikasi Next.js App Router.

## Menjalankan Lokal

Pastikan Node.js dan npm sudah terpasang.

```bash
npm install
npm run dev
```

Buka `http://localhost:3000`.

Jika terminal IDE lama belum mengenali `node` atau `npm` setelah instalasi Node.js, jalankan lewat launcher lokal:

```powershell
.\install.ps1
.\dev.ps1
```

## Akun Demo

- Username: bebas, contoh `operator`
- Password: `password`
- Role: User, Operator, Pimpinan, Administrator, atau Pegawai

## Fitur UI

- Login demo dengan validasi field.
- Dashboard sesuai role.
- Navigasi role-based.
- Modul ajuan surat, surat masuk, surat keluar, disposisi, approval, arsip, laporan, pengguna, audit trail, dan notifikasi.
- Filter tabel, pagination visual, modal konfirmasi, catatan wajib saat reject, preview dokumen, serta validasi upload ekstensi dan ukuran maksimal 10 MB.

## Struktur Utama

- `app/layout.js`: metadata dan root layout.
- `app/page.js`: UI interaktif E-Office.
- `app/globals.css`: tema biru muda dan responsive layout.

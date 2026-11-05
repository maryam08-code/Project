# Penomoran dan penyimpanan surat

Kolom **Nomor** adalah angka otomatis dari PostgreSQL dengan urutan sendiri per entitas. Nomor tetap sama saat data difilter, diperbarui, dibuka ulang, atau diakses dari perangkat lain. Nomor Surat resmi dan referensi ajuan tetap terpisah. UUID `id` dipertahankan sebagai kunci relasi internal. Nomor tidak didaur ulang dan dapat memiliki celah setelah pembatalan transaksi atau penghapusan.

## Penyimpanan terpusat

Sesi login backend memakai `letter_requests`, `outgoing_letters`, `documents`, dan `archives`. Field utama, pemilik, status, nomor, dan pelaku proses memakai kolom relasional; `frontend_data` menyimpan metadata tambahan antarmuka. Byte PDF tersimpan pada `documents.content`; JSON hanya menyimpan referensi unduhan yang memerlukan autentikasi. Maksimal setiap PDF 10 MB. File harus berekstensi PDF, memiliki MIME application/pdf dan header PDF yang sesuai. Form mengirim byte dokumen yang sama sekali saja meskipun ditampilkan sebagai field tunggal sekaligus daftar.

Ajuan hanya dapat dibuat User/Pegawai dan diedit pemilik saat draft atau revisi. Pimpinan memberi keputusan. Operator memproses surat dan menyimpan nomor/dokumen final sesudah persetujuan. Pemeriksaan versi menolak perubahan dari tampilan lama dengan HTTP 409. Percobaan ulang pembuatan dengan referensi klien yang sama tidak membuat surat ganda. Perubahan menghasilkan audit dan notifikasi dalam transaksi yang sama.

Arsip surat masuk dibuat otomatis di database saat registrasi bernomor. Arsip ajuan/surat keluar dibuat setelah operator menyelesaikan penomoran dan publikasi final. Nomor, kode unik, dan hash dokumen final harus sesuai dengan publikasi. Akses arsip/dokumen mengikuti pemilik, tujuan disposisi, atau peran staf. Daftar API mendukung paginasi; frontend memuat halaman secara bertahap dan memperbarui data setiap 15 detik serta saat jendela kembali aktif. Backend yang tidak tersedia menghasilkan pesan gagal; sesi nyata tidak mengganti data dengan contoh browser.

## Data browser lama

Data lama tidak dihapus. Jika akun memiliki data ajuan lokal atau operator memiliki surat keluar lokal selain contoh bawaan, tersedia tombol **Impor sebagai Draft**. Impor menyimpan referensi/status lama sebagai informasi, memberikan nomor database, dan membawa dokumen yang masih tersedia di browser. Surat perlu diperiksa dan diajukan kembali; status persetujuan dari browser tidak otomatis menjadi keputusan server. Impor dapat dicoba ulang tanpa menggandakan surat. Dokumen yang sudah hilang dari browser tidak dapat dipulihkan secara otomatis. Mode demo tetap menggunakan penyimpanan browser.

## Migrasi dan pemeriksaan

`010_record_numbers.sql` menambahkan nomor. `011_letter_persistence.sql` dan `014_letter_client_references.sql` menambahkan metadata, isi dokumen, versi, referensi percobaan ulang, dan arsip otomatis. Migrasi `012`, `013`, `015`, dan `016` memulihkan nama kolom yang berbeda pada database lama sesuai nama yang dipakai kode, tanpa menghapus baris atau memutus relasi.

Jalankan `npm run migrate` dari backend. Pengujian integrasi: `npm run test:letters`. Pengujian memakai skema sementara terpisah dan menghapus skema uji setelah selesai; membutuhkan izin membuat skema pada database pengembangan. Pengujian meliputi alur ajuan dan surat keluar hingga arsip, PDF, pembatasan peran/pemilik, versi basi, paginasi, impor idempoten, dan pembuatan bersamaan. Build frontend: `npm run build`. Pengujian interaksi browser secara manual belum dijalankan.

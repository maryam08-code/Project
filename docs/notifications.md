# Notifikasi portal

Notifikasi tersedia melalui lonceng header untuk Administrator, Operator, Pimpinan, User, dan Pegawai, tanpa menu tambahan di sidebar atau ringkasan di bawah dashboard. Data diambil dari API dengan token akun aktif; tidak ada notifikasi contoh atau penggabungan data antar akun melalui localStorage.

- Pembaruan otomatis setiap 30 detik ketika tab terlihat, serta saat tab kembali aktif atau koneksi kembali online.
- Daftar 10 notifikasi per halaman dan filter belum dibaca.
- Tandai satu atau semua notifikasi dibaca, tersimpan di database dan audit log.
- Tombol membuka modul terkait hanya muncul jika modul tersedia bagi role tersebut. Tombol membuka daftar modul, bukan langsung detail dokumen.
- Waktu ditampilkan dalam Asia/Jakarta.
- Logout/pergantian akun membuang state notifikasi dan membatalkan permintaan daftar yang sedang berjalan.

## Sumber notifikasi yang terhubung

Pemicu backend yang tersedia: email masuk untuk Operator, email yang diproses menjadi surat masuk, surat masuk diteruskan kepada Pimpinan, disposisi dibuat untuk akun tujuan, serta backup berhasil untuk Administrator yang menjalankannya. Portal Pegawai dapat membaca notifikasi yang ditujukan ke akun tersebut; migrasi tidak membuat akun default baru.

Alur ajuan, approval, surat keluar, dan tindak lanjut yang masih berupa state lokal di frontend belum memiliki endpoint workflow persisten. Pemicu PRD untuk alur tersebut masih perlu dihubungkan ketika backend alurnya tersedia. Tidak dibuat endpoint publik untuk mengirim notifikasi ke akun lain.

## Validasi

- `npm run migrate` menerapkan `007_notification_portals.sql`.
- `npm run build` berhasil.
- Tes frontend tujuan notifikasi dan regresi login: 6 lulus.
- Tes API: `cd backend` lalu `node --test scripts/test-notifications.js`. Menggunakan akun dan notifikasi sementara untuk kelima role, kemudian membersihkan hanya data uji tersebut. Mencakup autentikasi, isolasi penerima, pagination, filter, status baca persisten, idempotensi, validasi ID, serta audit.
- Percobaan tes API awal menemukan role Pegawai belum tersedia. Migrasi sudah memperbaikinya; pengujian ulang belum dilakukan karena eksekusi test runner dibatasi sandbox dan izin menjalankan ulang di luar sandbox ditolak.
- Tampilan belum diverifikasi melalui browser otomatis.

-- Initial seed data for local development.
-- This project request uses 4 roles: Administrator, Operator, Pimpinan, User.

INSERT INTO roles (code, name, description) VALUES
  ('administrator', 'Administrator', 'Mengelola pengguna, role, konfigurasi, audit trail, backup, dan master data.'),
  ('operator', 'Operator', 'Meregistrasi surat masuk, memproses ajuan, mengelola surat keluar, dan laporan operasional.'),
  ('pimpinan', 'Pimpinan', 'Membaca surat, membuat disposisi, approval/reject ajuan dan surat keluar.'),
  ('user', 'User', 'Mengajukan surat, melihat status, menerima disposisi, dan mengirim tindak lanjut.')
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  updated_at = now();

INSERT INTO permissions (code, name, module) VALUES
  ('dashboard.read', 'Lihat dashboard', 'dashboard'),
  ('users.manage', 'Kelola pengguna', 'users'),
  ('roles.manage', 'Kelola role dan permission', 'roles'),
  ('letter_requests.create', 'Buat ajuan surat', 'letter_requests'),
  ('letter_requests.read', 'Lihat ajuan surat', 'letter_requests'),
  ('letter_requests.process', 'Proses ajuan surat', 'letter_requests'),
  ('letter_requests.approve', 'Approve/reject ajuan surat', 'letter_requests'),
  ('incoming_letters.create', 'Registrasi surat masuk', 'incoming_letters'),
  ('incoming_letters.read', 'Lihat surat masuk', 'incoming_letters'),
  ('incoming_letters.forward', 'Teruskan surat masuk', 'incoming_letters'),
  ('outgoing_letters.create', 'Buat surat keluar', 'outgoing_letters'),
  ('outgoing_letters.read', 'Lihat surat keluar', 'outgoing_letters'),
  ('outgoing_letters.process', 'Proses surat keluar', 'outgoing_letters'),
  ('outgoing_letters.approve', 'Approve/reject surat keluar', 'outgoing_letters'),
  ('dispositions.create', 'Buat disposisi', 'dispositions'),
  ('dispositions.read', 'Lihat disposisi', 'dispositions'),
  ('dispositions.follow_up', 'Tindak lanjut disposisi', 'dispositions'),
  ('archives.read', 'Lihat arsip digital', 'archives'),
  ('archives.download', 'Download dokumen arsip', 'archives'),
  ('notifications.read', 'Lihat notifikasi', 'notifications'),
  ('reports.read', 'Lihat laporan', 'reports'),
  ('reports.export', 'Export laporan', 'reports'),
  ('audit_logs.read', 'Lihat audit trail', 'audit_logs'),
  ('backups.manage', 'Kelola backup database', 'backups')
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  module = EXCLUDED.module;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON
  r.code = 'administrator'
  OR (r.code = 'operator' AND p.code IN (
    'dashboard.read',
    'letter_requests.read',
    'letter_requests.process',
    'incoming_letters.create',
    'incoming_letters.read',
    'incoming_letters.forward',
    'outgoing_letters.create',
    'outgoing_letters.read',
    'outgoing_letters.process',
    'archives.read',
    'archives.download',
    'notifications.read',
    'reports.read',
    'reports.export'
  ))
  OR (r.code = 'pimpinan' AND p.code IN (
    'dashboard.read',
    'letter_requests.read',
    'letter_requests.approve',
    'incoming_letters.read',
    'outgoing_letters.read',
    'outgoing_letters.approve',
    'dispositions.create',
    'dispositions.read',
    'archives.read',
    'archives.download',
    'notifications.read',
    'reports.read',
    'reports.export'
  ))
  OR (r.code = 'user' AND p.code IN (
    'dashboard.read',
    'letter_requests.create',
    'letter_requests.read',
    'dispositions.read',
    'dispositions.follow_up',
    'archives.read',
    'archives.download',
    'notifications.read'
  ))
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO units (name, description) VALUES
  ('Sistem Informasi', 'Unit pengelola sistem dan administrator.'),
  ('Tata Usaha', 'Unit operator persuratan.'),
  ('Pimpinan', 'Unit pimpinan atau kepala bagian.'),
  ('Kepegawaian', 'Unit pengguna demo untuk ajuan surat.'),
  ('Akademik', 'Unit pemohon dan arsip akademik.'),
  ('Keuangan', 'Unit penerima disposisi dan dokumen.')
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  updated_at = now();

INSERT INTO letter_types (name) VALUES
  ('Surat Undangan'),
  ('Surat Pengumuman'),
  ('Surat Permohonan'),
  ('Surat Keputusan'),
  ('Surat Tugas'),
  ('Surat Edaran'),
  ('Surat Keterangan'),
  ('Surat Izin Penelitian'),
  ('Surat Lainnya')
ON CONFLICT (name) DO UPDATE SET
  is_active = true,
  updated_at = now();

INSERT INTO letter_natures (code, name) VALUES
  ('biasa', 'Biasa'),
  ('penting', 'Penting'),
  ('segera', 'Segera'),
  ('rahasia', 'Rahasia')
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  is_active = true,
  updated_at = now();

INSERT INTO users (role_id, unit_id, full_name, username, email, password_hash, position, status, must_change_password)
SELECT r.id, u.id, seed.full_name, seed.username, seed.email, crypt(seed.password, gen_salt('bf')), seed.position, 'aktif'::user_status, true
FROM (
  VALUES
    ('administrator', 'Sistem Informasi', 'Super Admin', 'admin', 'admin@e-office.local', 'admin123', 'Administrator Sistem'),
    ('operator', 'Tata Usaha', 'Rina Operator', 'operator', 'operator@e-office.local', 'operator123', 'Operator Persuratan'),
    ('pimpinan', 'Pimpinan', 'Dewi Pimpinan', 'pimpinan', 'pimpinan@e-office.local', 'pimpinan123', 'Kepala Bagian'),
    ('user', 'Kepegawaian', 'Budi Santoso', 'user', 'user@e-office.local', 'user123', 'Staf Kepegawaian')
) AS seed(role_code, unit_name, full_name, username, email, password, position)
JOIN roles r ON r.code = seed.role_code
JOIN units u ON u.name = seed.unit_name
ON CONFLICT (username) DO UPDATE SET
  role_id = EXCLUDED.role_id,
  unit_id = EXCLUDED.unit_id,
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  position = EXCLUDED.position,
  status = EXCLUDED.status,
  updated_at = now();

INSERT INTO audit_logs (user_id, activity, module, data_label, metadata)
SELECT u.id, 'seed_database', 'system', 'Initial PostgreSQL schema seed', '{"roles": 4, "timezone": "Asia/Jakarta"}'::jsonb
FROM users u
WHERE u.username = 'admin'
ON CONFLICT DO NOTHING;

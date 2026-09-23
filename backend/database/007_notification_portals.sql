-- Complete the portal roles specified in PRD without creating a default account.
INSERT INTO roles (code, name, description)
VALUES ('pegawai', 'Pegawai', 'Menerima surat dan notifikasi yang ditujukan kepada akun ini.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT roles.id, permissions.id FROM roles
CROSS JOIN permissions
WHERE roles.code = 'pegawai'
  AND permissions.code IN ('dashboard.read', 'notifications.read', 'archives.read', 'archives.download')
ON CONFLICT DO NOTHING;

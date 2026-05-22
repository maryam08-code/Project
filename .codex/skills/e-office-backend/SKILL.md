---
name: e-office-backend
description: Backend implementation guidance for the E-Office project. Use when creating APIs, database migrations, seeders, auth, RBAC, upload/storage handling, audit trail, notifications, reports, exports, validation, and workflow endpoints for surat masuk, surat keluar, ajuan surat, disposisi, archives, and users.
---

# E-Office Backend

Use this skill for server-side implementation. Read `PRD.md` sections 6, 12, 13, 15, 16, 17, 18, 19, 21, 23, 26, and 31 as needed.

## Baseline Data

Seed roles:

- Administrator
- Operator
- Pimpinan
- User
- Pegawai

Seed default users from `PRD.md` section 26.2 for local development only.

Seed master data:

- Jenis surat: Undangan, Pengumuman, Permohonan, Keputusan, Tugas, Edaran, Keterangan, Lainnya.
- Sifat surat: Biasa, Penting, Segera, Rahasia.

## API Modules

Prefer REST endpoints aligned with `PRD.md` section 15:

- `/api/auth/*`
- `/api/users/*`
- `/api/letter-requests/*`
- `/api/incoming-letters/*`
- `/api/outgoing-letters/*`
- `/api/dispositions/*`
- `/api/archives/*`
- `/api/notifications/*`
- `/api/reports/*`
- `/api/audit-logs`

## Database Rules

- Use soft deletes for users and important letter records.
- Store file metadata separately enough to support preview/download authorization.
- Store workflow actor fields: created_by, submitted_by, forwarded_by, approved_by, rejected_by, disposition giver, disposition target.
- Store rejection notes when rejecting ajuan or outgoing letters.
- Store timestamps for submitted, forwarded, approved, rejected, sent, received, followed up, and completed events where useful.

## Security Rules

- Hash passwords.
- Enforce active/inactive account status during login.
- Enforce RBAC in middleware or policy layer and in object-level queries.
- Validate upload extension, MIME type, and max size 10 MB.
- Keep documents inaccessible without authorization checks.
- Protect against SQL injection and XSS through framework validation/escaping.
- Use CSRF protection if session-based auth is selected.

## Audit Trail

Log these actions with user, module, data id, IP address, user agent, and timestamp when available:

- login, logout
- create, update, delete/deactivate
- upload
- submit ajuan
- forward letter
- approve/reject
- create disposition
- receive/follow-up/complete disposition
- download document
- backup

## Done Check

Before finishing backend work, verify:

- Correct roles can access the endpoint.
- Incorrect roles are denied.
- Required validation errors are returned.
- State transitions cannot be skipped improperly.
- Notification and audit side effects run.
- Files cannot be downloaded by unauthorized users.

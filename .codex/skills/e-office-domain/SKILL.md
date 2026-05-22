---
name: e-office-domain
description: Product-domain workflow guidance for the E-Office surat management application. Use when planning or implementing PRD-driven behavior for roles, MVP scope, surat masuk, surat keluar, ajuan surat, disposisi, tindak lanjut, arsip, notification triggers, state machines, acceptance criteria, and delivery sequencing.
---

# E-Office Domain

Use `PRD.md` as the source of truth. Load only the sections needed for the current task.

## Core Roles

- Administrator: users, roles, configuration, master data, audit trail, backup.
- Operator: incoming letter registration, outgoing letter input, forwarding, document checking, operational reports.
- Pimpinan: reads forwarded letters, creates dispositions, approves/rejects submissions, monitors follow-up.
- User: submits letter requests, tracks status, receives dispositions, sends follow-up.
- Pegawai: receives and downloads permitted letters such as invitations or announcements.

## MVP Order

Implement in this order unless the user requests otherwise:

1. Auth, roles, and active-account checks.
2. Dashboard shell by role.
3. User management and seed users.
4. Ajuan surat.
5. Incoming letters and forwarding.
6. Dispositions and follow-up.
7. Basic archive, notifications, and audit trail.
8. Reports/export and document preview.

## State Machines

Keep status labels consistent across database, API, UI, filters, and reports.

- Ajuan surat: `draft -> dikirim -> diproses_operator -> menunggu_approval -> disetujui -> selesai`, with `ditolak` from approval.
- Surat masuk: `diregistrasi -> diteruskan -> didisposisikan -> ditindaklanjuti -> selesai`.
- Surat keluar: `draft -> diperiksa -> menunggu_approval -> disetujui -> dikirim`, with `ditolak` from approval.
- Disposisi: `dikirim -> diterima -> ditindaklanjuti -> selesai`.

## Workflow Events

Create notifications and audit logs for important workflow transitions:

- User submits ajuan surat: notify Operator.
- Operator forwards incoming letter: notify Pimpinan.
- Pimpinan creates disposition: notify target User/Staf.
- User sends follow-up: notify Pimpinan.
- Pimpinan approves/rejects: notify User and Operator.
- Operator sends outgoing letter: notify related recipients where applicable.

## Implementation Habit

For every module, map the PRD into:

- Fields and validation.
- Allowed roles.
- State transitions.
- Required notification.
- Required audit trail entry.
- Archive/document behavior.
- Acceptance criteria and black-box tests.

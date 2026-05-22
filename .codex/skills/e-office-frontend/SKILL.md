---
name: e-office-frontend
description: Frontend implementation guidance for the E-Office web application. Use when building role-based dashboards, navigation, forms, tables, status views, archive search, document preview/download, notification UI, report filters, and responsive operational screens from the PRD.
---

# E-Office Frontend

Use this skill for UI work. Read `PRD.md` sections 5, 6, 7, 11, 16, 17, 18, 19, and 21 as needed.

## Product UI Character

Build an operational office system. Favor clear navigation, compact tables, predictable forms, explicit statuses, and fast task completion.

## Required Screens

- Login.
- Role-based dashboard.
- User management for Administrator.
- Ajuan surat list, create/edit draft, detail, submit, status history.
- Surat masuk list, create, detail, forward to Pimpinan.
- Surat keluar list, create, detail, approve/reject/send flow.
- Disposisi list, create, receive, follow-up, complete.
- Archive list with keyword, date, type, and status filters.
- Notification list and unread indicator.
- Reports with date/type/status filters and export actions.
- Audit log list for Administrator.

## Role Navigation

- User: dashboard, ajuan surat, disposisi masuk/follow-up, arsip permitted, notifications.
- Operator: dashboard, surat masuk, surat keluar, ajuan to process, arsip, reports, notifications.
- Pimpinan: dashboard, incoming review, approvals, dispositions, follow-up monitoring, reports, notifications.
- Administrator: dashboard, users, roles/permissions if implemented, master data, audit logs, backup, reports.
- Pegawai: permitted letters, detail, download if allowed.

## UX Patterns

- Use badges for status and priority.
- Use pagination for data tables.
- Use filters before archive/report tables.
- Use confirmation dialogs for submit, forward, approve, reject, send, deactivate, delete, and complete.
- Require rejection note before reject action.
- Show validation messages near fields.
- Show empty, loading, and error states.
- Hide actions the current role cannot perform.

## Document Handling

- Preview PDF and image files when supported.
- Provide download only when the API authorizes it.
- Show clear fallback for DOC/DOCX preview limitations.

## Done Check

Before finishing frontend work, verify that main workflows can be completed from the UI, role-specific navigation is correct, text fits on desktop/tablet, and API errors are shown clearly.

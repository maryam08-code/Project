# E-Office Project Agent Guide

Use `PRD.md` as the source of truth for product behavior, roles, workflows, acceptance criteria, API recommendations, validation, and testing.

## Project Intent

Build a web-based E-Office system for surat masuk, surat keluar, ajuan surat, disposisi, tindak lanjut, arsip digital, notifikasi, laporan, audit trail, and user management.

Prioritize MVP items first:

1. Login and role access.
2. Simple role-based dashboard.
3. User management.
4. Letter requests.
5. Incoming letter registration and forwarding.
6. Disposition and follow-up.
7. Status tracking.
8. Basic digital archive.
9. Internal notifications.
10. Basic audit trail.

## Recommended Agent Split

Use the project-local agent prompts in `.codex/agents/` when delegating or scoping work:

- `product-architect.md`: requirements slicing, module boundaries, data model, state transitions.
- `backend-engineer.md`: API, database, auth, RBAC, audit trail, upload/storage, reports.
- `frontend-engineer.md`: role-based UI, forms, tables, dashboards, document preview, usability.
- `qa-engineer.md`: black-box scenarios, acceptance criteria, RBAC tests, upload validation, regression checks.
- `docs-release.md`: install guide, API docs, usage docs, final delivery checklist.

## Project Skills

Use these skills when the task matches their scope:

- `$e-office-domain`: product domain, roles, workflows, state machines, MVP slicing.
- `$e-office-backend`: backend API, DB schema, RBAC, audit, storage, exports.
- `$e-office-frontend`: frontend screens, role dashboards, forms, tables, document preview.
- `$e-office-qa`: black-box tests, acceptance criteria coverage, security and workflow validation.

## Execution Rules

- Keep implementation aligned with `PRD.md`; do not silently drop acceptance criteria.
- Use Asia/Jakarta timezone for date/time behavior.
- Use soft delete for important data such as users and letters.
- Validate file extension, MIME type, and size for every upload. Initial max size is 10 MB.
- Store all important actions in audit trail: login, logout, CRUD, upload, submit, approve/reject, disposition, follow-up, download, backup.
- Protect documents from direct unauthenticated access.
- Apply pagination to large tables and filters to archive/report views.
- Implement frontend and backend validation for required fields.
- Check every role boundary explicitly before marking a workflow done.

## Definition of Done

A feature is done only when UI, backend endpoint, database persistence, validation, role access, related notifications, audit trail, error handling, and black-box test coverage are handled for its main flow.

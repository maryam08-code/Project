---
name: e-office-qa
description: QA and black-box testing guidance for the E-Office project. Use when creating or running tests for PRD acceptance criteria, role access, workflow state transitions, upload validation, notifications, audit trail, archives, reports, and MVP delivery readiness.
---

# E-Office QA

Use this skill for verification work. Read `PRD.md` sections 6, 7, 12, 13, 14, 16, 19, 20, 28, and 30 as needed.

## Test Priority

Test these MVP flows first:

- Login success/failure/inactive/empty fields.
- User creates and submits ajuan surat.
- Operator processes ajuan and forwards approval.
- Pimpinan approves/rejects with required rejection note.
- Operator registers incoming letter and forwards it.
- Pimpinan creates disposition.
- User receives and follows up disposition.
- Archive search/filter/download honors role permissions.
- Notifications appear for the correct users only.
- Audit trail records important actions.

## RBAC Checks

For each module, test:

- Authorized role can access list/detail/action.
- Unauthorized role receives forbidden response or hidden UI action.
- User sees only owned/permitted records.
- Administrator-only pages are unavailable to non-admin roles.

## Upload Checks

Test:

- Allowed: PDF, DOC, DOCX, JPG, JPEG, PNG.
- Rejected: executable or unsupported extension.
- Rejected: file larger than 10 MB.
- Rejected or sanitized: mismatched MIME type where framework support exists.
- Unauthorized download fails.

## State Transition Checks

Test that workflow actions update status correctly and prevent invalid jumps:

- Draft ajuan cannot become approved without submission and approval.
- Rejected actions require note.
- Incoming letter must be forwarded before disposition.
- Disposition must be received/followed up before completion.

## Done Check

A feature passes QA when positive and negative tests cover the acceptance criteria, role restrictions are checked, notification and audit side effects are verified, and residual risks are documented.

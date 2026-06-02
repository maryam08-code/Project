# Database

PostgreSQL schema for the E-Office MVP based on `PRD.md` and the current frontend screens.

## Roles

The user request asks for 4 roles, so the seed uses:

- `administrator`
- `operator`
- `pimpinan`
- `user`

`pegawai` from the PRD is intentionally not seeded. If needed later, add it to `roles` and map permissions separately.

## Apply Locally

```powershell
createdb eoffice_db
psql -d eoffice_db -f backend/database/001_schema.sql
psql -d eoffice_db -f backend/database/002_seed.sql
```

Default local users:

| Username | Password |
|---|---|
| admin | admin123 |
| operator | operator123 |
| pimpinan | pimpinan123 |
| user | user123 |

Passwords are hashed with PostgreSQL `pgcrypto` for local development. Replace them through the backend auth flow before production.

# E-Office Backend

Node.js API backend for the E-Office PostgreSQL database.

## Setup

```powershell
cd backend
copy .env.example .env
npm install
npm run migrate
npm run dev
```

API base URL:

```text
http://127.0.0.1:8000/api
```

Useful checks:

```powershell
npm run db:check
```

Database connection uses these `.env` keys:

```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=eoffice_db
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_SSL=false
```

Create the `eoffice_db` database first, then run `npm run migrate`. The migration command reads every `database/NNN_*.sql` file in order and records applied files in `schema_migrations`.

## Initial Endpoints

- `GET /api/health`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `GET /api/roles`
- `GET /api/letter-types`
- `GET /api/letter-natures`
- `GET /api/users` as `administrator`
- `GET /api/audit-logs` as `administrator`

Default local users are seeded in `database/002_seed.sql`.

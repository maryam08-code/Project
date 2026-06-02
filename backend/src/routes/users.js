import { Router } from "express";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { query, withTransaction } from "../db.js";
import { writeAuditLog } from "../utils/audit.js";

export const usersRouter = Router();

usersRouter.get("/", requireAuth, requireRole("administrator"), async (request, response, next) => {
  try {
    const page = Math.max(Number(request.query.page || 1), 1);
    const perPage = Math.min(Math.max(Number(request.query.perPage || 10), 1), 100);
    const offset = (page - 1) * perPage;
    const result = await query(
      `SELECT users.id, users.full_name, users.username, users.email, users.position, users.status,
              roles.name AS role, units.name AS unit
       FROM users
       JOIN roles ON roles.id = users.role_id
       LEFT JOIN units ON units.id = users.unit_id
       WHERE users.deleted_at IS NULL
       ORDER BY users.created_at DESC
       LIMIT $1 OFFSET $2`,
      [perPage, offset]
    );
    response.json({ data: result.rows, meta: { page, perPage } });
  } catch (error) {
    next(error);
  }
});

usersRouter.post("/", requireAuth, requireRole("administrator"), async (request, response, next) => {
  try {
    const { fullName, username, email, password, role, unit, position, status = "aktif" } = request.body || {};
    const requiredErrors = {};
    if (!fullName) requiredErrors.fullName = "Nama lengkap wajib diisi.";
    if (!username) requiredErrors.username = "Username wajib diisi.";
    if (!password) requiredErrors.password = "Password wajib diisi.";
    if (!role) requiredErrors.role = "Role wajib diisi.";
    if (Object.keys(requiredErrors).length > 0) {
      return response.status(422).json({ message: "Validasi gagal.", errors: requiredErrors });
    }

    const rawRole = String(role).toLowerCase();
    const roleCode = rawRole === "admin" ? "administrator" : rawRole;
    const accountStatus = String(status).toLowerCase() === "nonaktif" ? "nonaktif" : "aktif";
    const user = await withTransaction(async (client) => {
      const roleResult = await client.query("SELECT id, code, name FROM roles WHERE code = $1 OR lower(name) = $1", [roleCode]);
      const selectedRole = roleResult.rows[0];
      if (!selectedRole) {
        const error = new Error("Role tidak ditemukan.");
        error.status = 422;
        throw error;
      }

      let unitId = null;
      if (unit) {
        const unitResult = await client.query(
          `INSERT INTO units (name) VALUES ($1)
           ON CONFLICT (name) DO UPDATE SET updated_at = now()
           RETURNING id`,
          [unit]
        );
        unitId = unitResult.rows[0].id;
      }

      const insertResult = await client.query(
        `INSERT INTO users (role_id, unit_id, full_name, username, email, password_hash, position, status, must_change_password, created_by)
         VALUES ($1, $2, $3, $4, NULLIF($5, ''), crypt($6, gen_salt('bf')), $7, $8, true, $9)
         RETURNING id, full_name, username, email, position, status`,
        [selectedRole.id, unitId, fullName, username, email || null, password, position || null, accountStatus, request.user.id]
      );

      return { ...insertResult.rows[0], role: selectedRole.name, unit: unit || null };
    });

    await writeAuditLog({
      userId: request.user.id,
      activity: "create_user",
      module: "users",
      dataId: user.id,
      dataLabel: user.full_name,
      request
    });

    response.status(201).json({ data: user });
  } catch (error) {
    if (error.code === "23505") {
      return response.status(409).json({ message: "Username atau email sudah digunakan." });
    }
    next(error);
  }
});

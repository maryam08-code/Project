import { Router } from "express";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { query } from "../db.js";

export const auditLogsRouter = Router();

auditLogsRouter.get("/", requireAuth, requireRole("administrator"), async (request, response, next) => {
  try {
    const page = Math.max(Number(request.query.page || 1), 1);
    const perPage = Math.min(Math.max(Number(request.query.perPage || 20), 1), 100);
    const offset = (page - 1) * perPage;
    const result = await query(
      `SELECT audit_logs.id, audit_logs.activity, audit_logs.module, audit_logs.data_label,
              audit_logs.metadata, audit_logs.ip_address, audit_logs.user_agent, audit_logs.created_at,
              users.full_name AS user_name
       FROM audit_logs
       LEFT JOIN users ON users.id = audit_logs.user_id
       ORDER BY audit_logs.created_at DESC
       LIMIT $1 OFFSET $2`,
      [perPage, offset]
    );
    response.json({ data: result.rows, meta: { page, perPage } });
  } catch (error) {
    next(error);
  }
});

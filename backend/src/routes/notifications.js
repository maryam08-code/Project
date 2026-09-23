import { Router } from "express";
import { query, withTransaction } from "../db.js";
import { requireAuth } from "../middleware/auth.js";

export const notificationsRouter = Router();

notificationsRouter.get("/", requireAuth, async (request, response, next) => {
  try {
    const page = Math.max(Number.parseInt(request.query.page, 10) || 1, 1);
    const perPage = Math.min(Math.max(Number.parseInt(request.query.perPage, 10) || 20, 1), 100);
    const offset = (page - 1) * perPage;
    const unreadOnly = String(request.query.unreadOnly || "").toLowerCase() === "true";
    const values = [request.user.id];
    const conditions = ["recipient_id = $1"];
    if (unreadOnly) conditions.push("is_read = false");

    const countResult = await query(
      `SELECT count(*)::int AS total_count,
              count(*) FILTER (WHERE is_read = false)::int AS unread_count
       FROM notifications
       WHERE ${conditions.join(" AND ")}`,
      values
    );
    const result = await query(
      `SELECT id, type, title, message, source_type, source_id, is_read, read_at, created_at
       FROM notifications
       WHERE ${conditions.join(" AND ")}
       ORDER BY created_at DESC, id DESC
       LIMIT $2 OFFSET $3`,
      [...values, perPage, offset]
    );
    const totalCount = countResult.rows[0]?.total_count || 0;

    response.json({
      data: result.rows,
      meta: {
        page,
        perPage,
        totalCount,
        totalPages: Math.max(Math.ceil(totalCount / perPage), 1),
        unreadCount: countResult.rows[0]?.unread_count || 0
      }
    });
  } catch (error) {
    next(error);
  }
});

notificationsRouter.post("/:id/read", requireAuth, async (request, response, next) => {
  try {
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(request.params.id)) {
      return response.status(422).json({ message: "ID notifikasi tidak valid." });
    }
    const notification = await withTransaction(async (client) => {
      const existing = await client.query(
        "SELECT id, is_read, read_at FROM notifications WHERE id = $1 AND recipient_id = $2 FOR UPDATE",
        [request.params.id, request.user.id]
      );
      if (!existing.rows[0] || existing.rows[0].is_read) return existing.rows[0];
      const result = await client.query(
        `UPDATE notifications
         SET is_read = true, read_at = COALESCE(read_at, now())
         WHERE id = $1 AND recipient_id = $2
         RETURNING id, is_read, read_at`,
        [request.params.id, request.user.id]
      );
      await client.query(
        `INSERT INTO audit_logs (user_id, activity, module, data_id, ip_address, user_agent)
         VALUES ($1, 'read_notification', 'notifications', $2, $3, $4)`,
        [request.user.id, request.params.id, request.ip, request.get("user-agent") || null]
      );
      return result.rows[0];
    });
    if (!notification) return response.status(404).json({ message: "Notifikasi tidak ditemukan." });
    response.json({ data: notification });
  } catch (error) {
    next(error);
  }
});

notificationsRouter.post("/read-all", requireAuth, async (request, response, next) => {
  try {
    const updatedCount = await withTransaction(async (client) => {
      const result = await client.query(
        `UPDATE notifications
         SET is_read = true, read_at = COALESCE(read_at, now())
         WHERE recipient_id = $1 AND is_read = false
         RETURNING id`,
        [request.user.id]
      );
      if (result.rowCount) {
        await client.query(
          `INSERT INTO audit_logs (user_id, activity, module, metadata, ip_address, user_agent)
           VALUES ($1, 'read_all_notifications', 'notifications', $2, $3, $4)`,
          [request.user.id, JSON.stringify({ updatedCount: result.rowCount }), request.ip, request.get("user-agent") || null]
        );
      }
      return result.rowCount;
    });
    response.json({ data: { updatedCount } });
  } catch (error) {
    next(error);
  }
});

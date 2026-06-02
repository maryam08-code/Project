import { query } from "../db.js";

export async function writeAuditLog({ userId, activity, module, dataId = null, dataLabel = null, metadata = {}, request = null }) {
  await query(
    `INSERT INTO audit_logs (user_id, activity, module, data_id, data_label, metadata, ip_address, user_agent)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [
      userId,
      activity,
      module,
      dataId,
      dataLabel,
      JSON.stringify(metadata),
      request?.ip || null,
      request?.get?.("user-agent") || null
    ]
  );
}

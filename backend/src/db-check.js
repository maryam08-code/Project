import { closePool, query } from "./db.js";

try {
  const result = await query("SELECT now() AS server_time, current_database() AS database_name");
  console.log(JSON.stringify(result.rows[0], null, 2));
} finally {
  await closePool();
}

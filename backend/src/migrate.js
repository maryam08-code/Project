import crypto from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { closePool, withTransaction } from "./db.js";

const currentFile = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFile);
const migrationsDir = path.resolve(currentDir, "..", "database");

function checksum(content) {
  return crypto.createHash("sha256").update(content).digest("hex");
}

try {
  const files = (await readdir(migrationsDir))
    .filter((file) => /^\d+_.+\.sql$/.test(file))
    .sort();

  if (files.length === 0) {
    console.log("No migration files found.");
    process.exitCode = 0;
  } else {
    await withTransaction(async (client) => {
      await client.query(`
        CREATE TABLE IF NOT EXISTS schema_migrations (
          id bigserial PRIMARY KEY,
          filename varchar(255) NOT NULL UNIQUE,
          checksum_sha256 varchar(64) NOT NULL,
          executed_at timestamptz NOT NULL DEFAULT now()
        )
      `);

      for (const file of files) {
        const fullPath = path.join(migrationsDir, file);
        const sql = await readFile(fullPath, "utf8");
        const hash = checksum(sql);
        const existing = await client.query("SELECT checksum_sha256 FROM schema_migrations WHERE filename = $1", [file]);

        if (existing.rows[0]) {
          if (existing.rows[0].checksum_sha256 !== hash) {
            throw new Error(`Migration ${file} was already applied with a different checksum.`);
          }
          console.log(`Skipped ${file}`);
          continue;
        }

        console.log(`Applying ${file}`);
        await client.query(sql);
        await client.query("INSERT INTO schema_migrations (filename, checksum_sha256) VALUES ($1, $2)", [file, hash]);
      }
    });
  }
} finally {
  await closePool();
}

import dotenv from "dotenv";

dotenv.config();

function readBoolean(value, fallback = false) {
  if (value === undefined || value === null || value === "") return fallback;
  return ["1", "true", "yes", "on"].includes(String(value).toLowerCase());
}

function readNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export const config = {
  app: {
    name: process.env.APP_NAME || "E-Office",
    env: process.env.APP_ENV || "local",
    port: readNumber(process.env.APP_PORT, 8000),
    frontendUrls: (process.env.FRONTEND_URL || "http://localhost:3000,http://127.0.0.1:3000")
      .split(",")
      .map((url) => url.trim())
      .filter(Boolean),
    timezone: process.env.TIMEZONE || "Asia/Jakarta",
    jwtSecret: process.env.JWT_SECRET || "change_this_secret",
    maxUploadSize: readNumber(process.env.MAX_UPLOAD_SIZE, 10 * 1024 * 1024)
  },
  db: {
    host: process.env.DB_HOST || "127.0.0.1",
    port: readNumber(process.env.DB_PORT, 5432),
    database: process.env.DB_DATABASE || "eoffice_db",
    user: process.env.DB_USERNAME || "postgres",
    password: process.env.DB_PASSWORD || "postgres",
    ssl: readBoolean(process.env.DB_SSL, false) ? { rejectUnauthorized: false } : false
  }
};

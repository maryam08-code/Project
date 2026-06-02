import { Router } from "express";
import { query } from "../db.js";

export const healthRouter = Router();

healthRouter.get("/health", async (_request, response, next) => {
  try {
    const result = await query("SELECT now() AS database_time");
    response.json({
      status: "ok",
      database: "connected",
      databaseTime: result.rows[0].database_time
    });
  } catch (error) {
    next(error);
  }
});

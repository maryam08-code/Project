import { Router } from "express";
import { requireAuth } from "../middleware/auth.js";
import { query } from "../db.js";

export const metaRouter = Router();

metaRouter.get("/roles", requireAuth, async (_request, response, next) => {
  try {
    const result = await query("SELECT code, name, description FROM roles ORDER BY name");
    response.json({ data: result.rows });
  } catch (error) {
    next(error);
  }
});

metaRouter.get("/letter-types", requireAuth, async (_request, response, next) => {
  try {
    const result = await query("SELECT id, name FROM letter_types WHERE is_active = true ORDER BY name");
    response.json({ data: result.rows });
  } catch (error) {
    next(error);
  }
});

metaRouter.get("/letter-natures", requireAuth, async (_request, response, next) => {
  try {
    const result = await query("SELECT id, code, name FROM letter_natures WHERE is_active = true ORDER BY name");
    response.json({ data: result.rows });
  } catch (error) {
    next(error);
  }
});

import express from 'express';
import { verifyLetter } from '../controllers/verificationController.js';

const router = express.Router();

// Endpoint publik tanpa middleware JWT/Auth
router.get('/verify/:letterNumber', verifyLetter);

export default router;
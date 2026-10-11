import express from 'express';
import { verifyLetter } from '../controllers/verificationController.js';
import { verifyFinalLetter, previewFinalDocument } from './final-letters.js';

const router = express.Router();
router.get('/verify/:letterNumber', verifyLetter);
router.post('/verify-final', verifyFinalLetter);
router.post('/verify-final/document', previewFinalDocument);
export default router;

import { Router } from 'express';
import { register, login, getMe } from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();
router.get('/health', (_req, res) => res.json({ status: 'ok' }));
router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticate, getMe);

export default router;

import { Router } from 'express';
import { authenticate, requireAdmin } from '../middleware/auth';
import {
  setShutdown, getShutdown, setForceUpdate, getForceUpdate,
  getUsers, deleteUser, getStats
} from '../controllers/adminController';

const router = Router();
router.get('/stats', authenticate, requireAdmin, getStats);
router.get('/shutdown', getShutdown);
router.post('/shutdown', authenticate, requireAdmin, setShutdown);
router.get('/force-update', getForceUpdate);
router.post('/force-update', authenticate, requireAdmin, setForceUpdate);
router.get('/users', authenticate, requireAdmin, getUsers);
router.delete('/users/:id', authenticate, requireAdmin, deleteUser);

export default router;

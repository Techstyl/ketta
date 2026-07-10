import { Router } from 'express';
import { authenticate, requireAdmin } from '../middleware/auth';
import {
  setShutdown, getShutdown, setForceUpdate, getForceUpdate,
  getUsers, deleteUser, getStats, getProducts, deleteProductAdmin
} from '../controllers/adminController';

const router = Router();
router.get('/stats', authenticate, requireAdmin, getStats);
router.get('/shutdown', getShutdown);
router.post('/shutdown', authenticate, requireAdmin, setShutdown);
router.get('/force-update', getForceUpdate);
router.post('/force-update', authenticate, requireAdmin, setForceUpdate);
router.get('/products', authenticate, requireAdmin, getProducts);
router.delete('/products/:id', authenticate, requireAdmin, deleteProductAdmin);
router.get('/users', authenticate, requireAdmin, getUsers);
router.delete('/users/:id', authenticate, requireAdmin, deleteUser);

export default router;

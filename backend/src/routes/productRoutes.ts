import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { authenticate } from '../middleware/auth';
import {
  getProducts, getMyProducts, createProduct, updateProduct,
  deleteProduct, getProductById, markAsSold, getCategories
} from '../controllers/productController';

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, 'uploads/'),
  filename: (_, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.random().toString(36).substring(2, 8)}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

const router = Router();
router.get('/', getProducts);
router.get('/categories', getCategories);
router.get('/my', authenticate, getMyProducts);
router.get('/:id', getProductById);
router.post('/', authenticate, upload.array('images', 5), createProduct);
router.put('/:id', authenticate, upload.array('images', 5), updateProduct);
router.delete('/:id', authenticate, deleteProduct);
router.put('/:id/sold', authenticate, markAsSold);

export default router;

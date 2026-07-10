import { Response } from 'express';
import { pool } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { uploadToCloudinary } from '../config/cloudinary';

export async function getProducts(req: AuthRequest, res: Response) {
  try {
    const { category, search } = req.query;
    let query = `
      SELECT p.*, u.username as farmer_name, u.location as farmer_location
      FROM products p JOIN users u ON p.farmer_id = u.id
      WHERE p.status = 'active'
    `;
    const params: any[] = [];
    let paramIndex = 1;

    if (category) {
      query += ` AND p.category_id = $${paramIndex++}`;
      params.push(parseInt(category as string));
    }
    if (search) {
      query += ` AND p.title ILIKE $${paramIndex++}`;
      params.push(`%${search}%`);
    }

    query += ' ORDER BY p.created_at DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('GetProducts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getMyProducts(req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      'SELECT * FROM products WHERE farmer_id = $1 ORDER BY created_at DESC',
      [req.userId]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('GetMyProducts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function createProduct(req: AuthRequest, res: Response) {
  try {
    const { categoryId, title, description, quantity, unit, price, location, paymentMethods } = req.body;
    const files = req.files as Express.Multer.File[] | undefined;
    let images: string[] = [];
    if (files && files.length > 0) {
      const urls = await Promise.all(files.map(f => uploadToCloudinary(f.path)));
      images = urls.filter((u): u is string => u !== null);
      if (images.length === 0) {
        images = files.map(f => `/uploads/${f.filename}`);
      }
    }
    const pm = typeof paymentMethods === 'string' ? JSON.parse(paymentMethods) : (paymentMethods || []);

    const result = await pool.query(
      `INSERT INTO products (farmer_id, category_id, title, description, quantity, unit, price, location, images, payment_methods)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
      [req.userId, categoryId, title, description, quantity, unit || 'Quintal', price, location, images, pm]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('CreateProduct error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function updateProduct(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    let { title, description, quantity, unit, price, location, status, categoryId, paymentMethods, keepImages, existingImages } = req.body;
    if (paymentMethods && typeof paymentMethods === 'string') paymentMethods = JSON.parse(paymentMethods);

    const existing = await pool.query('SELECT * FROM products WHERE id = $1 AND farmer_id = $2', [id, req.userId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found or not yours' });
    }

    let images = existing.rows[0].images || [];
    if (existingImages) {
      if (typeof existingImages === 'string') existingImages = JSON.parse(existingImages);
      if (Array.isArray(existingImages)) images = existingImages;
    }
    const files = req.files as Express.Multer.File[] | undefined;
    if (files && files.length > 0) {
      const urls = await Promise.all(files.map(f => uploadToCloudinary(f.path)));
      const newImages = urls.filter((u): u is string => u !== null);
      images = [...images, ...(newImages.length > 0 ? newImages : files.map(f => `/uploads/${f.filename}`))];
    }

    const result = await pool.query(
      `UPDATE products SET title = COALESCE($1, title), description = COALESCE($2, description),
       quantity = COALESCE($3, quantity), unit = COALESCE($4, unit), price = COALESCE($5, price),
       location = COALESCE($6, location), status = COALESCE($7, status), category_id = COALESCE($8, category_id),
       payment_methods = COALESCE($10, payment_methods), images = $11
       WHERE id = $9 RETURNING *`,
      [title, description, quantity, unit, price, location, status, categoryId, id, paymentMethods, images]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('UpdateProduct error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function deleteProduct(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'DELETE FROM products WHERE id = $1 AND farmer_id = $2 RETURNING id',
      [id, req.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found or not yours' });
    }
    res.json({ message: 'Deleted' });
  } catch (error) {
    console.error('DeleteProduct error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getProductById(req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      'SELECT p.*, u.username as farmer_name, u.location as farmer_location, u.phone as farmer_phone FROM products p JOIN users u ON p.farmer_id = u.id WHERE p.id = $1',
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('GetProduct error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function markAsSold(req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      "UPDATE products SET status = 'sold' WHERE id = $1 AND farmer_id = $2 RETURNING *",
      [req.params.id, req.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('MarkSold error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getCategories(_req: AuthRequest, res: Response) {
  try {
    const result = await pool.query('SELECT * FROM categories ORDER BY id');
    res.json(result.rows);
  } catch (error) {
    console.error('GetCategories error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

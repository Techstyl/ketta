import { Response } from 'express';
import { pool } from '../config/database';
import { AuthRequest } from '../middleware/auth';

export async function setShutdown(req: AuthRequest, res: Response) {
  try {
    const { value, message } = req.body;
    await pool.query(
      `INSERT INTO app_settings (key, value, message, updated_at)
       VALUES ('shutdown', $1, $2, NOW())
       ON CONFLICT (key) DO UPDATE SET value = $1, message = $2, updated_at = NOW()`,
      [value.toString(), message || '']
    );
    res.json({ message: 'Updated' });
  } catch (error) {
    console.error('SetShutdown error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getShutdown(_req: AuthRequest, res: Response) {
  try {
    const result = await pool.query("SELECT value, message FROM app_settings WHERE key = 'shutdown'");
    if (result.rows.length === 0) {
      return res.json({ value: false, message: '' });
    }
    res.json({
      value: result.rows[0].value === 'true',
      message: result.rows[0].message || '',
    });
  } catch (error) {
    console.error('GetShutdown error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function setForceUpdate(req: AuthRequest, res: Response) {
  try {
    const { version } = req.body;
    await pool.query(
      `INSERT INTO app_settings (key, value, updated_at)
       VALUES ('force_update', $1, NOW())
       ON CONFLICT (key) DO UPDATE SET value = $1, updated_at = NOW()`,
      [version]
    );
    res.json({ message: 'Updated' });
  } catch (error) {
    console.error('SetForceUpdate error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getForceUpdate(_req: AuthRequest, res: Response) {
  try {
    const result = await pool.query("SELECT value FROM app_settings WHERE key = 'force_update'");
    res.json({ version: result.rows[0]?.value || null });
  } catch (error) {
    console.error('GetForceUpdate error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getUsers(_req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      'SELECT id, username, user_type, full_name, phone, location, profile_image, created_at FROM users ORDER BY created_at DESC'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('GetUsers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function deleteUser(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
    res.json({ message: 'Deleted' });
  } catch (error) {
    console.error('DeleteUser error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getStats(_req: AuthRequest, res: Response) {
  try {
    const [users, products, active, sold, inquiries] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM users'),
      pool.query('SELECT COUNT(*) FROM products'),
      pool.query("SELECT COUNT(*) FROM products WHERE status = 'active'"),
      pool.query("SELECT COUNT(*) FROM products WHERE status = 'sold'"),
      pool.query('SELECT COUNT(*) FROM conversations'),
    ]);
    res.json({
      users: parseInt(users.rows[0].count),
      products: parseInt(products.rows[0].count),
      active: parseInt(active.rows[0].count),
      sold: parseInt(sold.rows[0].count),
      inquiries: parseInt(inquiries.rows[0].count),
    });
  } catch (error) {
    console.error('GetStats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

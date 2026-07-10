import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../config/database';
import { config } from '../config/env';

export async function register(req: Request, res: Response) {
  try {
    const { username, password, userType, fullName, phone, location } = req.body;

    if (!username || !password || !userType) {
      return res.status(400).json({ error: 'Username, password, and userType required' });
    }
    if (!['farmer', 'buyer', 'admin'].includes(userType)) {
      return res.status(400).json({ error: 'Invalid user type' });
    }

    const existing = await pool.query('SELECT id FROM users WHERE username = $1', [username]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Username already taken' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO users (username, password_hash, user_type, full_name, phone, location)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, username, user_type, full_name, phone, location, created_at`,
      [username, passwordHash, userType, fullName || null, phone || null, location || null]
    );

    const user = result.rows[0];
    const token = jwt.sign(
      { userId: user.id, userType: user.user_type, username: user.username },
      config.jwtSecret,
      { expiresIn: '30d' }
    );

    res.status(201).json({ token, user });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const result = await pool.query(
      'SELECT id, username, password_hash, user_type, full_name, phone, location, profile_image, created_at FROM users WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const token = jwt.sign(
      { userId: user.id, userType: user.user_type, username: user.username },
      config.jwtSecret,
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        userType: user.user_type,
        fullName: user.full_name,
        phone: user.phone,
        location: user.location,
        profileImage: user.profile_image,
        createdAt: user.created_at,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getMe(req: any, res: Response) {
  try {
    const result = await pool.query(
      'SELECT id, username, user_type, full_name, phone, location, profile_image, created_at FROM users WHERE id = $1',
      [req.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('GetMe error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

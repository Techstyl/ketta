import { Response } from 'express';
import { pool } from '../config/database';
import { AuthRequest } from '../middleware/auth';

export async function createConversation(req: AuthRequest, res: Response) {
  try {
    const { productId, productTitle, farmerId, farmerName } = req.body;

    const existing = await pool.query(
      'SELECT * FROM conversations WHERE product_id = $1 AND buyer_id = $2 AND farmer_id = $3',
      [productId, req.userId, farmerId]
    );
    if (existing.rows.length > 0) {
      return res.json(existing.rows[0]);
    }

    const result = await pool.query(
      `INSERT INTO conversations (product_id, product_title, buyer_id, buyer_name, farmer_id, farmer_name)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [productId, productTitle, req.userId, req.username, farmerId, farmerName]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('CreateConversation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getConversations(req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      'SELECT * FROM conversations WHERE buyer_id = $1 OR farmer_id = $1 ORDER BY last_message_at DESC',
      [req.userId]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('GetConversations error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getMessages(req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      'SELECT * FROM messages WHERE conversation_id = $1 ORDER BY created_at ASC',
      [req.params.conversationId]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('GetMessages error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function sendMessage(req: AuthRequest, res: Response) {
  try {
    const { conversationId, content, imageUrl } = req.body;

    const msgResult = await pool.query(
      `INSERT INTO messages (conversation_id, sender_id, content, image_url, type)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [conversationId, req.userId, content, imageUrl || null, imageUrl ? 'image' : 'text']
    );

    await pool.query(
      'UPDATE conversations SET last_message = $1, last_message_at = NOW() WHERE id = $2',
      [content, conversationId]
    );

    res.status(201).json(msgResult.rows[0]);
  } catch (error) {
    console.error('SendMessage error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function markAsRead(req: AuthRequest, res: Response) {
  try {
    const { messageId } = req.body;
    await pool.query('UPDATE messages SET read_at = NOW() WHERE id = $1', [messageId]);
    res.json({ message: 'Read' });
  } catch (error) {
    console.error('MarkRead error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getInquiryCount(req: AuthRequest, res: Response) {
  try {
    const result = await pool.query(
      'SELECT COUNT(*) FROM conversations WHERE farmer_id = $1',
      [req.userId]
    );
    res.json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    console.error('InquiryCount error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { config } from '../config/env';
import { pool } from '../config/database';

interface AuthSocket extends Socket {
  userId?: string;
  username?: string;
}

export function setupSocket(io: Server) {
  io.use((socket: AuthSocket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('No token'));
    try {
      const decoded = jwt.verify(token, config.jwtSecret) as any;
      socket.userId = decoded.userId;
      socket.username = decoded.username;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket: AuthSocket) => {
    console.log(`User connected: ${socket.username}`);

    socket.on('join:conversation', (conversationId: string) => {
      socket.join(`conv:${conversationId}`);
    });

    socket.on('leave:conversation', (conversationId: string) => {
      socket.leave(`conv:${conversationId}`);
    });

    socket.on('send:message', async (data: {
      conversationId: string;
      content: string;
      imageUrl?: string;
    }) => {
      try {
        const result = await pool.query(
          `INSERT INTO messages (conversation_id, sender_id, content, image_url, type)
           VALUES ($1, $2, $3, $4, $5) RETURNING *`,
          [
            data.conversationId,
            socket.userId,
            data.content,
            data.imageUrl || null,
            data.imageUrl ? 'image' : 'text',
          ]
        );

        await pool.query(
          'UPDATE conversations SET last_message = $1, last_message_at = NOW() WHERE id = $2',
          [data.content, data.conversationId]
        );

        const convResult = await pool.query(
          'SELECT * FROM conversations WHERE id = $1',
          [data.conversationId]
        );
        const conv = convResult.rows[0];

        const message = result.rows[0];
        io.to(`conv:${data.conversationId}`).emit('message:new', message);

        const otherUserId = conv.buyer_id === socket.userId ? conv.farmer_id : conv.buyer_id;
        io.emit('conversation:updated', { conversationId: data.conversationId, lastMessage: data.content });
      } catch (error) {
        console.error('Socket message error:', error);
        socket.emit('error', 'Failed to send message');
      }
    });

    socket.on('typing:start', (conversationId: string) => {
      socket.to(`conv:${conversationId}`).emit('typing', { userId: socket.userId, username: socket.username });
    });

    socket.on('typing:stop', (conversationId: string) => {
      socket.to(`conv:${conversationId}`).emit('typing:stopped', { userId: socket.userId });
    });

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.username}`);
    });
  });
}

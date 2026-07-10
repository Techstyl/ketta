import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
  createConversation, getConversations, getMessages,
  sendMessage, markAsRead, getInquiryCount
} from '../controllers/chatController';

const router = Router();
router.post('/conversations', authenticate, createConversation);
router.get('/conversations', authenticate, getConversations);
router.get('/conversations/:conversationId/messages', authenticate, getMessages);
router.post('/messages', authenticate, sendMessage);
router.put('/messages/read', authenticate, markAsRead);
router.get('/inquiry-count', authenticate, getInquiryCount);

export default router;

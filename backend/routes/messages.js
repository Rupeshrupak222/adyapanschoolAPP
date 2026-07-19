const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/messages — Get messages for the logged-in user
router.get('/', authenticate, async (req, res) => {
  try {
    const email = req.user.email;
    const role = req.user.role;

    let messages;

    if (role === 'admin') {
      messages = await prisma.$queryRawUnsafe(
        `SELECT id, sender_email, sender_name, recipient_type, recipient_email, recipient_role, message, is_read, created_at
         FROM admin_messages
         WHERE (recipient_type = 'individual' AND recipient_email = ?)
            OR (recipient_type = 'broadcast' AND recipient_role = 'admin')
         ORDER BY created_at DESC
         LIMIT 50`,
        email.toLowerCase()
      );
    } else {
      messages = await prisma.$queryRawUnsafe(
        `SELECT id, sender_email, sender_name, recipient_type, recipient_email, recipient_role, message, is_read, created_at
         FROM admin_messages
         WHERE (recipient_type = 'individual' AND recipient_email = ?)
            OR (recipient_type = 'broadcast' AND recipient_role = ?)
         ORDER BY created_at DESC
         LIMIT 50`,
        email.toLowerCase(),
        role.toLowerCase()
      );
    }

    sendResponse(res, 200, true, 'Messages fetched', { messages });
  } catch (err) {
    console.error('Fetch messages error:', err.message);
    sendResponse(res, 500, false, 'Failed to fetch messages');
  }
});

// GET /api/v1/messages/student — Get messages for a student
router.get('/student', authenticate, async (req, res) => {
  try {
    const email = req.query.email || req.user.email;

    const messages = await prisma.$queryRawUnsafe(
      `SELECT id, sender_email, sender_name, message, is_read, created_at
       FROM admin_messages
       WHERE (recipient_type = 'individual' AND recipient_email = ?)
          OR (recipient_type = 'broadcast' AND recipient_role = 'student')
       ORDER BY created_at DESC
       LIMIT 50`,
      email.toLowerCase()
    );

    sendResponse(res, 200, true, 'Messages fetched', { messages });
  } catch (err) {
    console.error('Fetch student messages error:', err.message);
    sendResponse(res, 500, false, 'Failed to fetch messages');
  }
});

// POST /api/v1/messages — Send a message
router.post('/', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    const { recipient_email, recipient_role, message, sender_name } = req.body;

    if (!message?.trim()) {
      return sendResponse(res, 400, false, 'Message is required');
    }

    const senderRole = req.user.role;
    const senderNameFinal = sender_name || req.user.name || senderRole;
    const senderEmail = req.user.email;
    const id = crypto.randomUUID();

    // If recipient_email is a specific email, send individually
    if (recipient_email && recipient_email.includes('@')) {
      await prisma.$executeRawUnsafe(
        `INSERT INTO admin_messages (id, sender_email, sender_name, recipient_type, recipient_email, recipient_role, message)
         VALUES (?, ?, ?, 'individual', ?, ?, ?)`,
        id, senderEmail, senderNameFinal, recipient_email, recipient_role || 'admin', message.trim()
      );
    } else {
      // Broadcast to a role
      const targetRole = recipient_role || recipient_email || 'admin';
      await prisma.$executeRawUnsafe(
        `INSERT INTO admin_messages (id, sender_email, sender_name, recipient_type, recipient_role, message)
         VALUES (?, ?, ?, 'broadcast', ?, ?)`,
        id, senderEmail, senderNameFinal, targetRole, message.trim()
      );
    }

    sendResponse(res, 201, true, 'Message sent successfully');
  } catch (err) {
    console.error('Send message error:', err.message);
    sendResponse(res, 500, false, 'Failed to send message');
  }
});

// PUT /api/v1/messages/:id/read — Mark message as read
router.put('/:id/read', authenticate, async (req, res) => {
  try {
    await prisma.$executeRawUnsafe(
      'UPDATE admin_messages SET is_read = 1 WHERE id = ?',
      req.params.id
    );
    sendResponse(res, 200, true, 'Message marked as read');
  } catch (err) {
    console.error('Mark read error:', err.message);
    sendResponse(res, 500, false, 'Failed to mark message as read');
  }
});

module.exports = router;

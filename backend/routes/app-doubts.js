const express = require('express');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/app-doubts — Fetch doubts (teacher sees assigned, student sees own)
router.get('/', authenticate, async (req, res) => {
  try {
    const { student_email, teacher_id } = req.query;
    const where = {};

    if (req.user.role === 'teacher') {
      where.teacher_id = req.user.id;
    } else if (req.user.role === 'student') {
      where.student_email = req.user.email;
    } else if (teacher_id) {
      where.teacher_id = teacher_id;
    }

    if (student_email) where.student_email = student_email;

    const records = await prisma.app_doubts.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: 100,
    });

    // Format for mobile app
    const result = records.map((r) => ({
      id: r.id,
      studentName: r.student_name,
      studentEmail: r.student_email,
      studentClass: r.student_class,
      subject: r.subject,
      question: r.question,
      replied: r.replied,
      replyText: r.reply_text || '',
      time: r.time,
      attachmentType: r.attachment_type || 'None',
      attachmentName: r.attachment_name || '',
      attachmentPath: r.attachment_path || '',
      replyAttachmentType: r.reply_attachment_type || 'None',
      replyAttachmentName: r.reply_attachment_name || '',
      replyAttachmentPath: r.reply_attachment_path || '',
    }));

    res.json(result);
  } catch (error) {
    console.error('app-doubts GET error:', error.message);
    sendResponse(res, 500, false, 'Failed to fetch doubts.');
  }
});

// POST /api/v1/app-doubts — Student asks a doubt
router.post('/', authenticate, async (req, res) => {
  try {
    const { student_name, student_email, student_class, subject, question, teacher_id, attachment_type, attachment_name, attachment_path } = req.body;

    if (!subject || !question || !teacher_id) {
      return sendResponse(res, 400, false, 'subject, question, teacher_id are required.');
    }

    const record = await prisma.app_doubts.create({
      data: {
        student_name: student_name || req.user.name || '',
        student_email: student_email || req.user.email,
        student_class: student_class || '',
        subject,
        question,
        replied: false,
        time: 'Just now',
        attachment_type: attachment_type || 'None',
        attachment_name: attachment_name || '',
        attachment_path: attachment_path || '',
        teacher_id,
      },
    });

    res.status(201).json({ id: record.id });
  } catch (error) {
    console.error('app-doubts POST error:', error.message);
    sendResponse(res, 500, false, 'Failed to ask doubt.');
  }
});

// PUT /api/v1/app-doubts/:id/solve — Teacher solves a doubt
router.put('/:id/solve', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { reply_text, reply_attachment_type, reply_attachment_name, reply_attachment_path } = req.body;

    if (!reply_text) {
      return sendResponse(res, 400, false, 'reply_text is required.');
    }

    await prisma.app_doubts.update({
      where: { id },
      data: {
        replied: true,
        reply_text,
        time: 'Solved just now',
        reply_attachment_type: reply_attachment_type || 'None',
        reply_attachment_name: reply_attachment_name || '',
        reply_attachment_path: reply_attachment_path || '',
      },
    });

    sendResponse(res, 200, true, 'Doubt solved.');
  } catch (error) {
    console.error('app-doubts solve PUT error:', error.message);
    sendResponse(res, 500, false, 'Failed to solve doubt.');
  }
});

module.exports = router;

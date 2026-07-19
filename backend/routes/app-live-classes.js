const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/app-live-classes — Fetch live classes
router.get('/', authenticate, async (req, res) => {
  try {
    const { teacher_id } = req.query;
    const where = {};

    if (req.user.role === 'teacher') {
      where.OR = [{ teacher_id: req.user.id }, { teacher_id: 'all' }];
    } else if (teacher_id && teacher_id !== 'all') {
      where.OR = [{ teacher_id }, { teacher_id: 'all' }];
    }

    const records = await prisma.app_live_classes.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: 50,
    });

    const result = records.map((r) => ({
      id: r.id,
      subject: r.subject,
      topic: r.topic,
      time: r.time,
      status: r.status,
      isLive: r.is_live,
    }));

    res.json(result);
  } catch (error) {
    console.error('app-live-classes GET error:', error.message);
    sendResponse(res, 500, false, 'Failed to fetch live classes.');
  }
});

// POST /api/v1/app-live-classes — Teacher creates/updates a live class
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { id, subject, topic, time, status, is_live } = req.body;

    if (!subject || !topic || !time) {
      return sendResponse(res, 400, false, 'subject, topic, time are required.');
    }

    const classId = id || crypto.randomUUID();
    const record = await prisma.app_live_classes.upsert({
      where: { id: classId },
      update: { subject, topic, time, status: status || 'Scheduled', is_live: is_live || false },
      create: {
        id: classId,
        subject,
        topic,
        time,
        status: status || 'Scheduled',
        is_live: is_live || false,
        teacher_id: req.user.id,
      },
    });

    res.status(201).json(record);
  } catch (error) {
    console.error('app-live-classes POST error:', error.message);
    sendResponse(res, 500, false, 'Failed to save live class.');
  }
});

// DELETE /api/v1/app-live-classes/:id
router.delete('/:id', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    await prisma.app_live_classes.delete({ where: { id: req.params.id } });
    sendResponse(res, 200, true, 'Live class deleted.');
  } catch (error) {
    console.error('app-live-classes DELETE error:', error.message);
    sendResponse(res, 500, false, 'Failed to delete live class.');
  }
});

module.exports = router;

const express = require('express');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/app-recorded-lectures — Fetch all recorded lectures
router.get('/', authenticate, async (req, res) => {
  try {
    const records = await prisma.app_recorded_lectures.findMany({
      orderBy: { created_at: 'desc' },
      take: 100,
    });

    const result = records.map((r) => ({
      id: r.id,
      title: r.title,
      duration: r.duration,
      teacher: r.teacher,
      emoji: r.emoji,
      videoUrl: r.video_url || '',
    }));

    res.json(result);
  } catch (error) {
    console.error('app-recorded-lectures GET error:', error.message);
    sendResponse(res, 500, false, 'Failed to fetch recorded lectures.');
  }
});

// POST /api/v1/app-recorded-lectures — Teacher adds a recorded lecture
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { title, duration, teacher, emoji, video_url } = req.body;

    if (!title || !duration || !teacher) {
      return sendResponse(res, 400, false, 'title, duration, teacher are required.');
    }

    const record = await prisma.app_recorded_lectures.create({
      data: {
        title,
        duration,
        teacher,
        emoji: emoji || '📹',
        video_url: video_url || '',
      },
    });

    res.status(201).json(record);
  } catch (error) {
    console.error('app-recorded-lectures POST error:', error.message);
    sendResponse(res, 500, false, 'Failed to add recorded lecture.');
  }
});

module.exports = router;

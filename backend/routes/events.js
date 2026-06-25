const express = require('express');
const prisma = require('../lib/dualPrisma');
const router = express.Router();

// GET /api/v1/events
router.get('/', async (req, res) => {
  try {
    const { limit } = req.query;

    const events = await prisma.notifications.findMany({
      orderBy: { created_at: 'desc' },
      take: limit ? parseInt(limit) : 50,
    });

    res.json(events);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/events
router.post('/', async (req, res) => {
  try {
    const { user_email, title, message, channel } = req.body;

    const event = await prisma.notifications.create({
      data: {
        id: require('crypto').randomUUID().replace(/-/g, '').slice(0, 25),
        user_email: user_email || null,
        title,
        message,
        channel: channel || 'email',
        status: 'queued',
      },
    });

    res.status(201).json(event);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/events/:id
router.delete('/:id', async (req, res) => {
  try {
    await prisma.notifications.delete({ where: { id: req.params.id } });
    res.json({ message: 'Event deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

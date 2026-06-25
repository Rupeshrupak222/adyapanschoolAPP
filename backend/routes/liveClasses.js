const express = require('express');
const prisma = require('../lib/dualPrisma');
const router = express.Router();

// GET /api/v1/live-classes
router.get('/', async (req, res) => {
  try {
    const classes = await prisma.teacher_class_sessions.findMany({
      orderBy: { start_time: 'desc' },
    });
    res.json(classes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/live-classes
router.post('/', async (req, res) => {
  try {
    const { teacher_id, title, class_level, subject, start_time, end_time, room, mode, status } = req.body;

    const session = await prisma.teacher_class_sessions.create({
      data: {
        id: require('crypto').randomUUID().replace(/-/g, '').slice(0, 25),
        teacher_id,
        title,
        class_level,
        subject: subject || null,
        start_time: new Date(start_time),
        end_time: end_time ? new Date(end_time) : null,
        room: room || null,
        mode: mode || 'online',
        status: status || 'scheduled',
      },
    });

    res.status(201).json(session);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/live-classes/:id
router.put('/:id', async (req, res) => {
  try {
    const session = await prisma.teacher_class_sessions.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json(session);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/live-classes/:id
router.delete('/:id', async (req, res) => {
  try {
    await prisma.teacher_class_sessions.delete({ where: { id: req.params.id } });
    res.json({ message: 'Live class removed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

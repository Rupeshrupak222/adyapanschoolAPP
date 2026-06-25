const express = require('express');
const prisma = require('../lib/dualPrisma');
const router = express.Router();

// GET /api/v1/leads
router.get('/', async (req, res) => {
  try {
    const leads = await prisma.leads.findMany({
      orderBy: { created_at: 'desc' },
    });
    res.json(leads);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/leads
router.post('/', async (req, res) => {
  try {
    const { type, name, email, phone, school, city, message, class_level, interest } = req.body;

    if (!email || !String(email).includes('@')) {
      return res.status(400).json({ error: 'Valid email required.' });
    }

    const lead = await prisma.leads.create({
      data: {
        id: require('crypto').randomUUID().replace(/-/g, '').slice(0, 25),
        type: type || 'demo',
        name: name || null,
        email,
        phone: phone || null,
        school: school || null,
        city: city || null,
        message: message || null,
        class_level: class_level || null,
        interest: interest || null,
      },
    });

    res.status(201).json({ ok: true, lead });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/leads/:id
router.delete('/:id', async (req, res) => {
  try {
    await prisma.leads.delete({ where: { id: req.params.id } });
    res.json({ message: 'Lead deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

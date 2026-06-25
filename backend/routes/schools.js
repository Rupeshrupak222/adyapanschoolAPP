const express = require('express');
const prisma = require('../lib/dualPrisma');
const router = express.Router();

// GET /api/v1/schools
router.get('/', async (req, res) => {
  try {
    const schools = await prisma.school.findMany({
      orderBy: { created_at: 'desc' },
    });
    res.json(schools);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/schools/:id
router.get('/:id', async (req, res) => {
  try {
    const school = await prisma.school.findUnique({
      where: { id: req.params.id },
    });

    if (!school) return res.status(404).json({ error: 'School not found' });
    res.json(school);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/schools
router.post('/', async (req, res) => {
  try {
    const { name, email, phone, city, address, contact_person, status } = req.body;

    const school = await prisma.school.create({
      data: {
        name,
        email: email || null,
        phone: phone || null,
        city: city || null,
        address: address || null,
        contact_person: contact_person || null,
        status: status || 'lead',
      },
    });

    res.status(201).json(school);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/schools/:id
router.put('/:id', async (req, res) => {
  try {
    const school = await prisma.school.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json(school);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/schools/:id
router.delete('/:id', async (req, res) => {
  try {
    await prisma.school.delete({ where: { id: req.params.id } });
    res.json({ message: 'School removed successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

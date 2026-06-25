const express = require('express');
const prisma = require('../lib/dualPrisma');
const router = express.Router();

// GET /api/v1/teachers
router.get('/', async (req, res) => {
  try {
    const { search, schoolId } = req.query;
    let where = {};

    if (schoolId) where.schoolId = schoolId;
    if (search) {
      where.OR = [
        { teacher_name: { contains: search } },
        { subject: { contains: search } },
      ];
    }

    const teachers = await prisma.teacher.findMany({
      where,
      orderBy: { created_at: 'desc' },
    });

    res.json(teachers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/teachers/:id
router.get('/:id', async (req, res) => {
  try {
    const teacher = await prisma.teacher.findUnique({
      where: { id: req.params.id },
    });

    if (!teacher) return res.status(404).json({ error: 'Teacher not found' });
    res.json(teacher);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/teachers
router.post('/', async (req, res) => {
  try {
    const { teacher_name, email, password_hash, staff_key_hash, subject, phone, schoolId, school_name, assigned_classes } = req.body;

    const teacher = await prisma.teacher.create({
      data: {
        teacher_name,
        email,
        password_hash,
        staff_key_hash,
        subject: subject || null,
        phone: phone || null,
        schoolId,
        school_name,
        assigned_classes: assigned_classes || null,
      },
    });

    res.status(201).json(teacher);
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'Teacher with this email already exists' });
    }
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/teachers/:id
router.put('/:id', async (req, res) => {
  try {
    const teacher = await prisma.teacher.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json(teacher);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/teachers/:id
router.delete('/:id', async (req, res) => {
  try {
    await prisma.teacher.delete({ where: { id: req.params.id } });
    res.json({ message: 'Teacher removed successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

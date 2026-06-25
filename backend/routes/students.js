const express = require('express');
const prisma = require('../lib/dualPrisma');
const router = express.Router();

// GET /api/v1/students
router.get('/', async (req, res) => {
  try {
    const { search, schoolId } = req.query;
    let where = {};

    if (schoolId) where.schoolId = schoolId;
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { class_level: { contains: search } },
      ];
    }

    const students = await prisma.student.findMany({
      where,
      orderBy: { created_at: 'desc' },
    });

    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/students/:id
router.get('/:id', async (req, res) => {
  try {
    const student = await prisma.student.findUnique({
      where: { id: req.params.id },
    });

    if (!student) return res.status(404).json({ error: 'Student not found' });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/students
router.post('/', async (req, res) => {
  try {
    const { name, email, phone, class_level, school_name, parent_name, parent_phone, schoolId } = req.body;

    const student = await prisma.student.create({
      data: {
        name,
        email,
        phone: phone || null,
        class_level: class_level || null,
        school_name: school_name || null,
        parent_name: parent_name || null,
        parent_phone: parent_phone || null,
        schoolId: schoolId || null,
      },
    });

    res.status(201).json(student);
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'Student with this email already exists' });
    }
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/students/:id
router.put('/:id', async (req, res) => {
  try {
    const student = await prisma.student.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/students/:id
router.delete('/:id', async (req, res) => {
  try {
    await prisma.student.delete({ where: { id: req.params.id } });
    res.json({ message: 'Student deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

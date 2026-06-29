const express = require('express');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/app-notes — Fetch notes/PDFs
router.get('/', authenticate, async (req, res) => {
  try {
    const { teacher_id } = req.query;
    const where = {};

    if (req.user.role === 'teacher') {
      where.teacher_id = req.user.id;
    } else if (teacher_id) {
      where.teacher_id = teacher_id;
    }

    const records = await prisma.app_notes.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: 100,
    });

    // Format for mobile app
    const result = records.map((r) => ({
      id: r.id,
      title: r.title,
      subject: r.subject,
      description: r.description || '',
      fileName: r.file_name,
      fileSize: r.file_size,
      pages: r.pages,
      uploadedBy: r.uploaded_by,
      uploadedAt: r.uploaded_at,
      filePath: r.file_path || '',
    }));

    res.json(result);
  } catch (error) {
    console.error('app-notes GET error:', error.message);
    sendResponse(res, 500, false, 'Failed to fetch notes.');
  }
});

// POST /api/v1/app-notes — Teacher adds a note
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { title, subject, description, file_name, file_size, pages, uploaded_by, file_path } = req.body;

    if (!title || !subject || !file_name) {
      return sendResponse(res, 400, false, 'title, subject, file_name are required.');
    }

    const record = await prisma.app_notes.create({
      data: {
        title,
        subject,
        description: description || '',
        file_name,
        file_size: file_size || '0 KB',
        pages: parseInt(pages) || 1,
        uploaded_by: uploaded_by || req.user.name || 'Teacher',
        uploaded_at: 'Just now',
        file_path: file_path || '',
        teacher_id: req.user.id,
      },
    });

    res.status(201).json(record);
  } catch (error) {
    console.error('app-notes POST error:', error.message);
    sendResponse(res, 500, false, 'Failed to create note.');
  }
});

// DELETE /api/v1/app-notes/:id
router.delete('/:id', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    await prisma.app_notes.delete({ where: { id: parseInt(req.params.id) } });
    sendResponse(res, 200, true, 'Note deleted.');
  } catch (error) {
    console.error('app-notes DELETE error:', error.message);
    sendResponse(res, 500, false, 'Failed to delete note.');
  }
});

module.exports = router;

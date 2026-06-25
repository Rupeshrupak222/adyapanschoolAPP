const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/app-homework — Fetch homework (teacher sees their own, student sees all for their class)
router.get('/', authenticate, async (req, res) => {
  try {
    const { teacher_id, class_level } = req.query;
    const where = {};

    if (req.user.role === 'teacher') {
      where.teacher_id = req.user.id;
    } else if (teacher_id) {
      where.teacher_id = teacher_id;
    }

    if (class_level) where.class_level = class_level;

    const records = await prisma.app_homework.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: 100,
    });

    res.json(records);
  } catch (error) {
    console.error('app-homework GET error:', error.message);
    sendResponse(res, 500, false, 'Failed to fetch homework.');
  }
});

// POST /api/v1/app-homework — Teacher creates homework
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { title, subject, description, due_date, priority, added_by, class_level, file_name, file_path, file_url } = req.body;

    if (!title || !subject || !due_date || !priority) {
      return sendResponse(res, 400, false, 'title, subject, due_date, priority are required.');
    }

    const record = await prisma.app_homework.create({
      data: {
        title,
        subject,
        description: description || '',
        due_date,
        priority,
        added_by: added_by || req.user.name || 'Teacher',
        teacher_id: req.user.id,
        class_level: class_level || '',
        file_name: file_name || '',
        file_path: file_path || '',
        file_url: file_url || '',
      },
    });

    res.status(201).json(record);
  } catch (error) {
    console.error('app-homework POST error:', error.message);
    sendResponse(res, 500, false, 'Failed to create homework.');
  }
});

// DELETE /api/v1/app-homework/:id
router.delete('/:id', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    await prisma.app_homework_submissions.deleteMany({ where: { homework_id: id } });
    await prisma.app_homework.delete({ where: { id } });
    sendResponse(res, 200, true, 'Homework deleted.');
  } catch (error) {
    console.error('app-homework DELETE error:', error.message);
    sendResponse(res, 500, false, 'Failed to delete homework.');
  }
});

// ─── SUBMISSIONS ────────────────────────────────────────────────────

// GET /api/v1/app-homework/submissions — Teacher fetches all submissions for their homework
router.get('/submissions', authenticate, async (req, res) => {
  try {
    const { student_email } = req.query;
    const where = {};

    if (req.user.role === 'teacher') {
      where.homework = { teacher_id: req.user.id };
    }
    if (student_email) {
      where.student_email = student_email;
    }

    const submissions = await prisma.app_homework_submissions.findMany({
      where,
      include: { homework: true },
      orderBy: { created_at: 'desc' },
    });

    // Flatten the response for the mobile app
    const result = submissions.map((s) => ({
      id: s.homework_id,
      title: s.homework?.title || '',
      subject: s.homework?.subject || '',
      description: s.homework?.description || '',
      dueDate: s.homework?.due_date || '',
      priority: s.homework?.priority || 'Normal',
      addedBy: s.homework?.added_by || '',
      submitted: true,
      submittedAt: s.submitted_at,
      fileName: s.file_name || '',
      filePath: s.file_path || '',
      studentComment: s.student_comment || '',
      studentName: s.student_name,
      studentEmail: s.student_email,
      grade: s.grade || 'Pending Grade',
      teacherFeedback: s.teacher_feedback || '',
      submission_id: s.id,
    }));

    res.json(result);
  } catch (error) {
    console.error('app-homework submissions GET error:', error.message);
    sendResponse(res, 500, false, 'Failed to fetch submissions.');
  }
});

// POST /api/v1/app-homework/submissions — Student submits homework
router.post('/submissions', authenticate, async (req, res) => {
  try {
    const { homework_id, student_email, student_name, submitted_at, file_name, file_path, student_comment } = req.body;

    if (!homework_id || !student_email || !student_name) {
      return sendResponse(res, 400, false, 'homework_id, student_email, student_name are required.');
    }

    // Delete existing submission for resubmission
    await prisma.app_homework_submissions.deleteMany({
      where: { homework_id: parseInt(homework_id), student_email },
    });

    const submission = await prisma.app_homework_submissions.create({
      data: {
        id: crypto.randomUUID(),
        homework_id: parseInt(homework_id),
        student_email,
        student_name,
        submitted_at: submitted_at || new Date().toISOString(),
        file_name: file_name || '',
        file_path: file_path || '',
        student_comment: student_comment || '',
      },
    });

    res.status(201).json(submission);
  } catch (error) {
    console.error('app-homework submit POST error:', error.message);
    sendResponse(res, 500, false, 'Failed to submit homework.');
  }
});

// PUT /api/v1/app-homework/submissions/grade — Teacher grades a submission
router.put('/submissions/grade', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { homework_id, student_email, grade, feedback } = req.body;

    if (!homework_id || !student_email || !grade) {
      return sendResponse(res, 400, false, 'homework_id, student_email, grade are required.');
    }

    await prisma.app_homework_submissions.updateMany({
      where: { homework_id: parseInt(homework_id), student_email },
      data: { grade, teacher_feedback: feedback || '' },
    });

    sendResponse(res, 200, true, 'Homework graded.');
  } catch (error) {
    console.error('app-homework grade PUT error:', error.message);
    sendResponse(res, 500, false, 'Failed to grade homework.');
  }
});

module.exports = router;

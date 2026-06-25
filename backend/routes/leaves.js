const express = require('express');
const prisma = require('../lib/dualPrisma');
const mysql = require('mysql2/promise');
const router = express.Router();

// Using raw mysql2 for leaves since there's no Prisma model for it yet
// This can be migrated to Prisma later

let pool;
function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.MYSQL_HOST || '127.0.0.1',
      port: Number(process.env.MYSQL_PORT || 4000),
      user: process.env.MYSQL_USER || 'root',
      password: process.env.MYSQL_PASSWORD || '',
      database: process.env.MYSQL_DATABASE || 'preschool',
      ssl: process.env.MYSQL_SSL === 'true' ? { minVersion: 'TLSv1.2', rejectUnauthorized: true } : undefined,
      waitForConnections: true,
      connectionLimit: 5,
    });
  }
  return pool;
}

// GET /api/v1/leaves
router.get('/', async (req, res) => {
  try {
    const { status } = req.query;
    let query = 'SELECT * FROM leave_requests ORDER BY created_at DESC';
    let params = [];

    if (status) {
      query = 'SELECT * FROM leave_requests WHERE status = ? ORDER BY created_at DESC';
      params = [status];
    }

    const [rows] = await getPool().query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/leaves
router.post('/', async (req, res) => {
  try {
    const { teacherName, subject, teacherUid, dates, reason } = req.body;
    const id = require('crypto').randomUUID().replace(/-/g, '').slice(0, 25);

    await getPool().query(
      'INSERT INTO leave_requests (id, teacher_name, subject, teacher_uid, dates, reason, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())',
      [id, teacherName, subject, teacherUid, dates, reason, 'Pending']
    );

    res.status(201).json({ id, teacherName, subject, teacherUid, dates, reason, status: 'Pending' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/leaves/:id
router.put('/:id', async (req, res) => {
  try {
    const { status } = req.body;

    if (!['Approved', 'Rejected', 'Pending'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Use: Pending, Approved, Rejected' });
    }

    await getPool().query('UPDATE leave_requests SET status = ? WHERE id = ?', [status, req.params.id]);
    res.json({ id: req.params.id, status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/leaves/:id
router.delete('/:id', async (req, res) => {
  try {
    await getPool().query('DELETE FROM leave_requests WHERE id = ?', [req.params.id]);
    res.json({ message: 'Leave request deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

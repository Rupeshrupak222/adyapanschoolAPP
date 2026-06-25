const express = require('express');
const mysql = require('mysql2/promise');
const router = express.Router();

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

// GET /api/v1/meetings
router.get('/', async (req, res) => {
  try {
    const [rows] = await getPool().query('SELECT * FROM meetings ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/meetings
router.post('/', async (req, res) => {
  try {
    const { title, hostedBy, duration } = req.body;
    const id = require('crypto').randomUUID().replace(/-/g, '').slice(0, 25);

    await getPool().query(
      'INSERT INTO meetings (id, title, hosted_by, duration, is_active, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
      [id, title || 'Urgent Faculty Meeting', hostedBy || 'Admin', duration || 600, true]
    );

    res.status(201).json({ id, title, hostedBy, duration, isActive: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/meetings/:id
router.put('/:id', async (req, res) => {
  try {
    const { is_active, title } = req.body;
    const updates = [];
    const params = [];

    if (is_active !== undefined) { updates.push('is_active = ?'); params.push(is_active); }
    if (title) { updates.push('title = ?'); params.push(title); }

    if (updates.length === 0) return res.status(400).json({ error: 'No fields to update' });

    params.push(req.params.id);
    await getPool().query(`UPDATE meetings SET ${updates.join(', ')} WHERE id = ?`, params);
    res.json({ id: req.params.id, ...req.body });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

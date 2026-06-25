const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { getPool } = require('../db');

function cleanEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function mapUser(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    phone: row.phone,
    className: row.class_name,
    class_name: row.class_name,
    school: row.school,
    createdAt: row.created_at,
  };
}

function isBcryptHash(value) {
  return /^\$2[aby]\$\d{2}\$/.test(String(value || ''));
}

function detectClientType(req) {
  const explicitType = String(req.body.clientType || req.body.platform || '').trim().toLowerCase();
  if (['mobile', 'web'].includes(explicitType)) return explicitType;

  const userAgent = String(req.get('user-agent') || '').toLowerCase();
  if (/android|iphone|ipad|ipod|mobile/.test(userAgent)) return 'mobile';
  if (userAgent) return 'web';

  return 'unknown';
}

function requireFields(body, fields) {
  const missing = fields.filter((field) => !String(body[field] || '').trim());
  if (missing.length > 0) {
    const err = new Error(`Missing required fields: ${missing.join(', ')}`);
    err.status = 400;
    throw err;
  }
}

async function signup(req, res, next) {
  try {
    const className = req.body.className || req.body.class_name;
    const payload = { ...req.body, className };
    requireFields(payload, ['name', 'email', 'phone', 'className', 'school', 'password']);

    const email = cleanEmail(payload.email);
    const passwordHash = await bcrypt.hash(payload.password, 12);
    const pool = getPool();

    const [existing] = await pool.execute('SELECT id FROM users WHERE LOWER(email) = ? LIMIT 1;', [email]);
    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered',
      });
    }

    const userId = crypto.randomUUID();

    await pool.execute(
      `
        INSERT INTO users (id, name, email, phone, class_name, school, password)
        VALUES (?, ?, ?, ?, ?, ?, ?);
      `,
      [
        userId,
        payload.name.trim(),
        email,
        payload.phone.trim(),
        className.trim(),
        payload.school.trim(),
        passwordHash,
      ],
    );

    const user = {
      id: userId,
      name: payload.name.trim(),
      email,
      phone: payload.phone.trim(),
      className: className.trim(),
      class_name: className.trim(),
      school: payload.school.trim(),
    };

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user,
    });
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    requireFields(req.body, ['email', 'password']);

    const email = cleanEmail(req.body.email);
    const [rows] = await getPool().execute(
      `
        SELECT id, name, email, phone, class_name, school, password, created_at
        FROM users
        WHERE LOWER(email) = ?
        LIMIT 1;
      `,
      [email],
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const user = rows[0];
    const storedPassword = String(user.password || '');
    const submittedPassword = String(req.body.password || '');
    let isPasswordValid = false;
    let shouldUpgradePassword = false;

    if (isBcryptHash(storedPassword)) {
      isPasswordValid = await bcrypt.compare(submittedPassword, storedPassword);
    } else if (storedPassword && storedPassword === submittedPassword) {
      isPasswordValid = true;
      shouldUpgradePassword = true;
    }

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    if (shouldUpgradePassword) {
      const passwordHash = await bcrypt.hash(submittedPassword, 12);
      await getPool().execute('UPDATE users SET password = ? WHERE id = ?;', [passwordHash, user.id]);
      user.password = passwordHash;
    }

    const clientType = detectClientType(req);
    await getPool().execute(
      `
        INSERT INTO login_events (id, user_id, name, email, role, source, status, ip_address, user_agent)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      `,
      [
        crypto.randomUUID(),
        user.id,
        user.name,
        user.email,
        'student',
        clientType,
        'success',
        req.ip || null,
        req.get('user-agent') || null,
      ],
    );

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      clientType,
      user: mapUser(user),
    });
  } catch (error) {
    return next(error);
  }
}

async function loginEvents(req, res, next) {
  try {
    const clientType = String(req.query.clientType || '').trim().toLowerCase();
    const params = [];
    let filter = '';

    if (['mobile', 'web', 'unknown'].includes(clientType)) {
      filter = 'WHERE le.source = ?';
      params.push(clientType);
    }

    const [rows] = await getPool().execute(
      `
        SELECT le.id, le.user_id, COALESCE(u.name, le.name) AS name, le.email, le.source, le.ip_address, le.created_at
        FROM login_events le
        LEFT JOIN users u ON u.id = le.user_id
        ${filter}
        ORDER BY le.created_at DESC
        LIMIT 100;
      `,
      params,
    );

    return res.json({
      success: true,
      loginEvents: rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        name: row.name,
        email: row.email,
        clientType: row.source,
        ipAddress: row.ip_address,
        loggedAt: row.created_at,
      })),
    });
  } catch (error) {
    return next(error);
  }
}

async function loginSummary(_req, res, next) {
  try {
    const [rows] = await getPool().execute(`
      SELECT source, COUNT(*) AS total
      FROM login_events
      GROUP BY source;
    `);

    const summary = { mobile: 0, web: 0, unknown: 0 };
    for (const row of rows) {
      summary[row.source || 'unknown'] = Number(row.total);
    }

    return res.json({
      success: true,
      summary,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  signup,
  login,
  loginEvents,
  loginSummary,
};

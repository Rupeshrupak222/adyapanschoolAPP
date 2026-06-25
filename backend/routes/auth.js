const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/dualPrisma');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/token');
const { hashPassword, verifyPassword, needsRehash, generateAccessKey, hashAccessKey } = require('../utils/password');
const { sendResponse } = require('../utils/response');
const { validateBody, validateEmail, validatePassword } = require('../middleware/validate');
const { recordFailedAttempt, clearFailedAttempts } = require('../utils/progressive-delay');
const { authenticate } = require('../middleware/auth');
const { isLocked, recordFailure, clearFailures } = require('../utils/account-lockout');
const { blacklistToken, isBlacklisted, revokeAllUserTokens } = require('../utils/token-blacklist');
const { logLoginSuccess, logLoginFailed, logAccountLocked, logPasswordChanged, logSuspiciousActivity } = require('../utils/security-logger');
const { generateFingerprint, trackAttempt } = require('../utils/fingerprint');

const router = express.Router();

// ─── POST /api/v1/auth/login ────────────────────────────────────────
router.post('/login', validateBody('email', 'password'), validateEmail, async (req, res) => {
  try {
    const { email, password } = req.body;
    const fingerprint = generateFingerprint(req);
    const ip = req.ip || req.connection?.remoteAddress || 'unknown';

    // 1. Check account lockout
    const lockStatus = isLocked(email);
    if (lockStatus.locked) {
      const minutes = Math.ceil(lockStatus.remainingMs / 60000);
      logLoginFailed({ email, ip, fingerprint, details: `Account locked. ${minutes}min remaining.` });
      return sendResponse(res, 423, false, `Account locked due to too many failed attempts. Try again in ${minutes} minutes.`);
    }

    // 2. Check fingerprint for credential stuffing
    const fpResult = trackAttempt(fingerprint, email);
    if (fpResult.suspicious) {
      logSuspiciousActivity({ email, ip, fingerprint, details: `Credential stuffing detected. ${fpResult.uniqueEmails} unique emails from same client.` });
      return sendResponse(res, 429, false, 'Suspicious activity detected. Please try again later.');
    }

    // 3. Find user
    const user = await prisma.users.findUnique({
      where: { email: email.toLowerCase().trim() },
    });

    if (!user) {
      await recordFailedAttempt(email);
      recordFailure(email);
      logLoginFailed({ email, ip, fingerprint, details: 'User not found' });
      return sendResponse(res, 401, false, 'Invalid email or password');
    }

    // 4. Verify password
    const storedHash = user.password_hash || user.password;
    const isValid = await verifyPassword(password, storedHash);

    if (!isValid) {
      const { attempts } = await recordFailedAttempt(email);
      const lockResult = recordFailure(email);

      if (lockResult.locked) {
        const minutes = Math.ceil(lockResult.lockDurationMs / 60000);
        logAccountLocked({ email, userId: user.id, ip, fingerprint, details: `Locked after ${lockResult.attempts} failures for ${minutes}min` });
        return sendResponse(res, 423, false, `Account locked after ${lockResult.attempts} failed attempts. Try again in ${minutes} minutes.`);
      }

      logLoginFailed({ email, userId: user.id, ip, fingerprint, details: `Wrong password. Attempt ${lockResult.attempts}/${5}` });
      return sendResponse(res, 401, false, 'Invalid email or password', {
        ...(lockResult.attempts >= 3 && { hint: `${5 - lockResult.attempts} attempts remaining before lockout.` }),
      });
    }

    // 5. Success — clear all counters
    clearFailedAttempts(email);
    clearFailures(email);

    // 6. Auto-upgrade to Argon2id
    if (needsRehash(storedHash)) {
      const newHash = await hashPassword(password);
      await prisma.users.update({
        where: { id: user.id },
        data: { password_hash: newHash, password: newHash },
      }).catch(() => {});
    }

    // 7. Log success
    logLoginSuccess({ email, userId: user.id, ip, fingerprint });

    // 8. Record login event in DB (fire-and-forget)
    prisma.login_events.create({
      data: {
        id: crypto.randomUUID(),
        user_id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        source: req.body.platform || detectPlatform(req),
        status: 'success',
        ip_address: ip,
        user_agent: (req.get('user-agent') || '').slice(0, 500),
      },
    }).catch(() => {});

    // 9. Generate tokens
    const token = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    sendResponse(res, 200, true, 'Login successful', {
      token,
      refreshToken,
      user: sanitizeUser(user),
    });
  } catch (err) {
    console.error('Login error:', err.message);
    sendResponse(res, 500, false, 'Internal server error');
  }
});

// ─── POST /api/v1/auth/register ─────────────────────────────────────
router.post('/register', validateBody('name', 'email', 'password'), validateEmail, validatePassword, async (req, res) => {
  try {
    const { name, email, password, phone, role, class_level, class_name, school_name, school_id, school } = req.body;

    // Restrict role assignment — only admin can create non-student accounts
    const allowedSelfRoles = ['student'];
    const assignedRole = allowedSelfRoles.includes(role) ? role : 'student';

    const existing = await prisma.users.findUnique({
      where: { email: email.toLowerCase().trim() },
    });

    if (existing) {
      return sendResponse(res, 409, false, 'User with this email already exists');
    }

    // Hash password with Argon2id
    const password_hash = await hashPassword(password);

    const user = await prisma.users.create({
      data: {
        id: crypto.randomUUID().replace(/-/g, '').slice(0, 25),
        name: name.trim(),
        email: email.toLowerCase().trim(),
        password_hash,
        password: password_hash,
        phone: phone || null,
        role: assignedRole,
        class_level: class_level || null,
        class_name: class_name || null,
        school_name: school_name || school || null,
        school_id: school_id || null,
        signup_source: req.body.platform || detectPlatform(req),
      },
    });

    const token = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    sendResponse(res, 201, true, 'Registration successful', {
      token,
      refreshToken,
      user: sanitizeUser(user),
    });
  } catch (err) {
    console.error('Register error:', err.message);
    sendResponse(res, 500, false, 'Internal server error');
  }
});

// ─── GET /api/v1/auth/me ────────────────────────────────────────────
router.get('/me', authenticate, async (req, res) => {
  try {
    const user = await prisma.users.findUnique({
      where: { id: req.user.id },
      select: {
        id: true, name: true, email: true, role: true, phone: true,
        class_level: true, class_name: true, school_name: true,
        school_id: true, otp_verified: true, created_at: true,
      },
    });

    if (!user) return sendResponse(res, 404, false, 'User not found');
    sendResponse(res, 200, true, 'User fetched', { user });
  } catch (err) {
    console.error('Auth/me error:', err.message);
    sendResponse(res, 500, false, 'Internal server error');
  }
});

// ─── POST /api/v1/auth/refresh ──────────────────────────────────────
router.post('/refresh', validateBody('refreshToken'), async (req, res) => {
  try {
    const { refreshToken } = req.body;

    const decoded = verifyRefreshToken(refreshToken);

    const user = await prisma.users.findUnique({ where: { id: decoded.id } });
    if (!user) return sendResponse(res, 404, false, 'User not found');

    // Issue new access token (short-lived)
    const newToken = generateAccessToken(user);
    sendResponse(res, 200, true, 'Token refreshed', { token: newToken });
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return sendResponse(res, 401, false, 'Invalid or expired refresh token. Please login again.');
    }
    console.error('Refresh error:', err.message);
    sendResponse(res, 500, false, 'Internal server error');
  }
});

// ─── POST /api/v1/auth/change-password ──────────────────────────────
router.post('/change-password', authenticate, validateBody('currentPassword', 'newPassword'), async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (newPassword.length < 6) {
      return sendResponse(res, 400, false, 'New password must be at least 6 characters.');
    }

    const user = await prisma.users.findUnique({ where: { id: req.user.id } });
    if (!user) return sendResponse(res, 404, false, 'User not found');

    const storedHash = user.password_hash || user.password;
    const isValid = await verifyPassword(currentPassword, storedHash);

    if (!isValid) {
      return sendResponse(res, 401, false, 'Current password is incorrect');
    }

    const newHash = await hashPassword(newPassword);
    await prisma.users.update({
      where: { id: user.id },
      data: { password_hash: newHash, password: newHash, updated_at: new Date() },
    });

    // Revoke all existing tokens for this user
    revokeAllUserTokens(user.id);
    logPasswordChanged({ email: user.email, userId: user.id, ip: req.ip });

    sendResponse(res, 200, true, 'Password changed successfully. All sessions revoked.');
  } catch (err) {
    console.error('Change password error:', err.message);
    sendResponse(res, 500, false, 'Internal server error');
  }
});

// ─── POST /api/v1/auth/logout ───────────────────────────────────────
router.post('/logout', authenticate, (req, res) => {
  // Blacklist the current token
  if (req.user && req.user.jti) {
    blacklistToken(req.user.jti, 28800); // 8 hours
  }
  sendResponse(res, 200, true, 'Logged out successfully');
});

// ─── POST /api/v1/auth/logout-all ───────────────────────────────────
router.post('/logout-all', authenticate, (req, res) => {
  // Revoke ALL tokens for this user
  revokeAllUserTokens(req.user.id);
  sendResponse(res, 200, true, 'All sessions revoked');
});

// ─── Helpers ────────────────────────────────────────────────────────

function detectPlatform(req) {
  const ua = (req.get('user-agent') || '').toLowerCase();
  if (/android|iphone|ipad|mobile|flutter/.test(ua)) return 'mobile';
  if (ua) return 'web';
  return 'unknown';
}

function sanitizeUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    phone: user.phone || null,
    class_level: user.class_level || null,
    class_name: user.class_name || null,
    school_name: user.school_name || null,
    school_id: user.school_id || null,
  };
}

module.exports = router;

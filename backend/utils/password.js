const argon2 = require('argon2');
const crypto = require('crypto');

// Argon2id config (OWASP recommended)
const ARGON2_OPTIONS = {
  type: argon2.argon2id,
  memoryCost: 65536,   // 64 MB
  timeCost: 3,         // 3 iterations
  parallelism: 1,      // 1 thread
};

/**
 * Hash password using Argon2id
 */
async function hashPassword(password) {
  return argon2.hash(password, ARGON2_OPTIONS);
}

/**
 * Verify password against stored hash
 * Supports: Argon2id, bcrypt (legacy), plain text (legacy seed)
 * Uses constant-time comparison for plain text to prevent timing attacks
 */
async function verifyPassword(password, hash) {
  if (!hash || !password) return false;

  // Argon2 hash
  if (hash.startsWith('$argon2')) {
    return argon2.verify(hash, password);
  }

  // Legacy bcrypt hash
  if (/^\$2[aby]\$/.test(hash)) {
    const bcrypt = require('bcryptjs');
    return bcrypt.compare(password, hash);
  }

  // Plain text (legacy seed data) — constant-time comparison
  if (password.length !== hash.length) return false;
  const a = Buffer.from(password, 'utf8');
  const b = Buffer.from(hash, 'utf8');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

/**
 * Check if hash needs upgrade to Argon2id
 */
function needsRehash(hash) {
  if (!hash) return true;
  return !hash.startsWith('$argon2');
}

/**
 * Generate 256-bit access key (hex)
 */
function generateAccessKey() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Hash access key using SHA-256 (store only this in DB)
 */
function hashAccessKey(accessKey) {
  return crypto.createHash('sha256').update(accessKey).digest('hex');
}

/**
 * Verify access key against stored hash (constant-time)
 */
function verifyAccessKey(accessKey, storedHash) {
  if (!accessKey || !storedHash) return false;
  const hash = hashAccessKey(accessKey);
  try {
    return crypto.timingSafeEqual(Buffer.from(hash, 'hex'), Buffer.from(storedHash, 'hex'));
  } catch {
    return false;
  }
}

module.exports = {
  hashPassword,
  verifyPassword,
  needsRehash,
  generateAccessKey,
  hashAccessKey,
  verifyAccessKey,
};

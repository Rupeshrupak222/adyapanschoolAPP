/**
 * lib/dualPrisma.js
 * ─────────────────────────────────────────────────────────────────────
 * A transparent Proxy around the Prisma client.
 *
 * READS  → TiDB Cloud only (fast primary).
 * WRITES → TiDB Cloud first, then mirrored to AWS RDS asynchronously.
 * DELETES → Mirrored to AWS RDS using the returned row's PK.
 *
 * Usage:  replace `require('../lib/prisma')` with `require('../lib/dualPrisma')`
 *         in any route file.  The API is 100% identical to PrismaClient.
 */

const prisma              = require('./prisma');
const { rdsQuery, RDS_ENABLED } = require('./rdsDb');

// ─── Table name map  (Prisma model name → actual MySQL table name) ───
const MODEL_TABLE = {
  user:                      'users',
  users:                     'users',
  student:                   'students',
  teacher:                   'teachers',
  principal:                 'principals',
  school:                    'schools',
  attendance:                'attendance',
  courses:                   'courses',
  enrollments:               'enrollments',
  payments:                  'payments',
  certificates:              'certificates',
  leads:                     'leads',
  notifications:             'notifications',
  otps:                      'otps',
  login_events:              'login_events',
  teacher_login_events:      'teacher_login_events',
  principal_login_events:    'principal_login_events',
  teacher_class_sessions:    'teacher_class_sessions',
  dashboard_snapshots:       'dashboard_snapshots',
  app_homework:              'app_homework',
  app_homework_submissions:  'app_homework_submissions',
  app_doubts:                'app_doubts',
  app_live_classes:          'app_live_classes',
  app_notes:                 'app_notes',
  app_recorded_lectures:     'app_recorded_lectures',
  app_teacher_messages:      'app_teacher_messages',
  app_notices:               'app_notices',
};

// ─── Write operations that must be mirrored ──────────────────────────
const WRITE_OPS = new Set(['create', 'update', 'upsert', 'delete', 'createMany', 'updateMany', 'deleteMany']);

// ─── Convert a Prisma result row → INSERT … ON DUPLICATE KEY UPDATE ──
function buildUpsertSql(table, data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return null;

  const flat = {};
  for (const [k, v] of Object.entries(data)) {
    if (v === undefined) continue;
    if (v instanceof Date)                      flat[k] = v.toISOString().slice(0, 19).replace('T', ' ');
    else if (typeof v === 'object' && v !== null) flat[k] = JSON.stringify(v);
    else                                          flat[k] = v;
  }

  const cols    = Object.keys(flat);
  if (cols.length === 0) return null;
  const vals    = Object.values(flat);
  const holders = cols.map(() => '?').join(', ');
  const updates = cols.map((c) => `\`${c}\` = VALUES(\`${c}\`)`).join(', ');

  return {
    sql: `INSERT INTO \`${table}\` (\`${cols.join('`, `')}\`) VALUES (${holders})
          ON DUPLICATE KEY UPDATE ${updates}`,
    params: vals,
  };
}

// ─── Mirror a single Prisma result to RDS ────────────────────────────
async function mirrorToRds(table, result, operation, prismaArgs) {
  if (!RDS_ENABLED || !table) return;

  try {
    // ── Handle single DELETE ─────────────────────────────────────────
    if (operation === 'delete') {
      // Prisma returns the deleted row — use its PK
      const pk    = result?.id ?? result?.credential_id ?? null;
      if (pk) {
        const pkCol = result?.credential_id !== undefined ? 'credential_id' : 'id';
        await rdsQuery(`DELETE FROM \`${table}\` WHERE \`${pkCol}\` = ?`, [pk]);
      }
      return;
    }

    // ── Handle deleteMany ────────────────────────────────────────────
    if (operation === 'deleteMany') {
      const where = prismaArgs?.[0]?.where;
      if (where && typeof where === 'object') {
        const entries = Object.entries(where).filter(([, v]) => v !== undefined && typeof v !== 'object');
        if (entries.length > 0) {
          const cols = entries.map(([k]) => `\`${k}\` = ?`).join(' AND ');
          const vals = entries.map(([, v]) => v);
          await rdsQuery(`DELETE FROM \`${table}\` WHERE ${cols}`, vals);
        }
      }
      return;
    }

    // ── Handle CREATE / UPDATE / UPSERT / createMany / updateMany ───
    const rows = Array.isArray(result)
      ? result
      : result?.count !== undefined
        ? []    // bulk count result — no row data
        : [result];

    for (const row of rows) {
      if (!row || typeof row !== 'object') continue;
      const built = buildUpsertSql(table, row);
      if (built) await rdsQuery(built.sql, built.params);
    }
  } catch (err) {
    console.error('⚠️  dualPrisma mirror error (non-fatal):', err.message);
  }
}

// ─── Model proxy handler ──────────────────────────────────────────────
function makeModelProxy(modelName, modelDelegate) {
  const table = MODEL_TABLE[modelName.toLowerCase()];

  return new Proxy(modelDelegate, {
    get(target, prop) {
      const original = target[prop];
      if (typeof original !== 'function') return original;

      // Only intercept write operations
      if (!WRITE_OPS.has(prop)) return original.bind(target);

      return async function (...args) {
        // 1. Execute on TiDB (primary — authoritative)
        const result = await original.apply(target, args);

        // 2. Mirror to RDS asynchronously — fire-and-forget, never blocks response
        if (RDS_ENABLED && table) {
          setImmediate(() => mirrorToRds(table, result, prop, args));
        }

        return result;
      };
    },
  });
}

// ─── Top-level Prisma proxy ───────────────────────────────────────────
const dualPrisma = new Proxy(prisma, {
  get(target, prop) {
    const value = target[prop];

    // Proxy model delegates (e.g. prisma.users, prisma.student …)
    if (
      value &&
      typeof value === 'object' &&
      typeof value.findMany === 'function' // duck-type PrismaDelegate
    ) {
      return makeModelProxy(String(prop), value);
    }

    // Everything else (prisma.$connect, prisma.$transaction, etc.) — pass through
    if (typeof value === 'function') return value.bind(target);
    return value;
  },
});

module.exports = dualPrisma;

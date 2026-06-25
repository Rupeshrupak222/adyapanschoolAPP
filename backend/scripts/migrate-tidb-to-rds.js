/**
 * scripts/migrate-tidb-to-rds.js
 * ─────────────────────────────────────────────────────────────────────
 * One-time full migration: TiDB Cloud → AWS RDS MySQL
 *
 * Run ONCE after creating your RDS instance and pushing the schema:
 *
 *   node scripts/migrate-tidb-to-rds.js
 *
 * The script:
 *  1. Connects to both TiDB (source) and AWS RDS (target)
 *  2. For every table: reads ALL rows from TiDB → bulk-upserts to RDS
 *  3. Prints a row-count diff report at the end
 *  4. Is safe to re-run (REPLACE INTO / ON DUPLICATE KEY UPDATE)
 *
 * Pre-requisites:
 *  - AWS RDS instance running with the same schema (run `prisma migrate deploy`
 *    or `prisma db push` against AWS_RDS_DATABASE_URL first)
 *  - .env has AWS_RDS_* vars filled in
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });

const mysql = require('mysql2/promise');

// ─── Source: TiDB Cloud ──────────────────────────────────────────────
const tidbConfig = {
  host:    process.env.MYSQL_HOST,
  port:    parseInt(process.env.MYSQL_PORT || '4000', 10),
  user:    process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE || 'preschool',
  ssl:     process.env.MYSQL_SSL === 'false' ? undefined : { rejectUnauthorized: false },
  connectTimeout: 15000,
};

// ─── Target: AWS RDS MySQL ────────────────────────────────────────────
const rdsConfig = {
  host:    process.env.AWS_RDS_HOST,
  port:    parseInt(process.env.AWS_RDS_PORT || '3306', 10),
  user:    process.env.AWS_RDS_USER,
  password: process.env.AWS_RDS_PASSWORD,
  database: process.env.AWS_RDS_DATABASE || 'preschool',
  ssl:     process.env.AWS_RDS_SSL === 'false' ? undefined : { rejectUnauthorized: false },
  connectTimeout: 15000,
  multipleStatements: true,
};

// ─── Tables to migrate (order matters for FK constraints) ────────────
const TABLES = [
  'users',
  'schools',
  'students',
  'teachers',
  'principals',
  'courses',
  'payments',
  'enrollments',
  'certificates',
  'attendance',
  'leads',
  'notifications',
  'otps',
  'login_events',
  'teacher_login_events',
  'principal_login_events',
  'teacher_class_sessions',
  'dashboard_snapshots',
];

// ─── Helpers ──────────────────────────────────────────────────────────
function pad(str, len) {
  return String(str).padEnd(len);
}

function formatVal(v) {
  if (v === null || v === undefined) return null;
  if (v instanceof Date) return v.toISOString().slice(0, 19).replace('T', ' ');
  if (typeof v === 'object') return JSON.stringify(v);
  return v;
}

async function migrateTable(tidb, rds, table) {
  // Read all rows from TiDB
  const [rows] = await tidb.execute(`SELECT * FROM \`${table}\``);

  if (rows.length === 0) {
    console.log(`  ${pad(table, 32)} — 0 rows (skipped)`);
    return { table, source: 0, migrated: 0 };
  }

  const cols    = Object.keys(rows[0]);
  const holders = cols.map(() => '?').join(', ');
  const updates = cols.map((c) => `\`${c}\` = VALUES(\`${c}\`)`).join(', ');
  const sql     = `INSERT INTO \`${table}\` (\`${cols.join('`, `')}\`)
                   VALUES (${holders})
                   ON DUPLICATE KEY UPDATE ${updates}`;

  // Batch insert in chunks of 200
  const CHUNK = 200;
  let migrated = 0;

  // Temporarily disable FK checks on RDS for bulk insert
  await rds.execute('SET FOREIGN_KEY_CHECKS = 0');

  for (let i = 0; i < rows.length; i += CHUNK) {
    const chunk = rows.slice(i, i + CHUNK);
    for (const row of chunk) {
      const params = cols.map((c) => formatVal(row[c]));
      await rds.execute(sql, params);
      migrated++;
    }
    process.stdout.write(`\r  ${pad(table, 32)} — ${migrated}/${rows.length} rows`);
  }

  await rds.execute('SET FOREIGN_KEY_CHECKS = 1');
  console.log(`\r  ${pad(table, 32)} — ✅ ${migrated}/${rows.length} rows migrated`);
  return { table, source: rows.length, migrated };
}

// ─── Main ─────────────────────────────────────────────────────────────
(async () => {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║     TiDB Cloud  →  AWS RDS MySQL  Migration Tool    ║');
  console.log('╚══════════════════════════════════════════════════════╝\n');

  // Validate env vars
  const missing = [];
  if (!tidbConfig.host)    missing.push('MYSQL_HOST');
  if (!tidbConfig.user)    missing.push('MYSQL_USER');
  if (!tidbConfig.password) missing.push('MYSQL_PASSWORD');
  if (!rdsConfig.host)     missing.push('AWS_RDS_HOST');
  if (!rdsConfig.user)     missing.push('AWS_RDS_USER');
  if (!rdsConfig.password) missing.push('AWS_RDS_PASSWORD');
  if (missing.length > 0) {
    console.error('❌ Missing env vars:', missing.join(', '));
    console.error('   Fill these in your .env file first.');
    process.exit(1);
  }

  let tidb, rds;

  try {
    console.log('🔌 Connecting to TiDB Cloud…');
    tidb = await mysql.createConnection(tidbConfig);
    console.log('✅ TiDB connected\n');

    console.log('🔌 Connecting to AWS RDS MySQL…');
    rds = await mysql.createConnection(rdsConfig);
    console.log('✅ AWS RDS connected\n');
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
    process.exit(1);
  }

  console.log('📦 Starting migration…\n');
  const results = [];

  for (const table of TABLES) {
    try {
      const r = await migrateTable(tidb, rds, table);
      results.push(r);
    } catch (err) {
      console.error(`\n  ❌ ${table} — ERROR: ${err.message}`);
      results.push({ table, source: '?', migrated: 0, error: err.message });
    }
  }

  // ── Summary report ──────────────────────────────────────────────────
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║                  Migration Summary                  ║');
  console.log('╠══════════════════════════════════════════════════════╣');
  for (const r of results) {
    const status = r.error ? '❌' : (r.source === r.migrated ? '✅' : '⚠️ ');
    console.log(`║  ${status} ${pad(r.table, 30)} ${pad(r.migrated, 5)} rows  ║`);
  }
  console.log('╚══════════════════════════════════════════════════════╝\n');

  // ── Verify row counts ────────────────────────────────────────────────
  console.log('🔍 Verifying row counts…\n');
  let allMatch = true;
  for (const table of TABLES) {
    const [[{ c: sc }]] = await tidb.execute(`SELECT COUNT(*) AS c FROM \`${table}\``);
    const [[{ c: rc }]] = await rds.execute(`SELECT COUNT(*) AS c FROM \`${table}\``);
    const match = sc === rc;
    if (!match) allMatch = false;
    console.log(`  ${match ? '✅' : '❌'} ${pad(table, 32)} TiDB: ${pad(sc, 6)} | RDS: ${rc}`);
  }

  console.log(allMatch
    ? '\n🎉 All tables match! Migration successful.\n'
    : '\n⚠️  Some tables differ — re-run the script to sync.\n'
  );

  await tidb.end();
  await rds.end();
  process.exit(0);
})();

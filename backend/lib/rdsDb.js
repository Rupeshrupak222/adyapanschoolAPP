/**
 * lib/rdsDb.js
 * ─────────────────────────────────────────────────────────────────────
 * Raw MySQL2 connection pool for AWS RDS MySQL.
 * Used by dualPrisma.js to mirror every write to RDS.
 *
 * If RDS env vars are missing the pool is null and all write-mirror calls
 * become silent no-ops — the app continues on TiDB only.
 */

const mysql = require('mysql2/promise');

const RDS_HOST     = process.env.AWS_RDS_HOST;
const RDS_PORT     = parseInt(process.env.AWS_RDS_PORT || '3306', 10);
const RDS_USER     = process.env.AWS_RDS_USER;
const RDS_PASSWORD = process.env.AWS_RDS_PASSWORD;
const RDS_DATABASE = process.env.AWS_RDS_DATABASE || 'preschool';
const RDS_ENABLED  = !!(RDS_HOST && RDS_USER && RDS_PASSWORD);

let rdsPool = null;

if (RDS_ENABLED) {
  rdsPool = mysql.createPool({
    host:               RDS_HOST,
    port:               RDS_PORT,
    user:               RDS_USER,
    password:           RDS_PASSWORD,
    database:           RDS_DATABASE,
    ssl:                process.env.AWS_RDS_SSL === 'false' ? undefined : { rejectUnauthorized: false },
    waitForConnections: true,
    connectionLimit:    10,
    queueLimit:         0,
    connectTimeout:     10000,
  });

  // Verify on startup (non-blocking)
  rdsPool.getConnection()
    .then((conn) => {
      console.log(`✅ AWS RDS MySQL connected — host: ${RDS_HOST}:${RDS_PORT}/${RDS_DATABASE}`);
      conn.release();
    })
    .catch((err) => {
      console.error('❌ AWS RDS MySQL connection failed:', err.message);
      console.error('   Check AWS_RDS_* env vars and Security Group (port 3306 open).');
    });
} else {
  console.log('ℹ️  AWS RDS not configured — dual-write disabled (TiDB only).');
}

/**
 * Execute a raw SQL query on RDS.
 * Safe to call even when RDS is not configured — returns null silently.
 *
 * @param {string}  sql    Parameterized SQL string
 * @param {Array}   params Query parameters
 * @returns {Promise<Array|null>}
 */
async function rdsQuery(sql, params = []) {
  if (!rdsPool) return null;
  try {
    const [rows] = await rdsPool.execute(sql, params);
    return rows;
  } catch (err) {
    // Log but never crash main flow
    console.error('⚠️  RDS write error (non-fatal):', err.message, '| SQL:', sql.slice(0, 120));
    return null;
  }
}

module.exports = { rdsPool, rdsQuery, RDS_ENABLED };

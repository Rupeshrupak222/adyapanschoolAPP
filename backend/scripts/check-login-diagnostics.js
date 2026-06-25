const { getPool, closePool } = require('../src/db');

function maskEmail(email) {
  const [name, domain] = String(email || '').split('@');
  if (!name || !domain) return 'unknown';
  return `${name.slice(0, 2)}***@${domain}`;
}

async function main() {
  const pool = getPool();

  const [summaryRows] = await pool.execute(`
    SELECT
      COUNT(*) AS total,
      SUM(CASE WHEN password LIKE '$2%' THEN 1 ELSE 0 END) AS bcrypt_like,
      SUM(CASE WHEN password NOT LIKE '$2%' THEN 1 ELSE 0 END) AS plain_like,
      MIN(CHAR_LENGTH(password)) AS min_len,
      MAX(CHAR_LENGTH(password)) AS max_len
    FROM users;
  `);

  const [duplicateRows] = await pool.execute(`
    SELECT LOWER(email) AS email_key, COUNT(*) AS total
    FROM users
    GROUP BY LOWER(email)
    HAVING COUNT(*) > 1;
  `);

  const [userRows] = await pool.execute(`
    SELECT
      name,
      email,
      class_name,
      school,
      CHAR_LENGTH(password) AS password_len,
      CASE WHEN password LIKE '$2%' THEN 'bcrypt' ELSE 'plain/other' END AS password_type,
      created_at
    FROM users
    ORDER BY created_at DESC
    LIMIT 10;
  `);

  const [loginSourceRows] = await pool.execute(`
    SELECT source, COUNT(*) AS total
    FROM login_events
    GROUP BY source
    ORDER BY source;
  `);

  const [mobileLoginRows] = await pool.execute(`
    SELECT email, name, created_at
    FROM login_events
    WHERE source = 'mobile'
    ORDER BY created_at DESC
    LIMIT 10;
  `);

  console.log(
    JSON.stringify(
      {
        summary: summaryRows[0],
        duplicateEmails: duplicateRows.map((row) => ({
          email: maskEmail(row.email_key),
          total: Number(row.total),
        })),
        users: userRows.map((row) => ({
          name: row.name,
          email: maskEmail(row.email),
          className: row.class_name,
          school: row.school,
          passwordLen: Number(row.password_len),
          passwordType: row.password_type,
          createdAt: row.created_at,
        })),
        loginSources: loginSourceRows.map((row) => ({
          source: row.source || 'unknown',
          total: Number(row.total),
        })),
        latestMobileLogins: mobileLoginRows.map((row) => ({
          name: row.name,
          email: maskEmail(row.email),
          createdAt: row.created_at,
        })),
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error) => {
    console.error(error.code || error.name, error.message);
    process.exitCode = 1;
  })
  .finally(closePool);

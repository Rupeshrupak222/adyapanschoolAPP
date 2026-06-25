const { getPool, closePool } = require('../src/db');

function maskEmail(email) {
  const value = String(email || '');
  const [name, domain] = value.split('@');
  if (!name || !domain) return value;
  return `${name.slice(0, 2)}***@${domain}`;
}

async function main() {
  const pool = getPool();

  const [tables] = await pool.execute(`
    SELECT TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
    ORDER BY TABLE_NAME;
  `);

  const [userCountRows] = await pool.execute('SELECT COUNT(*) AS total FROM users;');
  const [loginCountRows] = await pool.execute('SELECT COUNT(*) AS total FROM login_events;');

  const [latestUsers] = await pool.execute(`
    SELECT id, name, email, phone, class_name, school, created_at
    FROM users
    ORDER BY created_at DESC
    LIMIT 10;
  `);

  const [latestLogins] = await pool.execute(`
    SELECT le.email, COALESCE(u.name, le.name) AS name, le.source, le.ip_address, le.created_at
    FROM login_events le
    LEFT JOIN users u ON u.id = le.user_id
    ORDER BY le.created_at DESC
    LIMIT 10;
  `);

  console.log('Tables:');
  for (const row of tables) console.log(`- ${row.TABLE_NAME}`);

  console.log('\nCounts:');
  console.log(`- users: ${Number(userCountRows[0].total)}`);
  console.log(`- login_events: ${Number(loginCountRows[0].total)}`);

  console.log('\nLatest users:');
  for (const row of latestUsers) {
    console.log(
      `- ${row.name} | ${maskEmail(row.email)} | ${row.phone} | ${row.class_name} | ${row.school} | ${row.created_at}`,
    );
  }

  console.log('\nLatest logins:');
  for (const row of latestLogins) {
    console.log(
      `- ${row.name || 'no-name'} | ${maskEmail(row.email)} | ${row.source || 'unknown'} | ${row.ip_address || 'no-ip'} | ${row.created_at}`,
    );
  }
}

main()
  .catch((error) => {
    console.error(error.code || error.name, error.message);
    process.exitCode = 1;
  })
  .finally(closePool);

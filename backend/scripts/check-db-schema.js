const { getPool, closePool } = require('../src/db');

async function main() {
  const [columns] = await getPool().execute(`
    SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, DATA_TYPE, COLUMN_KEY
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND (
        (TABLE_NAME = 'users' AND COLUMN_NAME = 'id')
        OR (TABLE_NAME = 'students' AND COLUMN_NAME = 'user_id')
        OR TABLE_NAME = 'login_events'
      )
    ORDER BY TABLE_NAME, COLUMN_NAME;
  `);

  console.log(JSON.stringify(columns, null, 2));
}

main()
  .catch((error) => {
    console.error(error.code || error.name, error.message);
    process.exitCode = 1;
  })
  .finally(closePool);

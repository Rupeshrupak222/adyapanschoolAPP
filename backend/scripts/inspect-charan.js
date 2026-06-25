const { getPool, closePool } = require('../src/db');

async function main() {
  const pool = getPool();

  console.log("--- Querying users table for charan@gmail.com ---");
  const [users] = await pool.execute("SELECT id, name, email, role, password, teacher_id FROM users WHERE LOWER(email) = 'charan@gmail.com'");
  console.log(users);

  console.log("\n--- Querying teachers table for charan@gmail.com ---");
  const [teachers] = await pool.execute("SELECT id, teacher_name, email, password_hash, staff_key_hash FROM teachers WHERE LOWER(email) = 'charan@gmail.com'");
  console.log(teachers);
}

main()
  .catch((error) => {
    console.error(error.code || error.name, error.message);
    process.exitCode = 1;
  })
  .finally(closePool);

const { getPool, closePool } = require('../src/db');

async function main() {
  const pool = getPool();

  console.log("--- Querying users table for student 'gulshan' or 'Gulshan' ---");
  const [users] = await pool.execute("SELECT id, name, email, role, phone, teacher_id FROM users WHERE LOWER(name) LIKE '%gulshan%' OR LOWER(email) LIKE '%gulshan%'");
  console.log(users);

  console.log("\n--- Querying teachers table for 'charan' ---");
  const [teachers] = await pool.execute("SELECT id, teacher_name, email FROM teachers WHERE LOWER(teacher_name) LIKE '%charan%' OR LOWER(email) LIKE '%charan%'");
  console.log(teachers);
  
  if (teachers.length > 0) {
    const teacherId = teachers[0].id;
    console.log(`\n--- Querying users table for students linked to teacher ID '${teacherId}' ---`);
    const [linkedStudents] = await pool.execute("SELECT id, name, email, role, teacher_id FROM users WHERE teacher_id = ?", [teacherId]);
    console.log(linkedStudents);
  }
}

main()
  .catch((error) => {
    console.error(error.code || error.name, error.message);
    process.exitCode = 1;
  })
  .finally(closePool);

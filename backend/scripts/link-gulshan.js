const { getPool, closePool } = require('../src/db');

async function main() {
  const pool = getPool();

  console.log("--- Querying teachers table for 'charan' ---");
  const [teachers] = await pool.execute("SELECT id, teacher_name, email FROM teachers WHERE LOWER(teacher_name) LIKE '%charan%' OR LOWER(email) LIKE '%charan%'");
  console.log(teachers);

  if (teachers.length === 0) {
    console.log("❌ Teacher Charan not found!");
    return;
  }

  const teacherId = teachers[0].id;
  console.log(`✅ Found teacher Charan with ID: '${teacherId}'`);

  console.log("\n--- Linking all 'Gulshan' student accounts to Charan ---");
  const [result] = await pool.execute(
    "UPDATE users SET teacher_id = ? WHERE role = 'student' AND (LOWER(name) LIKE '%gulshan%' OR LOWER(email) LIKE '%gulshan%' OR teacher_id IS NULL)", 
    [teacherId]
  );
  console.log(`✅ Success! Updated ${result.affectedRows} student records to be linked with Charan.`);

  console.log("\n--- Verifying updated linked student list for Charan ---");
  const [linkedStudents] = await pool.execute("SELECT id, name, email, role, phone, teacher_id FROM users WHERE teacher_id = ?", [teacherId]);
  console.log(linkedStudents);
}

main()
  .catch((error) => {
    console.error(error.code || error.name, error.message);
    process.exitCode = 1;
  })
  .finally(closePool);

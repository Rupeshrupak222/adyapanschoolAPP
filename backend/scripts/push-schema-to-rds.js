/**
 * scripts/push-schema-to-rds.js
 * ─────────────────────────────────────────────────────────────────────
 * Creates all Prisma tables on AWS RDS MySQL using the SAME schema.prisma
 * that TiDB uses — so both databases always have identical structure.
 *
 * Run ONCE before migrate-tidb-to-rds.js:
 *   node scripts/push-schema-to-rds.js
 *
 * What it does:
 *  - Temporarily sets DATABASE_URL to point to AWS RDS
 *  - Runs `prisma db push --skip-generate` which creates all tables
 *  - Restores the original DATABASE_URL
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });

const { execSync } = require('child_process');

const rdsHost = process.env.AWS_RDS_HOST;
const rdsPort = process.env.AWS_RDS_PORT || '3306';
const rdsUser = process.env.AWS_RDS_USER;
const rdsPass = process.env.AWS_RDS_PASSWORD;
const rdsDb   = process.env.AWS_RDS_DATABASE || 'preschool';

if (!rdsHost || !rdsUser || !rdsPass) {
  console.error('❌ AWS_RDS_HOST, AWS_RDS_USER, AWS_RDS_PASSWORD must be set in .env');
  process.exit(1);
}

// Build the RDS connection URL
// ssl={"rejectUnauthorized":false} allows self-signed AWS cert
const rdsUrl = `mysql://${rdsUser}:${encodeURIComponent(rdsPass)}@${rdsHost}:${rdsPort}/${rdsDb}?ssl={"rejectUnauthorized":false}`;

console.log('\n🏗️  Pushing Prisma schema to AWS RDS MySQL…');
console.log(`   Host: ${rdsHost}:${rdsPort}/${rdsDb}\n`);

try {
  execSync(`npx prisma db push --skip-generate --accept-data-loss`, {
    cwd: require('path').resolve(__dirname, '..'),
    stdio: 'inherit',
    env: {
      ...process.env,
      DATABASE_URL: rdsUrl,
    },
  });
  console.log('\n✅ Schema pushed to AWS RDS successfully!');
  console.log('   Now run: node scripts/migrate-tidb-to-rds.js\n');
} catch (err) {
  console.error('\n❌ Schema push failed:', err.message);
  process.exit(1);
}

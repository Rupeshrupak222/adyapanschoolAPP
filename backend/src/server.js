const app = require('./app');
const env = require('./config/env');
const { initDatabase, closePool } = require('./db');

async function start() {
  await initDatabase();

  const server = app.listen(env.port, () => {
    console.log(`Backend API running on http://localhost:${env.port}`);
  });

  async function shutdown() {
    server.close(async () => {
      await closePool();
      process.exit(0);
    });
  }

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

start().catch((error) => {
  console.error('Failed to start backend API:', error);
  process.exit(1);
});

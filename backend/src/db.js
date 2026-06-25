const mysql = require('mysql2/promise');
const env = require('./config/env');

let pool;

function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: env.mysql.host,
      port: env.mysql.port,
      user: env.mysql.user,
      password: env.mysql.password,
      database: env.mysql.database,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      ssl: env.mysql.ssl ? {} : undefined,
    });
  }

  return pool;
}

async function initDatabase() {
  await getPool().execute(`
    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(64) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL UNIQUE,
      phone VARCHAR(50) NOT NULL,
      class_name VARCHAR(100) NOT NULL,
      school VARCHAR(255) NOT NULL,
      password VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  await getPool().execute(`
    CREATE TABLE IF NOT EXISTS login_events (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) NOT NULL,
      name VARCHAR(160),
      email VARCHAR(190) NOT NULL,
      role VARCHAR(30),
      source VARCHAR(40) NOT NULL DEFAULT 'unknown',
      status VARCHAR(40) NOT NULL DEFAULT 'success',
      ip_address VARCHAR(80),
      user_agent TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_login_events_user_id (user_id),
      INDEX idx_login_events_email (email),
      INDEX idx_login_events_source (source),
      INDEX idx_login_events_created_at (created_at),
      CONSTRAINT fk_login_events_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    );
  `);
}

async function closePool() {
  if (pool) {
    await pool.end();
    pool = undefined;
  }
}

module.exports = {
  getPool,
  initDatabase,
  closePool,
};

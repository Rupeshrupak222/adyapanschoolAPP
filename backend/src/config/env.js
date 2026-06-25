const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });
dotenv.config({ path: path.resolve(__dirname, '../../.env'), override: true });

function getRequired(name) {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function getBoolean(name, fallback = false) {
  const value = process.env[name];
  if (value == null || value === '') return fallback;
  return ['1', 'true', 'yes', 'on'].includes(value.toLowerCase());
}

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3000),
  corsOrigin: process.env.CORS_ORIGIN || '*',
  mysql: {
    host: getRequired('MYSQL_HOST'),
    port: Number(process.env.MYSQL_PORT || 4000),
    user: getRequired('MYSQL_USER'),
    password: getRequired('MYSQL_PASSWORD'),
    database: process.env.MYSQL_DATABASE || 'preschool',
    ssl: getBoolean('MYSQL_SSL', true),
  },
};

module.exports = env;

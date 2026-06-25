# Adyapan School Backend

Standalone Node.js backend for the Flutter app.

## API

```text
GET  /health
POST /api/auth/signup
POST /api/auth/login
GET  /api/auth/login-events
GET  /api/auth/login-summary
```

## Setup

```bash
cd backend
npm install
npm run dev
```

The backend loads env values from the project root `.env` first, then from `backend/.env` if present.

Required env:

```text
MYSQL_HOST
MYSQL_PORT
MYSQL_USER
MYSQL_PASSWORD
MYSQL_DATABASE
MYSQL_SSL
```

Optional env:

```text
PORT=3000
CORS_ORIGIN=*
```

## Signup Body

```json
{
  "name": "Aarav Sharma",
  "email": "aarav@example.com",
  "phone": "9876543210",
  "className": "Class 10",
  "school": "Adyapan Public School",
  "password": "password123"
}
```

## Login Body

```json
{
  "email": "aarav@example.com",
  "password": "password123",
  "clientType": "mobile"
}
```

`clientType` can be `mobile` or `web`. If it is not provided, the backend tries to detect it from the request user-agent.

## Login Tracking

Successful logins are stored in the `login_events` table.

```text
GET /api/auth/login-events?clientType=mobile
GET /api/auth/login-events?clientType=web
GET /api/auth/login-summary
```

## Frontend Base URL

On the frontend laptop, set:

```text
API_BASE_URL=http://YOUR_BACKEND_LAPTOP_IP:3000
LOCAL_API_BASE_URL=http://YOUR_BACKEND_LAPTOP_IP:3000
```

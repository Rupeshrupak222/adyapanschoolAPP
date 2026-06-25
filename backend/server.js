require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

// ─── Validate required env vars ─────────────────────────────────────
const REQUIRED_ENV = ['DATABASE_URL', 'JWT_SECRET'];
const missing = REQUIRED_ENV.filter((key) => !process.env[key]);
if (missing.length > 0) {
  console.error(`❌ Missing required env vars: ${missing.join(', ')}`);
  console.error('   Check your .env file or Render environment settings.');
  process.exit(1);
}

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const hpp = require('hpp');
const cookieParser = require('cookie-parser');
const prisma = require('./lib/prisma');
require('./lib/rdsDb'); // Boots AWS RDS pool on startup (logs connection status)
const { inputSanitizer } = require('./middleware/sanitize');
const { csrfProtection } = require('./middleware/csrf');

// Route imports
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const studentRoutes = require('./routes/students');
const teacherRoutes = require('./routes/teachers');
const schoolRoutes = require('./routes/schools');
const liveClassRoutes = require('./routes/liveClasses');
const eventRoutes = require('./routes/events');
const leaveRoutes = require('./routes/leaves');
const meetingRoutes = require('./routes/meetings');
const leadRoutes = require('./routes/leads');
const attendanceRoutes = require('./routes/attendance');
const classRoutes = require('./routes/classes');
const paymentRoutes = require('./routes/payments');
const noticeRoutes = require('./routes/notices');
const dashboardRoutes = require('./routes/dashboard');
const bulkImportRoutes = require('./routes/bulk-import');
const appHomeworkRoutes = require('./routes/app-homework');
const appDoubtsRoutes = require('./routes/app-doubts');
const appLiveClassesRoutes = require('./routes/app-live-classes');
const messagesRoutes = require('./routes/messages');

const app = express();
const PORT = process.env.PORT || 4000;
const isProduction = process.env.NODE_ENV === 'production';

// ─── Security Middleware ─────────────────────────────────────────────
app.use(
  helmet({
    crossOriginResourcePolicy: false, // Allows media files (images/videos) to load on mobile app
  })
);

const multer = require('multer');
const fs = require('fs');
const path = require('path');

// ─── AWS S3 Configuration ─────────────────────────────────────────────
const AWS_REGION = process.env.AWS_REGION;
const AWS_ACCESS_KEY_ID = process.env.AWS_ACCESS_KEY_ID;
const AWS_SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY;
const AWS_S3_BUCKET = process.env.AWS_S3_BUCKET_NAME;
const S3_ENABLED = !!(AWS_REGION && AWS_ACCESS_KEY_ID && AWS_SECRET_ACCESS_KEY && AWS_S3_BUCKET);

let s3Client = null;
if (S3_ENABLED) {
  const { S3Client } = require('@aws-sdk/client-s3');
  s3Client = new S3Client({
    region: AWS_REGION,
    credentials: {
      accessKeyId: AWS_ACCESS_KEY_ID,
      secretAccessKey: AWS_SECRET_ACCESS_KEY,
    },
  });
  console.log(`✅ AWS S3 enabled — bucket: ${AWS_S3_BUCKET} (region: ${AWS_REGION})`);
} else {
  console.log('⚠️  AWS S3 not configured — using local disk storage fallback');
}

// Ensure local uploads folder exists (used as fallback when S3 is not configured)
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Always use memory storage so we can pipe buffer to S3 or write to disk
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 500 * 1024 * 1024 }, // 500 MB limit for large video files
});

// Serve local uploads folder as static (used as fallback)
app.use('/uploads', express.static(uploadsDir));


// ─── CORS Configuration ─────────────────────────────────────────────
const allowedOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman)
      if (!origin) return callback(null, true);
      // In dev, allow all; in production, check whitelist
      if (!isProduction || allowedOrigins.length === 0) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// ─── Rate Limiting ──────────────────────────────────────────────────
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // 200 requests per window
  message: { success: false, message: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20, // Stricter for auth routes (prevent brute force)
  message: { success: false, message: 'Too many login attempts. Try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', generalLimiter);
app.use('/api/v1/auth/', authLimiter);

// ─── Compression ────────────────────────────────────────────────────
app.use(compression());

// ─── Body Parsing ───────────────────────────────────────────────────
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));
app.use(cookieParser());

// ─── HTTP Parameter Pollution Protection ────────────────────────────
app.use(hpp());

// ─── Input Sanitization (XSS Prevention) ────────────────────────────
app.use(inputSanitizer);

// ─── CSRF Protection (Double-Submit Cookie) ─────────────────────────
app.use(csrfProtection);

// ─── Logging ────────────────────────────────────────────────────────
if (isProduction) {
  app.use(morgan('combined'));
} else {
  app.use(morgan('dev'));
}

// ─── Health Check (TiDB + RDS + S3 status) ─────────────────────────
app.get('/', async (req, res) => {
  // 1. TiDB ping
  let tidbStatus = 'unknown';
  try {
    await prisma.$queryRaw`SELECT 1`;
    tidbStatus = 'connected';
  } catch {
    tidbStatus = 'disconnected';
  }

  // 2. AWS RDS ping
  const { rdsPool, RDS_ENABLED } = require('./lib/rdsDb');
  let rdsStatus = RDS_ENABLED ? 'unknown' : 'not_configured';
  if (RDS_ENABLED && rdsPool) {
    try {
      const conn = await rdsPool.getConnection();
      await conn.execute('SELECT 1');
      conn.release();
      rdsStatus = 'connected';
    } catch {
      rdsStatus = 'disconnected';
    }
  }

  // 3. AWS S3 status
  const s3Status = S3_ENABLED ? 'configured' : 'not_configured';

  const allOk = tidbStatus === 'connected';
  const response = {
    status: allOk ? 'ok' : 'degraded',
    message: 'Adyapan Unified Backend',
    version: '3.1.0',
    uptime: Math.floor(process.uptime()) + 's',
    services: {
      tidb:  tidbStatus,
      rds:   rdsStatus,
      s3:    s3Status,
    },
  };

  if (!isProduction) {
    response.environment = 'development';
    response.endpoints = [
      '/api/v1/auth', '/api/v1/profile', '/api/v1/students',
      '/api/v1/teachers', '/api/v1/schools', '/api/v1/live-classes',
      '/api/v1/events', '/api/v1/leaves', '/api/v1/meetings',
      '/api/v1/leads', '/api/v1/attendance', '/api/v1/classes',
      '/api/v1/payments', '/api/v1/notices', '/api/v1/dashboard',
      '/api/v1/upload', '/api/v1/sms/send',
    ];
  }

  res.status(allOk ? 200 : 503).json(response);
});


// ─── API Routes ─────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/profile', profileRoutes);
app.use('/api/v1/students', studentRoutes);
app.use('/api/v1/teachers', teacherRoutes);
app.use('/api/v1/schools', schoolRoutes);
app.use('/api/v1/live-classes', liveClassRoutes);
app.use('/api/v1/events', eventRoutes);
app.use('/api/v1/leaves', leaveRoutes);
app.use('/api/v1/meetings', meetingRoutes);
app.use('/api/v1/leads', leadRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/classes', classRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/notices', noticeRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/bulk-import', bulkImportRoutes);
app.use('/api/v1/app-homework', appHomeworkRoutes);
app.use('/api/v1/app-doubts', appDoubtsRoutes);
app.use('/api/v1/app-live-classes', appLiveClassesRoutes);
app.use('/api/v1/messages', messagesRoutes);

// ─── File Upload Endpoint (AWS S3 or local fallback) ─────────────────
app.post('/api/v1/upload', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No file uploaded' });
  }

  try {
    if (S3_ENABLED && s3Client) {
      // ── Upload to AWS S3 with organized folder structure ──
      const { PutObjectCommand } = require('@aws-sdk/client-s3');
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      const ext = path.extname(req.file.originalname).toLowerCase() || '';

      // Auto-detect folder based on file type
      let folder = 'docs';
      const mime = req.file.mimetype || '';
      const folderOverride = req.query.folder || req.body?.folder;
      if (folderOverride) {
        folder = folderOverride.replace(/[^a-z0-9_-]/gi, '').toLowerCase();
      } else if (mime.startsWith('video/'))  {
        folder = 'videos';
      } else if (mime.startsWith('image/'))  {
        folder = 'profiles';
      } else if (mime === 'application/pdf') {
        folder = 'notices';
      } else if (['.docx', '.doc', '.pptx', '.ppt', '.xlsx'].includes(ext)) {
        folder = 'homework';
      }

      const s3Key = `${folder}/${uniqueSuffix}${ext}`;

      await s3Client.send(new PutObjectCommand({
        Bucket: AWS_S3_BUCKET,
        Key: s3Key,
        Body: req.file.buffer,
        ContentType: req.file.mimetype,
      }));

      const fileUrl = `https://${AWS_S3_BUCKET}.s3.${AWS_REGION}.amazonaws.com/${s3Key}`;
      console.log(`☁️  S3 upload [${folder}]: ${s3Key}`);

      return res.json({
        success: true,
        message: 'File uploaded successfully to AWS S3',
        filename: s3Key,
        originalName: req.file.originalname,
        size: req.file.size,
        url: fileUrl,
        folder,
        storage: 's3',
      });
    } else {
      // ── Local fallback: write buffer to disk ──
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      const ext = path.extname(req.file.originalname) || '';
      const filename = `${uniqueSuffix}${ext}`;
      const filePath = path.join(uploadsDir, filename);

      fs.writeFileSync(filePath, req.file.buffer);
      const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${filename}`;
      console.log(`📁 File saved locally (S3 not configured): ${filename} -> ${fileUrl}`);

      return res.json({
        success: true,
        message: 'File uploaded successfully (local storage)',
        filename: filename,
        originalName: req.file.originalname,
        size: req.file.size,
        url: fileUrl,
        storage: 'local',
      });
    }
  } catch (err) {
    console.error('❌ File upload failed:', err.message);
    return res.status(500).json({ success: false, message: 'File upload failed: ' + err.message });
  }
});

// ─── Direct SMS Dispatch Route (Fast2SMS / Twilio Gateway) ──────────
app.post('/api/v1/sms/send', async (req, res) => {
  const { to, message, category, studentName } = req.body;

  if (!to || !message) {
    return res.status(400).json({ success: false, message: 'Missing required fields: to, message' });
  }

  console.log(`\n=================== 📲 SMS DISPATCH SYSTEM ===================`);
  console.log(`📞 TO (Parent): ${to}`);
  console.log(`👤 STUDENT: ${studentName}`);
  console.log(`🏷️  CATEGORY: ${category ? category.toUpperCase() : 'GENERAL'}`);
  console.log(`💬 MESSAGE: "${message}"`);

  // ── Fast2SMS Integration (Indian SMS gateway, free tier available) ──
  const fast2smsKey = process.env.FAST2SMS_API_KEY;
  if (fast2smsKey) {
    try {
      const axios = require('axios');
      // Sanitize phone number — remove spaces, dashes, +91 prefix
      const cleanPhone = to.replace(/[\s\-+]/g, '').replace(/^91/, '').slice(-10);

      const smsResponse = await axios.post(
        'https://www.fast2sms.com/dev/bulkV2',
        {
          route: 'q',
          message: message,
          language: 'english',
          flash: 0,
          numbers: cleanPhone,
        },
        {
          headers: {
            authorization: fast2smsKey,
            'Content-Type': 'application/json',
          },
          timeout: 8000,
        }
      );

      if (smsResponse.data?.return === true) {
        console.log(`✅ SMS delivered via Fast2SMS to ${cleanPhone}`);
        console.log(`==============================================================\n`);
        return res.json({
          success: true,
          provider: 'fast2sms',
          message: `SMS delivered to ${to}`,
          to,
          studentName,
        });
      } else {
        console.warn(`⚠️ Fast2SMS returned error:`, smsResponse.data);
      }
    } catch (smsErr) {
      console.error(`❌ Fast2SMS call failed:`, smsErr?.response?.data || smsErr.message);
    }
  }

  // ── Twilio Integration (fallback if TWILIO_ACCOUNT_SID configured) ──
  const twilioSid = process.env.TWILIO_ACCOUNT_SID;
  const twilioToken = process.env.TWILIO_AUTH_TOKEN;
  const twilioFrom = process.env.TWILIO_FROM_NUMBER;
  if (twilioSid && twilioToken && twilioFrom) {
    try {
      const twilio = require('twilio')(twilioSid, twilioToken);
      const toNumber = to.startsWith('+') ? to : `+91${to.replace(/\D/g, '').slice(-10)}`;
      await twilio.messages.create({ body: message, from: twilioFrom, to: toNumber });
      console.log(`✅ SMS delivered via Twilio to ${to}`);
      console.log(`==============================================================\n`);
      return res.json({
        success: true,
        provider: 'twilio',
        message: `SMS delivered to ${to}`,
        to,
        studentName,
      });
    } catch (twilioErr) {
      console.error(`❌ Twilio call failed:`, twilioErr.message);
    }
  }

  // ── Simulated Fallback (no gateway configured) ──────────────────────
  console.log(`⚠️  No SMS gateway configured. SMS simulated (not actually sent).`);
  console.log(`   → To enable real SMS, add FAST2SMS_API_KEY to your .env file`);
  console.log(`   → Get free key at: https://www.fast2sms.com`);
  console.log(`==============================================================\n`);

  // Return 200 so app doesn't crash, but mark as simulated
  res.json({
    success: false,
    simulated: true,
    message: 'SMS gateway not configured — message logged only. Add FAST2SMS_API_KEY to .env to enable real SMS.',
    to,
    studentName,
  });
});


// ─── 404 Handler ────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` });
});

// ─── Global Error Handler ───────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Server Error:', err.stack || err.message);
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: isProduction ? 'Internal server error' : err.message,
  });
});

// ─── Graceful Shutdown ──────────────────────────────────────────────
const server = app.listen(PORT, () => {
  console.log(`\n🚀 Adyapan Unified Backend running on http://localhost:${PORT}`);
  console.log(`📦 Primary DB : TiDB Cloud (via Prisma)`);
  console.log(`🗄️  Secondary DB: AWS RDS MySQL (${RDS_ENABLED ? 'dual-write ON' : 'not configured'})`);
  console.log(`🪣 File Storage: AWS S3 (${S3_ENABLED ? 'enabled — bucket: ' + AWS_S3_BUCKET : 'not configured — using local fallback'})`);
  console.log(`🔐 Security   : Helmet + Rate Limit + CSRF + CORS`);
  console.log(`🌐 Environment: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}\n`);
});


async function gracefulShutdown(signal) {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  server.close(async () => {
    await prisma.$disconnect();
    console.log('✅ Database disconnected. Server closed.');
    process.exit(0);
  });

  // Force shutdown after 10s
  setTimeout(() => {
    console.error('⚠️ Forced shutdown after timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// ─── Unhandled Errors (prevent silent crashes) ──────────────────────
process.on('unhandledRejection', (reason, promise) => {
  console.error('⚠️ Unhandled Rejection:', reason);
  // Don't exit — log and continue
});

process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  // Exit on uncaught — state may be corrupted
  gracefulShutdown('uncaughtException');
});

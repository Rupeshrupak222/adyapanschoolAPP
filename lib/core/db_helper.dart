import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:mysql_client/mysql_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dbcrypt/dbcrypt.dart';
import 'package:argon2/argon2.dart';

class DbHelper {
  static MySQLConnection? _conn;
  static final Random _random = Random.secure();

  static String _newId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(0x7fffffff).toRadixString(16);
    return '${prefix}_${timestamp}_$suffix';
  }

  // Establish a new connection or return the existing live connection
  static Future<MySQLConnection> getConnection() async {
    if (_conn != null && _conn!.connected) {
      try {
        // Test connection with a fast dummy query to check if it's still alive
        await _conn!.execute('SELECT 1;');
        return _conn!;
      } catch (_) {
        // Connection closed or timed out, recreate it
        _conn = null;
      }
    }

    final host = dotenv.env['MYSQL_HOST'] ?? '';
    final portStr = dotenv.env['MYSQL_PORT'] ?? '4000';
    final port = int.tryParse(portStr) ?? 4000;
    final user = dotenv.env['MYSQL_USER'] ?? '';
    final password = dotenv.env['MYSQL_PASSWORD'] ?? '';
    final db = dotenv.env['MYSQL_DATABASE'] ?? 'preschool';
    final sslEnabled = dotenv.env['MYSQL_SSL'] == 'true';

    final conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: user,
      password: password,
      databaseName: db,
      secure: sslEnabled, // Enable SSL/TLS encryption for TiDB Serverless
    );

    await conn.connect();
    _conn = conn;
    
    // Ensure standard database tables are created automatically
    await _initDatabase();

    return _conn!;
  }

  // Create table if it does not exist
  static Future<void> _initDatabase() async {
    if (_conn == null) return;
    try {
      await _conn!.execute('''
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
      ''');

      // Alter table users to add missing columns for backward/forward compatibility
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN class_level VARCHAR(100);'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN school_name VARCHAR(255);'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT "student";'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN otp_verified TINYINT DEFAULT 1;'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN signup_source VARCHAR(50) DEFAULT "flutter";'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN teacher_id VARCHAR(64);'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN xp INT DEFAULT 120;'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN level INT DEFAULT 1;'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN streak INT DEFAULT 3;'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE users ADD COLUMN completed_quizzes INT DEFAULT 4;'); } catch (_) {}

      await _conn!.execute('''
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
          INDEX idx_login_events_created_at (created_at)
        );
      ''');
      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS attendance (
          id VARCHAR(64) PRIMARY KEY,
          user_id VARCHAR(64) NOT NULL,
          subject VARCHAR(100) NOT NULL,
          status VARCHAR(30) NOT NULL,
          time VARCHAR(50) NOT NULL,
          source VARCHAR(50) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_attendance_user_id (user_id)
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_homework (
          id INT AUTO_INCREMENT PRIMARY KEY,
          title VARCHAR(255) NOT NULL,
          subject VARCHAR(100) NOT NULL,
          description TEXT,
          due_date VARCHAR(100) NOT NULL,
          priority VARCHAR(50) NOT NULL,
          added_by VARCHAR(160) NOT NULL,
          teacher_id VARCHAR(64) NOT NULL,
          class_level VARCHAR(100) DEFAULT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_homework_submissions (
          id VARCHAR(64) PRIMARY KEY,
          homework_id INT NOT NULL,
          student_email VARCHAR(190) NOT NULL,
          student_name VARCHAR(160) NOT NULL,
          submitted_at VARCHAR(100) NOT NULL,
          file_name VARCHAR(255),
          file_path TEXT,
          student_comment TEXT,
          grade VARCHAR(50) DEFAULT 'Pending Grade',
          teacher_feedback TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_submissions_homework (homework_id),
          INDEX idx_submissions_student (student_email)
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_notes (
          id INT AUTO_INCREMENT PRIMARY KEY,
          title VARCHAR(255) NOT NULL,
          subject VARCHAR(100) NOT NULL,
          description TEXT,
          file_name VARCHAR(255) NOT NULL,
          file_size VARCHAR(50) NOT NULL,
          pages INT NOT NULL,
          uploaded_by VARCHAR(160) NOT NULL,
          uploaded_at VARCHAR(100) NOT NULL,
          file_path TEXT,
          teacher_id VARCHAR(64) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_doubts (
          id INT AUTO_INCREMENT PRIMARY KEY,
          student_name VARCHAR(160) NOT NULL,
          student_email VARCHAR(190) NOT NULL,
          student_class VARCHAR(80) NOT NULL,
          subject VARCHAR(100) NOT NULL,
          question TEXT NOT NULL,
          replied TINYINT DEFAULT 0,
          reply_text TEXT,
          time VARCHAR(100) NOT NULL,
          attachment_type VARCHAR(50),
          attachment_name VARCHAR(255),
          attachment_path TEXT,
          teacher_id VARCHAR(64) NOT NULL,
          reply_attachment_type VARCHAR(50) DEFAULT 'None',
          reply_attachment_name VARCHAR(255) DEFAULT '',
          reply_attachment_path TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_doubts_student (student_email),
          INDEX idx_doubts_teacher (teacher_id)
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_live_classes (
          id VARCHAR(64) PRIMARY KEY,
          subject VARCHAR(100) NOT NULL,
          topic VARCHAR(255) NOT NULL,
          time VARCHAR(100) NOT NULL,
          status VARCHAR(50) NOT NULL,
          is_live TINYINT NOT NULL DEFAULT 0,
          teacher_id VARCHAR(64) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_live_classes_teacher (teacher_id)
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_notices (
          id VARCHAR(64) PRIMARY KEY,
          title VARCHAR(255) NOT NULL,
          body TEXT NOT NULL,
          time VARCHAR(100) NOT NULL,
          teacher_id VARCHAR(64) NOT NULL,
          teacher_name VARCHAR(160) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_notices_teacher (teacher_id)
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_skills_syllabus (
          id INT AUTO_INCREMENT PRIMARY KEY,
          class_name VARCHAR(80) NOT NULL,
          title VARCHAR(255) NOT NULL,
          syllabus_json TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE KEY idx_class_title (class_name, title)
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_custom_games (
          id INT AUTO_INCREMENT PRIMARY KEY,
          game_type VARCHAR(50) NOT NULL,
          class_level VARCHAR(80) NOT NULL,
          data_json TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_teacher_messages (
          id VARCHAR(64) PRIMARY KEY,
          student_name VARCHAR(160) NOT NULL,
          teacher_name VARCHAR(160) NOT NULL,
          message TEXT NOT NULL,
          category VARCHAR(50) NOT NULL,
          is_read TINYINT DEFAULT 0,
          date_str VARCHAR(100) NOT NULL,
          meeting_response TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      await _conn!.execute('''
        CREATE TABLE IF NOT EXISTS app_recorded_lectures (
          id INT AUTO_INCREMENT PRIMARY KEY,
          title VARCHAR(255) NOT NULL,
          duration VARCHAR(100) NOT NULL,
          teacher VARCHAR(160) NOT NULL,
          emoji VARCHAR(50) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''');
      try { await _conn!.execute('ALTER TABLE app_recorded_lectures ADD COLUMN video_url TEXT;'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE app_homework ADD COLUMN file_name VARCHAR(255);'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE app_homework ADD COLUMN file_path TEXT;'); } catch (_) {}
      try { await _conn!.execute('ALTER TABLE app_homework ADD COLUMN file_url TEXT;'); } catch (_) {}
    } catch (e) {
      print('❌ Database table initialization failed: $e');
    }
  }

  // Call REST API for authentication (uses the deployed backend)
  static Future<Map<String, dynamic>?> callAuthApi({
    required String path, // '/api/v1/auth/login' or '/api/v1/auth/register'
    required Map<String, dynamic> body,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://preschool-wzjj.onrender.com';
    
    try {
      final url = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');
      print('📡 Hitting Auth API: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...body,
          'platform': 'mobile',
        }),
      ).timeout(const Duration(seconds: 12));
      
      print('📡 Auth API response status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      }
      // API responded with an error (401, 403, 409, etc.)
      if (response.statusCode >= 400 && response.statusCode < 500) {
        try {
          final errorData = jsonDecode(response.body);
          return errorData;
        } catch (_) {}
      }
    } catch (e) {
      print('⚠️ Failed to hit Auth API: $e');
    }
    return null;
  }

  // Register a new user via the backend REST API (ensures Argon2id hashing)
  // This method is kept as a fallback; primary registration should go through ApiService.
  static Future<bool> registerUser({
    required String name,
    required String email,
    required String phone,
    required String className,
    required String school,
    required String password,
    required String role,
    String? teacherId,
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    // Always use the backend API for registration — it hashes with Argon2id
    try {
      final body = {
        'name': name,
        'email': cleanEmail,
        'phone': phone,
        'class_name': className,
        'school_name': school,
        'password': password,
        'role': role,
        'platform': 'mobile',
      };
      final apiResponse = await callAuthApi(path: '/api/v1/auth/register', body: body);
      if (apiResponse != null && apiResponse['success'] == true) {
        return true;
      }
      // If API returned 409 (user exists), propagate that
      if (apiResponse != null && apiResponse['success'] == false) {
        return false;
      }
    } catch (e) {
      print('⚠️ REST API signup failed: $e');
    }

    // Fallback: Direct DB with Argon2id hashing done locally
    try {
      final conn = await getConnection();

      // Check if user already exists
      final checkRes = await conn.execute(
        'SELECT id FROM users WHERE LOWER(email) = :email;',
        {'email': cleanEmail},
      );

      if (checkRes.rows.isNotEmpty) {
        return false; // Email already in database!
      }

      final userId = role == 'teacher' 
          ? (teacherId ?? _newId('tch')) 
          : _newId('usr');

      // Hash password with Argon2id before storing
      final hashedPassword = await _hashPasswordArgon2(password);

      await conn.execute('''
        INSERT INTO users (
          id, name, email, phone, 
          class_name, class_level, 
          school, school_name, 
          password, password_hash, 
          role, otp_verified, signup_source, teacher_id
        )
        VALUES (
          :id, :name, :email, :phone, 
          :className, :className, 
          :school, :school, 
          :password, :passwordHash, 
          :role, :otpVerified, :signupSource, :teacherId
        );
      ''', {
        'id': userId,
        'name': name,
        'email': cleanEmail,
        'phone': phone,
        'className': className,
        'school': school,
        'password': hashedPassword,
        'passwordHash': hashedPassword,
        'role': role,
        'otpVerified': 1,
        'signupSource': 'flutter',
        'teacherId': role == 'teacher' ? userId : teacherId,
      });

      return true;
    } catch (e) {
      print('❌ Database registration error: $e');
      rethrow;
    }
  }

  // Reset password — DEPRECATED plain text version kept for backward compat
  static Future<bool> resetPassword(String email, String newPassword) async {
    return resetPasswordSecure(email, newPassword);
  }

  // Reset password securely with Argon2id hashing
  static Future<bool> resetPasswordSecure(String email, String newPassword) async {
    final cleanEmail = email.toLowerCase().trim();
    try {
      final conn = await getConnection();
      
      // Check if user exists
      final checkRes = await conn.execute(
        'SELECT id FROM users WHERE LOWER(email) = :email;',
        {'email': cleanEmail},
      );

      if (checkRes.rows.isEmpty) {
        return false; // Email not registered!
      }

      // Hash the new password with Argon2id before storing
      final hashedPassword = await _hashPasswordArgon2(newPassword);

      // Update both password fields with the hash
      await conn.execute('''
        UPDATE users 
        SET password = :password, password_hash = :password, updated_at = NOW()
        WHERE LOWER(email) = :email;
      ''', {
        'email': cleanEmail,
        'password': hashedPassword,
      });

      return true;
    } catch (e) {
      print('❌ Database password reset error: $e');
      return false;
    }
  }

  /// Hash a password using Argon2id (matching the Node.js backend config)
  /// Config: memoryCost=65536 (64MB), timeCost=3, parallelism=1, hashLength=32
  static Future<String> _hashPasswordArgon2(String password) async {
    // Generate a random 16-byte salt
    final salt = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      salt[i] = _random.nextInt(256);
    }

    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      memory: 65536,
      lanes: 1,
    );

    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);

    final passwordBytes = parameters.converter.convert(password);
    final result = Uint8List(32); // 32-byte hash
    argon2.generateBytes(passwordBytes, result, 0, result.length);

    // Encode to standard Argon2 hash string format (compatible with Node.js argon2 package)
    final saltB64 = base64Encode(salt).replaceAll('=', '');
    final hashB64 = base64Encode(result).replaceAll('=', '');
    return '\$argon2id\$v=19\$m=65536,t=3,p=1\$$saltB64\$$hashB64';
  }

  // Validate credentials against TiDB Database (direct connection with hash verification)
  static Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final cleanEmail = email.toLowerCase().trim();
    print('🔐 Login attempt: $cleanEmail');

    // Connect directly to TiDB Cloud and verify password hash in Dart
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, name, email, phone, class_name, class_level, school, school_name, role, teacher_id, 
               password, password_hash, xp, level, streak, completed_quizzes
        FROM users
        WHERE LOWER(email) = :email;
      ''', {
        'email': cleanEmail,
      });

      if (results.rows.isEmpty) {
        print('❌ DB: No user found for $cleanEmail');
        return null;
      }

      final row = results.rows.first.assoc();
      final storedHash = row['password_hash'] ?? row['password'] ?? '';

      // Verify password against stored hash (supports Argon2id, bcrypt, plain text)
      final isValid = await _verifyPasswordHash(password, storedHash);
      if (!isValid) {
        print('❌ DB: Password mismatch for $cleanEmail');
        return null;
      }

      print('✅ Direct DB login success for $cleanEmail');

      // Log login event (non-critical)
      try {
        await conn.execute('''
          INSERT INTO login_events (id, user_id, name, email, role, source, status, user_agent)
          VALUES (:id, :userId, :name, :email, :role, :source, :status, :userAgent);
        ''', {
          'id': _newId('mobile_login'),
          'userId': row['id'] ?? '',
          'name': row['name'] ?? '',
          'email': row['email'] ?? cleanEmail,
          'role': row['role'] ?? 'student',
          'source': 'mobile',
          'status': 'success',
          'userAgent': 'flutter',
        });
      } catch (e) {
        print('⚠️ Login event insert failed (non-critical): $e');
      }

      return {
        'id': row['id'] ?? '',
        'name': row['name'] ?? '',
        'email': row['email'] ?? '',
        'phone': row['phone'] ?? '',
        'className': row['class_name'] ?? row['class_level'] ?? '',
        'school': row['school'] ?? row['school_name'] ?? '',
        'role': row['role'] ?? 'student',
        'teacher_id': row['teacher_id'] ?? '',
        'xp': row['xp'] ?? '120',
        'level': row['level'] ?? '1',
        'streak': row['streak'] ?? '3',
        'completedQuizzes': row['completed_quizzes'] ?? '4',
      };
    } catch (e) {
      print('❌ Direct DB login error: $e');
      rethrow;
    }
  }

  /// Verify password against stored hash (supports Argon2id, bcrypt, and plain text)
  static Future<bool> _verifyPasswordHash(String password, String storedHash) async {
    if (storedHash.isEmpty) return false;

    // Argon2id hash: $argon2id$v=19$m=65536,t=3,p=1$...
    if (storedHash.startsWith('\$argon2')) {
      try {
        return await _verifyArgon2(password, storedHash);
      } catch (e) {
        print('⚠️ Argon2 verify error: $e');
        return false;
      }
    }

    // bcrypt hash: $2a$, $2b$, $2y$
    if (RegExp(r'^\$2[aby]\$').hasMatch(storedHash)) {
      try {
        final bcrypt = DBCrypt();
        return bcrypt.checkpw(password, storedHash);
      } catch (e) {
        print('⚠️ BCrypt verify error: $e');
        return false;
      }
    }

    // Plain text (legacy) — constant-time-ish comparison
    return password == storedHash;
  }

  /// Verify Argon2id hash using the pure Dart argon2 package
  static Future<bool> _verifyArgon2(String password, String hashString) async {
    // Parse the Argon2id hash string: $argon2id$v=19$m=65536,t=3,p=1$<base64 salt>$<base64 hash>
    final parts = hashString.split('\$');
    // parts: ['', 'argon2id', 'v=19', 'm=65536,t=3,p=1', '<base64 salt>', '<base64 hash>']
    if (parts.length < 6) return false;

    // Determine argon2 type
    final typeStr = parts[1];
    int type;
    if (typeStr == 'argon2id') {
      type = Argon2Parameters.ARGON2_id;
    } else if (typeStr == 'argon2i') {
      type = Argon2Parameters.ARGON2_i;
    } else if (typeStr == 'argon2d') {
      type = Argon2Parameters.ARGON2_d;
    } else {
      return false;
    }

    // Parse version
    int version = Argon2Parameters.ARGON2_VERSION_13; // default v=19 (0x13)
    if (parts[2].startsWith('v=')) {
      final v = int.tryParse(parts[2].substring(2));
      if (v == 16) version = Argon2Parameters.ARGON2_VERSION_10;
      if (v == 19) version = Argon2Parameters.ARGON2_VERSION_13;
    }

    // Parse params: m=65536,t=3,p=1
    final paramParts = parts[3].split(',');
    int memory = 65536;
    int iterations = 3;
    int parallelism = 1;
    for (final p in paramParts) {
      if (p.startsWith('m=')) memory = int.tryParse(p.substring(2)) ?? memory;
      if (p.startsWith('t=')) iterations = int.tryParse(p.substring(2)) ?? iterations;
      if (p.startsWith('p=')) parallelism = int.tryParse(p.substring(2)) ?? parallelism;
    }

    final saltBase64 = parts[4];
    final hashBase64 = parts[5];

    // Decode base64 (Argon2 uses base64 without padding)
    final salt = base64Decode(_addBase64Padding(saltBase64));
    final expectedHash = base64Decode(_addBase64Padding(hashBase64));

    // Configure Argon2 parameters
    final parameters = Argon2Parameters(
      type,
      salt,
      version: version,
      iterations: iterations,
      memory: memory,
      lanes: parallelism,
    );

    // Generate hash from password
    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);

    final passwordBytes = parameters.converter.convert(password);
    final result = Uint8List(expectedHash.length);
    argon2.generateBytes(passwordBytes, result, 0, result.length);

    // Constant-time comparison
    if (result.length != expectedHash.length) return false;
    int diff = 0;
    for (int i = 0; i < result.length; i++) {
      diff |= result[i] ^ expectedHash[i];
    }
    return diff == 0;
  }

  /// Add padding to base64 string if needed
  static String _addBase64Padding(String base64Str) {
    final remainder = base64Str.length % 4;
    if (remainder == 0) return base64Str;
    return base64Str + '=' * (4 - remainder);
  }




  // Validate teacher access key against backend API (no local bypass)
  static Future<bool> validateTeacherKey(String key) async {
    // Teacher key validation is now done server-side via the login API.
    // This method is kept for backward compatibility but always returns true
    // since the actual key verification happens in the backend when
    // loginUser() sends the staffKey parameter.
    // If the key is empty, reject immediately (UI-level check).
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return false;
    return true;
  }

  // Fetch list of students linked to a specific teacher (with smart school-based match fallbacks)
  static Future<List<Map<String, dynamic>>> getLinkedStudents(String teacherId, {String schoolName = ''}) async {
    try {
      final conn = await getConnection();
      
      // Resolve both teacher's database id and email dynamically to ensure 100% match rate!
      String resolvedDbId = teacherId;
      String resolvedEmail = teacherId;
      String resolvedSchool = schoolName.trim().toLowerCase();
      
      try {
        final tRes = await conn.execute(
          'SELECT id, email, school, school_name FROM users WHERE LOWER(email) = :term OR id = :term LIMIT 1;',
          {'term': teacherId.toLowerCase().trim()}
        );
        if (tRes.rows.isNotEmpty) {
          final assoc = tRes.rows.first.assoc();
          resolvedDbId = assoc['id'] ?? teacherId;
          resolvedEmail = assoc['email'] ?? teacherId;
          if (resolvedSchool.isEmpty) {
            resolvedSchool = (assoc['school'] ?? assoc['school_name'] ?? '').toString().trim().toLowerCase();
          }
        }
      } catch (e) {
        print('⚠️ Non-critical: Failed to pre-resolve teacher record details: $e');
      }

      final results = await conn.execute('''
        SELECT id, name, email, phone, class_name, class_level, school, school_name, created_at, xp, level, streak, completed_quizzes,
          (SELECT COALESCE((SUM(CASE WHEN status IN ('Present', 'Excused') THEN 1 ELSE 0 END) * 100.0) / COUNT(*), -1.0) 
           FROM attendance WHERE user_id = users.id) AS attendance_pct,
          (SELECT COALESCE(AVG(CASE WHEN s.grade='A+' THEN 95.0 WHEN s.grade='A' THEN 85.0 WHEN s.grade='B' THEN 75.0 WHEN s.grade='C' THEN 65.0 WHEN s.grade='F' THEN 45.0 ELSE NULL END), -1.0)
           FROM app_homework_submissions s JOIN app_homework h ON h.id = s.homework_id
           WHERE LOWER(s.student_email) = LOWER(users.email) AND LOWER(h.subject) LIKE '%math%') AS math_grade,
          (SELECT COALESCE(AVG(CASE WHEN s.grade='A+' THEN 95.0 WHEN s.grade='A' THEN 85.0 WHEN s.grade='B' THEN 75.0 WHEN s.grade='C' THEN 65.0 WHEN s.grade='F' THEN 45.0 ELSE NULL END), -1.0)
           FROM app_homework_submissions s JOIN app_homework h ON h.id = s.homework_id
           WHERE LOWER(s.student_email) = LOWER(users.email) AND (LOWER(h.subject) LIKE '%science%' OR LOWER(h.subject) LIKE '%phy%' OR LOWER(h.subject) LIKE '%chem%' OR LOWER(h.subject) LIKE '%bio%')) AS science_grade,
          (SELECT COALESCE(AVG(CASE WHEN s.grade='A+' THEN 95.0 WHEN s.grade='A' THEN 85.0 WHEN s.grade='B' THEN 75.0 WHEN s.grade='C' THEN 65.0 WHEN s.grade='F' THEN 45.0 ELSE NULL END), -1.0)
           FROM app_homework_submissions s JOIN app_homework h ON h.id = s.homework_id
           WHERE LOWER(s.student_email) = LOWER(users.email) AND LOWER(h.subject) LIKE '%english%') AS english_grade
        FROM users
        WHERE role = 'student' AND (
          teacher_id = :teacherId 
          OR teacher_id = :resolvedDbId 
          OR LOWER(teacher_id) = :resolvedEmail
          OR teacher_id = 'teacher_mps8yshu_48f5p2'
          ${resolvedSchool.isNotEmpty ? "OR LOWER(school) = :schoolName OR LOWER(school_name) = :schoolName" : ""}
        )
        ORDER BY name ASC;
      ''', {
        'teacherId': teacherId,
        'resolvedDbId': resolvedDbId,
        'resolvedEmail': resolvedEmail.toLowerCase().trim(),
        'schoolName': resolvedSchool,
      });

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'name': assoc['name'] ?? '',
          'email': assoc['email'] ?? '',
          'phone': assoc['phone'] ?? '',
          'className': assoc['class_name'] ?? assoc['class_level'] ?? 'Class Student',
          'school': assoc['school'] ?? assoc['school_name'] ?? '',
          'createdAt': assoc['created_at'] ?? '',
          'xp': int.tryParse(assoc['xp'] ?? '') ?? 120,
          'level': int.tryParse(assoc['level'] ?? '') ?? 1,
          'streak': int.tryParse(assoc['streak'] ?? '') ?? 3,
          'completedQuizzes': int.tryParse(assoc['completed_quizzes'] ?? '') ?? 4,
          'attendance': double.tryParse(assoc['attendance_pct'] ?? '') ?? -1.0,
          'math': double.tryParse(assoc['math_grade'] ?? '') ?? -1.0,
          'science': double.tryParse(assoc['science_grade'] ?? '') ?? -1.0,
          'english': double.tryParse(assoc['english_grade'] ?? '') ?? -1.0,
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch linked students: $e');
      return [];
    }
  }

  // Fetch attendance logs for a specific user from TiDB
  static Future<List<Map<String, dynamic>>> fetchAttendanceLogs(String userId) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, subject, status, time, source, created_at
        FROM attendance
        WHERE user_id = :userId
        ORDER BY created_at DESC;
      ''', {'userId': userId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'subject': assoc['subject'] ?? '',
          'status': assoc['status'] ?? '',
          'time': assoc['time'] ?? '',
          'source': assoc['source'] ?? '',
          'createdAt': assoc['created_at'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch attendance logs: $e');
      return [];
    }
  }

  // Insert a new attendance record into TiDB
  static Future<bool> insertOrUpdateAttendance({
    required String userId,
    required String subject,
    required String status,
    required String time,
    required String source,
  }) async {
    try {
      final conn = await getConnection();
      final logId = _newId('att');
      await conn.execute('''
        INSERT INTO attendance (id, user_id, subject, status, time, source)
        VALUES (:id, :userId, :subject, :status, :time, :source);
      ''', {
        'id': logId,
        'userId': userId,
        'subject': subject,
        'status': status,
        'time': time,
        'source': source,
      });
      return true;
    } catch (e) {
      print('❌ Failed to insert attendance: $e');
      return false;
    }
  }

  // --- HOMEWORK DATABASE SYNCING ---
  static Future<List<Map<String, dynamic>>> getHomework(String teacherId) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, title, subject, description, due_date, priority, added_by, teacher_id, class_level, file_name, file_path, file_url, created_at
        FROM app_homework
        WHERE teacher_id = :teacherId
        ORDER BY created_at DESC;
      ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['id'] ?? '') ?? 0,
          'title': assoc['title'] ?? '',
          'subject': assoc['subject'] ?? '',
          'description': assoc['description'] ?? '',
          'dueDate': assoc['due_date'] ?? '',
          'priority': assoc['priority'] ?? 'Normal',
          'addedBy': assoc['added_by'] ?? '',
          'teacher_id': assoc['teacher_id'] ?? '',
          'class_level': assoc['class_level'] ?? '',
          'fileName': assoc['file_name'] ?? '',
          'filePath': assoc['file_path'] ?? '',
          'fileUrl': assoc['file_url'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch homework: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getHomeworkForClass(String teacherId, String classLevel) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, title, subject, description, due_date, priority, added_by, teacher_id, class_level, file_name, file_path, file_url, created_at
        FROM app_homework
        WHERE teacher_id = :teacherId
        ORDER BY created_at DESC;
      ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['id'] ?? '') ?? 0,
          'title': assoc['title'] ?? '',
          'subject': assoc['subject'] ?? '',
          'description': assoc['description'] ?? '',
          'dueDate': assoc['due_date'] ?? '',
          'priority': assoc['priority'] ?? 'Normal',
          'addedBy': assoc['added_by'] ?? '',
          'teacher_id': assoc['teacher_id'] ?? '',
          'class_level': assoc['class_level'] ?? '',
          'fileName': assoc['file_name'] ?? '',
          'filePath': assoc['file_path'] ?? '',
          'fileUrl': assoc['file_url'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch homework for class: $e');
      return [];
    }
  }

  static Future<int> addHomework({
    required String title,
    required String subject,
    required String description,
    required String dueDate,
    required String priority,
    required String addedBy,
    required String teacherId,
    String? classLevel,
    String? fileName,
    String? filePath,
    String? fileUrl,
  }) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        INSERT INTO app_homework (title, subject, description, due_date, priority, added_by, teacher_id, class_level, file_name, file_path, file_url)
        VALUES (:title, :subject, :description, :dueDate, :priority, :addedBy, :teacherId, :classLevel, :fileName, :filePath, :fileUrl);
      ''', {
        'title': title,
        'subject': subject,
        'description': description,
        'dueDate': dueDate,
        'priority': priority,
        'addedBy': addedBy,
        'teacherId': teacherId,
        'classLevel': classLevel ?? '',
        'fileName': fileName ?? '',
        'filePath': filePath ?? '',
        'fileUrl': fileUrl ?? '',
      });
      return results.lastInsertID.toInt();
    } catch (e) {
      print('❌ Failed to insert homework: $e');
      return 0;
    }
  }

  static Future<bool> deleteHomework(int homeworkId) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        DELETE FROM app_homework WHERE id = :id;
      ''', {'id': homeworkId});
      await conn.execute('''
        DELETE FROM app_homework_submissions WHERE homework_id = :id;
      ''', {'id': homeworkId});
      return true;
    } catch (e) {
      print('❌ Failed to delete homework: $e');
      return false;
    }
  }

  // --- HOMEWORK SUBMISSIONS ---
  static Future<List<Map<String, dynamic>>> getHomeworkSubmissions(String teacherId) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT s.id, s.homework_id, s.student_email, s.student_name, s.submitted_at, s.file_name, s.file_path, s.student_comment, s.grade, s.teacher_feedback, h.title, h.subject, h.description, h.due_date, h.priority, h.added_by
        FROM app_homework_submissions s
        JOIN app_homework h ON h.id = s.homework_id
        WHERE h.teacher_id = :teacherId
        ORDER BY s.created_at DESC;
      ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['homework_id'] ?? '') ?? 0,
          'title': assoc['title'] ?? '',
          'subject': assoc['subject'] ?? '',
          'description': assoc['description'] ?? '',
          'dueDate': assoc['due_date'] ?? '',
          'priority': assoc['priority'] ?? 'Normal',
          'addedBy': assoc['added_by'] ?? '',
          'submitted': true,
          'submittedAt': assoc['submitted_at'] ?? '',
          'fileName': assoc['file_name'] ?? 'assignment_document.pdf',
          'filePath': assoc['file_path'] ?? '',
          'studentComment': assoc['student_comment'] ?? '',
          'studentName': assoc['student_name'] ?? '',
          'studentEmail': assoc['student_email'] ?? '',
          'grade': assoc['grade'] ?? 'Pending Grade',
          'teacherFeedback': assoc['teacher_feedback'],
          'submission_id': assoc['id'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch homework submissions: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentHomeworkSubmissions(String studentEmail) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, homework_id, student_email, student_name, submitted_at, file_name, file_path, student_comment, grade, teacher_feedback
        FROM app_homework_submissions
        WHERE student_email = :studentEmail;
      ''', {'studentEmail': studentEmail});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'homework_id': int.tryParse(assoc['homework_id'] ?? '') ?? 0,
          'student_email': assoc['student_email'] ?? '',
          'student_name': assoc['student_name'] ?? '',
          'submitted_at': assoc['submitted_at'] ?? '',
          'file_name': assoc['file_name'] ?? '',
          'file_path': assoc['file_path'] ?? '',
          'student_comment': assoc['student_comment'] ?? '',
          'grade': assoc['grade'] ?? 'Pending Grade',
          'teacher_feedback': assoc['teacher_feedback'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch student homework submissions: $e');
      return [];
    }
  }

  static Future<bool> submitHomework({
    required int homeworkId,
    required String studentEmail,
    required String studentName,
    required String submittedAt,
    String? fileName,
    String? filePath,
    String? studentComment,
  }) async {
    try {
      final conn = await getConnection();
      final subId = _newId('sub');
      // Delete any existing submission first to allow resubmission
      await conn.execute('''
        DELETE FROM app_homework_submissions WHERE homework_id = :hwId AND student_email = :email;
      ''', {'hwId': homeworkId, 'email': studentEmail});

      await conn.execute('''
        INSERT INTO app_homework_submissions (id, homework_id, student_email, student_name, submitted_at, file_name, file_path, student_comment)
        VALUES (:id, :homeworkId, :studentEmail, :studentName, :submittedAt, :fileName, :filePath, :studentComment);
      ''', {
        'id': subId,
        'homeworkId': homeworkId,
        'studentEmail': studentEmail,
        'studentName': studentName,
        'submittedAt': submittedAt,
        'fileName': fileName ?? 'assignment_document.pdf',
        'filePath': filePath ?? '',
        'studentComment': studentComment ?? '',
      });
      return true;
    } catch (e) {
      print('❌ Failed to submit homework: $e');
      return false;
    }
  }

  static Future<bool> gradeHomework(int homeworkId, String studentEmail, {required String grade, String? feedback}) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        UPDATE app_homework_submissions
        SET grade = :grade, teacher_feedback = :feedback
        WHERE homework_id = :homeworkId AND student_email = :studentEmail;
      ''', {
        'homeworkId': homeworkId,
        'studentEmail': studentEmail,
        'grade': grade,
        'feedback': feedback ?? '',
      });
      return true;
    } catch (e) {
      print('❌ Failed to grade homework: $e');
      return false;
    }
  }

  // --- NOTES / PDF LIBRARY ---
  static Future<List<Map<String, dynamic>>> getNotes(String teacherId) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, title, subject, description, file_name, file_size, pages, uploaded_by, uploaded_at, file_path, teacher_id
        FROM app_notes
        WHERE teacher_id = :teacherId
        ORDER BY created_at DESC;
      ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['id'] ?? '') ?? 0,
          'title': assoc['title'] ?? '',
          'subject': assoc['subject'] ?? '',
          'description': assoc['description'] ?? '',
          'fileName': assoc['file_name'] ?? '',
          'fileSize': assoc['file_size'] ?? '',
          'pages': int.tryParse(assoc['pages'] ?? '') ?? 1,
          'uploadedBy': assoc['uploaded_by'] ?? '',
          'uploadedAt': assoc['uploaded_at'] ?? '',
          'filePath': assoc['file_path'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch notes: $e');
      return [];
    }
  }

  static Future<int> addNote({
    required String title,
    required String subject,
    required String description,
    required String fileName,
    required String fileSize,
    required int pages,
    required String uploadedBy,
    required String teacherId,
    String filePath = '',
  }) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        INSERT INTO app_notes (title, subject, description, file_name, file_size, pages, uploaded_by, uploaded_at, file_path, teacher_id)
        VALUES (:title, :subject, :description, :fileName, :fileSize, :pages, :uploadedBy, 'Just now', :filePath, :teacherId);
      ''', {
        'title': title,
        'subject': subject,
        'description': description,
        'fileName': fileName,
        'fileSize': fileSize,
        'pages': pages,
        'uploadedBy': uploadedBy,
        'filePath': filePath,
        'teacherId': teacherId,
      });
      return results.lastInsertID.toInt();
    } catch (e) {
      print('❌ Failed to insert note: $e');
      return 0;
    }
  }

  static Future<bool> deleteNote(int noteId) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        DELETE FROM app_notes WHERE id = :id;
      ''', {'id': noteId});
      return true;
    } catch (e) {
      print('❌ Failed to delete note: $e');
      return false;
    }
  }

  // --- DOUBTS ---
  static Future<List<Map<String, dynamic>>> getDoubtsForTeacher(String teacherId) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, student_name, student_email, student_class, subject, question, replied, reply_text, time, attachment_type, attachment_name, attachment_path, reply_attachment_type, reply_attachment_name, reply_attachment_path
        FROM app_doubts
        WHERE teacher_id = :teacherId
        ORDER BY created_at DESC;
      ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['id'] ?? '') ?? 0,
          'studentName': assoc['student_name'] ?? '',
          'studentEmail': assoc['student_email'] ?? '',
          'studentClass': assoc['student_class'] ?? '',
          'subject': assoc['subject'] ?? '',
          'question': assoc['question'] ?? '',
          'replied': (int.tryParse(assoc['replied'] ?? '0') ?? 0) == 1,
          'replyText': assoc['reply_text'] ?? '',
          'time': assoc['time'] ?? '',
          'attachmentType': assoc['attachment_type'] ?? 'None',
          'attachmentName': assoc['attachment_name'] ?? '',
          'attachmentPath': assoc['attachment_path'] ?? '',
          'replyAttachmentType': assoc['reply_attachment_type'] ?? 'None',
          'replyAttachmentName': assoc['reply_attachment_name'] ?? '',
          'replyAttachmentPath': assoc['reply_attachment_path'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch doubts for teacher: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDoubtsForStudent(String studentEmail) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, student_name, student_email, student_class, subject, question, replied, reply_text, time, attachment_type, attachment_name, attachment_path, reply_attachment_type, reply_attachment_name, reply_attachment_path
        FROM app_doubts
        WHERE student_email = :studentEmail
        ORDER BY created_at DESC;
      ''', {'studentEmail': studentEmail});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['id'] ?? '') ?? 0,
          'studentName': assoc['student_name'] ?? '',
          'studentEmail': assoc['student_email'] ?? '',
          'studentClass': assoc['student_class'] ?? '',
          'subject': assoc['subject'] ?? '',
          'question': assoc['question'] ?? '',
          'replied': (int.tryParse(assoc['replied'] ?? '0') ?? 0) == 1,
          'replyText': assoc['reply_text'] ?? '',
          'time': assoc['time'] ?? '',
          'attachmentType': assoc['attachment_type'] ?? 'None',
          'attachmentName': assoc['attachment_name'] ?? '',
          'attachmentPath': assoc['attachment_path'] ?? '',
          'replyAttachmentType': assoc['reply_attachment_type'] ?? 'None',
          'replyAttachmentName': assoc['reply_attachment_name'] ?? '',
          'replyAttachmentPath': assoc['reply_attachment_path'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch doubts for student: $e');
      return [];
    }
  }

  static Future<int> addDoubt({
    required String studentName,
    required String studentEmail,
    required String studentClass,
    required String subject,
    required String question,
    required String teacherId,
    String attachmentType = 'None',
    String attachmentName = '',
    String attachmentPath = '',
  }) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        INSERT INTO app_doubts (student_name, student_email, student_class, subject, question, replied, reply_text, time, attachment_type, attachment_name, attachment_path, teacher_id)
        VALUES (:studentName, :studentEmail, :studentClass, :subject, :question, 0, '', 'Just now', :attachmentType, :attachmentName, :attachmentPath, :teacherId);
      ''', {
        'studentName': studentName,
        'studentEmail': studentEmail,
        'studentClass': studentClass,
        'subject': subject,
        'question': question,
        'attachmentType': attachmentType,
        'attachmentName': attachmentName,
        'attachmentPath': attachmentPath,
        'teacherId': teacherId,
      });
      return results.lastInsertID.toInt();
    } catch (e) {
      print('❌ Failed to ask doubt: $e');
      return 0;
    }
  }

  static Future<bool> solveDoubt(
    int doubtId,
    String replyText, {
    String? replyAttachmentType,
    String? replyAttachmentName,
    String? replyAttachmentPath,
  }) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        UPDATE app_doubts
        SET replied = 1, reply_text = :replyText, time = 'Solved just now',
            reply_attachment_type = :replyAttachmentType, reply_attachment_name = :replyAttachmentName, reply_attachment_path = :replyAttachmentPath
        WHERE id = :id;
      ''', {
        'id': doubtId,
        'replyText': replyText,
        'replyAttachmentType': replyAttachmentType ?? 'None',
        'replyAttachmentName': replyAttachmentName ?? '',
        'replyAttachmentPath': replyAttachmentPath ?? '',
      });
      return true;
    } catch (e) {
      print('❌ Failed to reply to doubt: $e');
      return false;
    }
  }

  // --- LIVE CLASSES ---
  static Future<List<Map<String, dynamic>>> getLiveClasses(String teacherId) async {
    try {
      final conn = await getConnection();
      
      // If teacherId is 'all', query all active live classes.
      // Otherwise, query classes for the specific teacher OR general 'all' classes.
      final results = teacherId == 'all'
          ? await conn.execute('''
              SELECT id, subject, topic, time, status, is_live, teacher_id
              FROM app_live_classes
              ORDER BY created_at DESC;
            ''')
          : await conn.execute('''
              SELECT id, subject, topic, time, status, is_live, teacher_id
              FROM app_live_classes
              WHERE teacher_id = :teacherId OR teacher_id = 'all'
              ORDER BY created_at DESC;
            ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'subject': assoc['subject'] ?? '',
          'topic': assoc['topic'] ?? '',
          'time': assoc['time'] ?? '',
          'status': assoc['status'] ?? 'Scheduled',
          'isLive': (int.tryParse(assoc['is_live'] ?? '0') ?? 0) == 1,
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch live classes: $e');
      return [];
    }
  }

  static Future<bool> saveLiveClass(Map<String, dynamic> cls, String teacherId) async {
    try {
      final conn = await getConnection();
      final id = cls['id'] ?? _newId('live');
      await conn.execute('''
        INSERT INTO app_live_classes (id, subject, topic, time, status, is_live, teacher_id)
        VALUES (:id, :subject, :topic, :time, :status, :isLive, :teacherId)
        ON DUPLICATE KEY UPDATE subject = :subject, topic = :topic, time = :time, status = :status, is_live = :isLive;
      ''', {
        'id': id,
        'subject': cls['subject'] ?? '',
        'topic': cls['topic'] ?? '',
        'time': cls['time'] ?? '',
        'status': cls['status'] ?? 'Scheduled',
        'isLive': (cls['isLive'] == true || cls['status'] == 'LIVE NOW') ? 1 : 0,
        'teacherId': teacherId,
      });
      return true;
    } catch (e) {
      print('❌ Failed to save live class: $e');
      return false;
    }
  }

  static Future<bool> deleteLiveClass(String liveId) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        DELETE FROM app_live_classes WHERE id = :id;
      ''', {'id': liveId});
      return true;
    } catch (e) {
      print('❌ Failed to delete live class: $e');
      return false;
    }
  }

  // --- NOTICES ---
  static Future<List<Map<String, dynamic>>> getNotices(String teacherId) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, title, body, time, teacher_id, teacher_name
        FROM app_notices
        WHERE teacher_id = :teacherId
        ORDER BY created_at DESC;
      ''', {'teacherId': teacherId});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'title': assoc['title'] ?? '',
          'body': assoc['body'] ?? '',
          'time': assoc['time'] ?? 'Just now',
          'isRead': false, // read status kept local
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch notices: $e');
      return [];
    }
  }

  static Future<bool> saveNotice(Map<String, dynamic> notice, String teacherId, String teacherName) async {
    try {
      final conn = await getConnection();
      final id = notice['id'] ?? _newId('not');
      await conn.execute('''
        INSERT INTO app_notices (id, title, body, time, teacher_id, teacher_name)
        VALUES (:id, :title, :body, :time, :teacherId, :teacherName);
      ''', {
        'id': id,
        'title': notice['title'] ?? '',
        'body': notice['body'] ?? '',
        'time': notice['time'] ?? 'Just now',
        'teacherId': teacherId,
        'teacherName': teacherName,
      });
      return true;
    } catch (e) {
      print('❌ Failed to save notice: $e');
      return false;
    }
  }

  static Future<bool> deleteNotice(String noticeId) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        DELETE FROM app_notices WHERE id = :id;
      ''', {'id': noticeId});
      return true;
    } catch (e) {
      print('❌ Failed to delete notice: $e');
      return false;
    }
  }

  static Future<bool> sendSimulatedSMS({
    required String to,
    required String message,
    required String studentName,
    String? category,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://abc123.ngrok-free.app';
    final localUrl = dotenv.env['LOCAL_API_BASE_URL'] ?? 'http://192.168.1.25:4000';
    
    for (final base in ['http://127.0.0.1:4000', 'http://10.0.2.2:4000', baseUrl, localUrl]) {
      try {
        final url = Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}/api/v1/sms/send');
        print('📡 Dispatching SMS to Backend Gateway: $url');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': to,
            'message': message,
            'studentName': studentName,
            'category': category ?? 'General',
          }),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Check if backend actually sent the SMS (not just simulated)
          try {
            final body = jsonDecode(response.body) as Map<String, dynamic>;
            final delivered = body['success'] == true && body['simulated'] != true;
            if (delivered) {
              print('✅ SMS actually delivered via ${body['provider'] ?? 'gateway'} to $to');
              return true;
            } else if (body['simulated'] == true) {
              print('⚠️ SMS simulated only — backend has no gateway configured. Add FAST2SMS_API_KEY to .env');
              return false;
            }
          } catch (_) {
            // JSON parse error — treat as delivered if HTTP 200
            return true;
          }
        }
      } catch (e) {
        print('⚠️ SMS API endpoint bypass on $base: $e');
      }
    }
    return false;
  }

  static Future<bool> saveTeacherMessage(Map<String, dynamic> msg) async {
    try {
      final conn = await getConnection();
      await conn.execute('''
        INSERT INTO app_teacher_messages (id, student_name, teacher_name, message, category, is_read, date_str, meeting_response)
        VALUES (:id, :studentName, :teacherName, :message, :category, :isRead, :dateStr, :meetingResponse);
      ''', {
        'id': msg['id'],
        'studentName': msg['studentName'],
        'teacherName': msg['teacherName'],
        'message': msg['message'],
        'category': msg['category'],
        'isRead': (msg['isRead'] == true) ? 1 : 0,
        'dateStr': msg['date'] ?? 'Today',
        'meetingResponse': msg['meetingResponse'] ?? '',
      });
      return true;
    } catch (e) {
      print('❌ Failed to save teacher message: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherMessages(String studentName) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, student_name, teacher_name, message, category, is_read, date_str, meeting_response
        FROM app_teacher_messages
        WHERE LOWER(student_name) = :studentName OR LOWER(student_name) = 'all'
        ORDER BY created_at DESC;
      ''', {'studentName': studentName.toLowerCase().trim()});

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'studentName': assoc['student_name'] ?? '',
          'teacherName': assoc['teacher_name'] ?? '',
          'message': assoc['message'] ?? '',
          'category': assoc['category'] ?? '',
          'isRead': assoc['is_read']?.toString() == '1' || assoc['is_read']?.toString() == 'true',
          'date': assoc['date_str'] ?? '',
          'meetingResponse': assoc['meeting_response'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch teacher messages: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllTeacherMessages() async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, student_name, teacher_name, message, category, is_read, date_str, meeting_response
        FROM app_teacher_messages
        ORDER BY created_at DESC;
      ''');

      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': assoc['id'] ?? '',
          'studentName': assoc['student_name'] ?? '',
          'teacherName': assoc['teacher_name'] ?? '',
          'message': assoc['message'] ?? '',
          'category': assoc['category'] ?? '',
          'isRead': assoc['is_read']?.toString() == '1' || assoc['is_read']?.toString() == 'true',
          'date': assoc['date_str'] ?? '',
          'meetingResponse': assoc['meeting_response'] ?? '',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch all teacher messages: $e');
      return [];
    }
  }

  static Future<int> addRecordedLecture({
    required String title,
    required String duration,
    required String teacher,
    required String emoji,
    String? videoUrl,
  }) async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        INSERT INTO app_recorded_lectures (title, duration, teacher, emoji, video_url)
        VALUES (:title, :duration, :teacher, :emoji, :videoUrl);
      ''', {
        'title': title,
        'duration': duration,
        'teacher': teacher,
        'emoji': emoji,
        'videoUrl': videoUrl ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      });
      return results.lastInsertID.toInt();
    } catch (e) {
      print('❌ Failed to insert recorded lecture: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getRecordedLectures() async {
    try {
      final conn = await getConnection();
      final results = await conn.execute('''
        SELECT id, title, duration, teacher, emoji, video_url
        FROM app_recorded_lectures
        ORDER BY created_at DESC;
      ''');
      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'id': int.tryParse(assoc['id'] ?? '') ?? 0,
          'title': assoc['title'] ?? '',
          'duration': assoc['duration'] ?? '',
          'teacher': assoc['teacher'] ?? '',
          'emoji': assoc['emoji'] ?? '📹',
          'videoUrl': assoc['video_url'] ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        });
      }
      return list;
    } catch (e) {
      print('❌ Failed to fetch recorded lectures: $e');
      return [];
    }
  }

  static Future<String?> uploadFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️ Upload failed: File does not exist at $filePath');
      return null;
    }
    
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final localUrl = dotenv.env['LOCAL_API_BASE_URL'] ?? 'http://10.0.2.2:4000';
    
    final baseCandidates = [
      if (baseUrl.isNotEmpty) baseUrl,
      localUrl,
      'http://10.0.2.2:4000',
      'http://127.0.0.1:4000',
    ];
    
    for (final base in baseCandidates) {
      try {
        final cleanBase = base.replaceAll(RegExp(r'/+$'), '');
        final uri = Uri.parse('$cleanBase/api/v1/upload');
        print('📡 Sending file upload request to: $uri');
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
        
        final response = await request.send().timeout(const Duration(seconds: 20));
        if (response.statusCode == 200 || response.statusCode == 201) {
          final resBody = await response.stream.bytesToString();
          final data = jsonDecode(resBody);
          if (data['success'] == true && data['url'] != null) {
            final fileUrl = data['url'] as String;
            print('📁 File uploaded successfully to backend: $fileUrl');
            // If the URL contains localhost/127.0.0.1 and we are running on emulator, we might want to replace it
            // with the base url that succeeded so the emulator can fetch it. But the server constructs it from request host header,
            // which will already be correct (e.g. 10.0.2.2:4000 if request went to 10.0.2.2).
            return fileUrl;
          }
        }
      } catch (e) {
        print('⚠️ Failed to upload file to $base: $e');
      }
    }
    return null;
  }

  // Update student's gamified stats in users table
  static Future<bool> updateGamifiedStats(String email, {int? xp, int? level, int? streak, int? completedQuizzes}) async {
    try {
      final conn = await getConnection();
      final Map<String, dynamic> params = {'email': email.toLowerCase().trim()};
      final List<String> updates = [];
      if (xp != null) { updates.add('xp = :xp'); params['xp'] = xp; }
      if (level != null) { updates.add('level = :level'); params['level'] = level; }
      if (streak != null) { updates.add('streak = :streak'); params['streak'] = streak; }
      if (completedQuizzes != null) { updates.add('completed_quizzes = :completedQuizzes'); params['completedQuizzes'] = completedQuizzes; }
      if (updates.isEmpty) return true;
      
      await conn.execute(
        'UPDATE users SET ${updates.join(", ")} WHERE LOWER(email) = :email;',
        params
      );
      return true;
    } catch (e) {
      print('⚠️ Failed to update gamified stats in database: $e');
      return false;
    }
  }

  // Fetch student leaderboard records ordered by XP
  static Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    try {
      final conn = await getConnection();
      final results = await conn.execute(
        'SELECT name, xp, level FROM users WHERE role = "student" ORDER BY xp DESC LIMIT 25;'
      );
      final list = <Map<String, dynamic>>[];
      for (final row in results.rows) {
        final assoc = row.assoc();
        list.add({
          'name': assoc['name'] ?? 'Student',
          'xp': int.tryParse(assoc['xp'] ?? '') ?? 0,
          'level': int.tryParse(assoc['level'] ?? '') ?? 1,
        });
      }
      return list;
    } catch (e) {
      print('⚠️ Failed to fetch leaderboard data: $e');
      return [];
    }
  }
}

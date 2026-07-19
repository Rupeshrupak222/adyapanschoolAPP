import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified API Service — connects mobile app to the shared backend
/// All authentication flows through this service to ensure password hashing
/// is handled server-side (Argon2id) and credentials work across all platforms.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://preschool-wzjj.onrender.com';

  String? _token;
  String? _refreshToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Dart/Flutter (Adyapan School App)',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Initialize — load saved token from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  /// Save tokens after login
  Future<void> _saveTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('refresh_token', refreshToken);
  }

  /// Clear tokens on logout
  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  bool get isLoggedIn => _token != null;
  String? get token => _token;

  // ─── AUTH ─────────────────────────────────────────────────────────

  /// Login via backend API — returns user map on success, throws on error
  /// The backend handles Argon2id verification so credentials work across
  /// website and mobile app identically.
  /// Automatically handles session conflicts (409) by clearing previous sessions.
  /// For teachers: pass role='teacher' and staffKey. For principals: role='principal' and accessKey.
  Future<Map<String, dynamic>> loginWithDetails(
    String email,
    String password, {
    String? role,
    String? staffKey,
    String? accessKey,
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    final body = <String, dynamic>{
      'email': cleanEmail,
      'password': password,
      'platform': 'mobile',
    };
    if (role != null) body['role'] = role;
    if (staffKey != null) body['staffKey'] = staffKey;
    if (accessKey != null) body['accessKey'] = accessKey;

    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Dart/Flutter (Adyapan School App)',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 90));

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && data['success'] == true) {
      final userData = data['data'] as Map<String, dynamic>;
      await _saveTokens(
        userData['token'] as String,
        userData['refreshToken'] as String,
      );
      return userData['user'] as Map<String, dynamic>;
    }

    // Handle 409: Active session exists on another device
    // Auto-clear previous sessions and retry login
    if (res.statusCode == 409) {
      final cleared = await _clearPreviousSessions(cleanEmail, password);
      if (cleared) {
        // Retry login after clearing sessions
        final retryRes = await http.post(
          Uri.parse('$baseUrl/api/v1/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Dart/Flutter (Adyapan School App)',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));

        final retryData = jsonDecode(retryRes.body) as Map<String, dynamic>;
        if (retryRes.statusCode == 200 && retryData['success'] == true) {
          final userData = retryData['data'] as Map<String, dynamic>;
          await _saveTokens(
            userData['token'] as String,
            userData['refreshToken'] as String,
          );
          return userData['user'] as Map<String, dynamic>;
        }
      }
      // If clearing failed, report the session conflict
      throw AuthException('Session active on another device. Please try again.');
    }

    // Handle other error codes
    final message = data['message'] as String? ?? 'Login failed';
    final statusCode = res.statusCode;

    if (statusCode == 401) {
      throw AuthException('Invalid email or password');
    } else if (statusCode == 423) {
      throw AuthException(message); // Account locked
    } else if (statusCode == 429) {
      throw AuthException('Too many attempts. Please try again later.');
    } else if (statusCode == 403) {
      throw AuthException('Account is not active. Contact admin.');
    } else {
      throw AuthException(message);
    }
  }

  /// Clear previous sessions (used when 409 conflict is returned)
  Future<bool> _clearPreviousSessions(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/clear-previous-sessions'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Dart/Flutter (Adyapan School App)',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('⚠️ Clear sessions failed: $e');
      return false;
    }
  }

  /// Simple login that returns user map or null (backward compat)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      return await loginWithDetails(email, password);
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  /// Register via backend API — password is hashed server-side with Argon2id
  Future<Map<String, dynamic>> registerWithDetails({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? className,
    String? school,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Dart/Flutter (Adyapan School App)',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.toLowerCase().trim(),
        'password': password,
        'phone': phone,
        'class_name': className,
        'school_name': school,
        'platform': 'mobile',
      }),
    ).timeout(const Duration(seconds: 90));

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 201 && data['success'] == true) {
      final userData = data['data'] as Map<String, dynamic>;
      await _saveTokens(
        userData['token'] as String,
        userData['refreshToken'] as String,
      );
      return userData['user'] as Map<String, dynamic>;
    }

    final message = data['message'] as String? ?? 'Registration failed';

    if (res.statusCode == 409) {
      throw AuthException('User with this email already exists');
    } else if (res.statusCode == 400) {
      throw AuthException(message);
    } else {
      throw AuthException(message);
    }
  }

  /// Simple register that returns user map or null (backward compat)
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? className,
    String? school,
  }) async {
    try {
      return await registerWithDetails(
        name: name,
        email: email,
        password: password,
        phone: phone,
        className: className,
        school: school,
      );
    } catch (e) {
      print('❌ Register error: $e');
      return null;
    }
  }

  /// Change password via authenticated API call
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final res = await _postRaw('/api/v1/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return res != null && res.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getMe() async {
    return await _get('/api/v1/auth/me');
  }

  Future<void> logout() async {
    try {
      await _post('/api/v1/auth/logout', {});
    } catch (_) {}
    await clearTokens();
  }

  // ─── PROFILE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    return await _get('/api/v1/profile');
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> data) async {
    return await _put('/api/v1/profile', data);
  }

  // ─── DASHBOARD ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDashboard() async {
    return await _get('/api/v1/dashboard');
  }

  // ─── ATTENDANCE ───────────────────────────────────────────────────

  Future<List<dynamic>> getAttendance({int page = 1, int limit = 50}) async {
    final data = await _get('/api/v1/attendance?page=$page&limit=$limit');
    return data?['data'] ?? [];
  }

  Future<Map<String, dynamic>?> getAttendanceSummary(String userId) async {
    return await _get('/api/v1/attendance/summary/$userId');
  }

  // ─── CLASSES (Live + Scheduled) ───────────────────────────────────

  Future<List<dynamic>> getClasses({int page = 1, int limit = 20}) async {
    final data = await _get('/api/v1/classes?page=$page&limit=$limit');
    return data?['data'] ?? [];
  }

  // ─── NOTICES / NOTIFICATIONS ──────────────────────────────────────

  Future<List<dynamic>> getNotices({int page = 1, int limit = 20}) async {
    final data = await _get('/api/v1/notices?page=$page&limit=$limit');
    return data?['data'] ?? [];
  }

  Future<void> markNoticeRead(String id) async {
    await _put('/api/v1/notices/$id/read', {});
  }

  // ─── PAYMENTS ─────────────────────────────────────────────────────

  Future<List<dynamic>> getPayments({int page = 1, int limit = 20}) async {
    final data = await _get('/api/v1/payments?page=$page&limit=$limit');
    return data?['data'] ?? [];
  }

  // ─── STUDENTS ─────────────────────────────────────────────────────

  Future<List<dynamic>> getStudents({String? schoolId}) async {
    final query = schoolId != null ? '?schoolId=$schoolId' : '';
    final res = await _getRaw('/api/v1/students$query');
    if (res != null) return res is List ? res : [];
    return [];
  }

  // ─── TEACHERS ─────────────────────────────────────────────────────

  Future<List<dynamic>> getTeachers({String? schoolId}) async {
    final query = schoolId != null ? '?schoolId=$schoolId' : '';
    final res = await _getRaw('/api/v1/teachers$query');
    if (res != null) return res is List ? res : [];
    return [];
  }

  // ─── SCHOOLS ──────────────────────────────────────────────────────

  Future<List<dynamic>> getSchools() async {
    final res = await _getRaw('/api/v1/schools');
    if (res != null) return res is List ? res : [];
    return [];
  }

  // ─── LEADS ────────────────────────────────────────────────────────

  Future<bool> submitLead(Map<String, dynamic> data) async {
    final res = await _post('/api/v1/leads', data);
    return res != null;
  }

  // ─── MESSAGING (Admin ↔ Principal ↔ Teacher ↔ Student) ───────────

  /// Fetch messages for the currently logged-in user
  Future<List<Map<String, dynamic>>> fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/messages'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return fetchMessages();
        return [];
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] != null && data['data']['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['data']['messages']);
        }
        if (data is Map && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('❌ fetchMessages error: $e');
    }
    return [];
  }

  /// Fetch messages for a specific student (by email)
  Future<List<Map<String, dynamic>>> fetchStudentMessages(String email) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/messages/student?email=${Uri.encodeComponent(email)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return fetchStudentMessages(email);
        return [];
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] != null && data['data']['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['data']['messages']);
        }
        if (data is Map && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('❌ fetchStudentMessages error: $e');
    }
    return [];
  }

  /// Send a message (teacher → admin/principal/student, principal → admin/teacher)
  Future<bool> sendMessage({
    required String recipientEmail,
    required String recipientRole,
    required String message,
    String? senderName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/messages'),
        headers: _headers,
        body: jsonEncode({
          'recipient_email': recipientEmail,
          'recipient_role': recipientRole,
          'message': message,
          'sender_name': senderName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return sendMessage(
            recipientEmail: recipientEmail,
            recipientRole: recipientRole,
            message: message,
            senderName: senderName,
          );
        }
        return false;
      }

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('❌ sendMessage error: $e');
      return false;
    }
  }

  /// Mark a message as read
  Future<void> markMessageRead(String messageId) async {
    try {
      await _put('/api/v1/messages/$messageId/read', {});
    } catch (e) {
      print('❌ markMessageRead error: $e');
    }
  }

  // ─── PRIVATE HELPERS ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return _get(path);
        return null;
      }

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('❌ GET $path error: $e');
      return null;
    }
  }

  Future<dynamic> _getRaw(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return _getRaw(path);
        return null;
      }

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('❌ GET $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return _post(path, body);
        return null;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('❌ POST $path error: $e');
      return null;
    }
  }

  Future<http.Response?> _postRaw(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return _postRaw(path, body);
        return null;
      }

      return res;
    } catch (e) {
      print('❌ POST $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) return _put(path, body);
        return null;
      }

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('❌ PUT $path error: $e');
      return null;
    }
  }

  /// Auto-refresh expired access token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final responseData = data['data'] ?? data;
        _token = responseData['token'] ?? responseData['accessToken'];
        _refreshToken = responseData['refreshToken'] ?? _refreshToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        if (_refreshToken != null) {
          await prefs.setString('refresh_token', _refreshToken!);
        }
        return true;
      }
    } catch (e) {
      print('❌ Token refresh failed: $e');
    }

    // Refresh failed — force logout
    await clearTokens();
    return false;
  }

  /// Upload a file (avatar image) to the server
  /// Returns the file URL on success, null on failure
  Future<String?> uploadFile(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedRes = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamedRes);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['file'] != null && data['file']['url'] != null) {
          return data['file']['url'] as String;
        }
      }
    } catch (e) {
      print('❌ Upload file error: $e');
    }
    return null;
  }

  /// Update student avatar URL on the server
  Future<bool> updateAvatar(String avatarUrl) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/profile/avatar'),
        headers: _headers,
        body: jsonEncode({'avatarUrl': avatarUrl}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      print('❌ Update avatar error: $e');
      return false;
    }
  }
}

/// Custom exception for authentication errors with user-friendly messages
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

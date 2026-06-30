import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/db_helper.dart';
import 'app_layout.dart';
import 'teacher_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _teacherKeyController = TextEditingController();
  String _selectedClass = 'Class 1';
  bool _obscurePassword = true;
  bool _obscureKey = true;
  bool _saveCredentials = false;
  DateTime? _lastBackPressed;
  late AnimationController _animationController;
  String _userRole = 'student'; // 'student' or 'teacher'
  bool _isLoading = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await _getPrefs();
    // Load role-specific saved email
    final roleKey = _userRole == 'teacher' ? 'teacher_saved_email' : 'student_saved_email';
    final savedEmail = prefs.getString(roleKey) ?? '';
    final saved = prefs.getBool('save_credentials_$_userRole') ?? false;
    if (saved && savedEmail.isNotEmpty) {
      setState(() {
        _saveCredentials = true;
        _emailController.text = savedEmail;
      });
    } else {
      setState(() {
        _saveCredentials = false;
        _emailController.clear();
      });
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _passwordController.dispose();
    _teacherIdController.dispose();
    _teacherKeyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isLoading) return;
    final state = Provider.of<AppState>(context, listen: false);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final teacherKey = _teacherKeyController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Please fill in both email and password.', style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      return;
    }

    // Teacher key validation (always required for teacher role)
    if (_userRole == 'teacher') {
      if (teacherKey.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Please enter the Access Key.', style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // Save credentials role-specifically
    final roleKey = _userRole == 'teacher' ? 'teacher_saved_email' : 'student_saved_email';
    if (_saveCredentials) {
      final prefs = await _getPrefs();
      await prefs.setString(roleKey, email);
      await prefs.setBool('save_credentials_$_userRole', true);
    } else {
      final prefs = await _getPrefs();
      await prefs.remove(roleKey);
      await prefs.setBool('save_credentials_$_userRole', false);
    }

    // For teacher with valid key: must verify password against database
    if (_userRole == 'teacher') {
      bool dbSuccess = false;
      String errorMsg = '';
      try {
        dbSuccess = await state.loginUser(email, password, role: 'teacher', staffKey: teacherKey);
      } catch (e) {
        dbSuccess = false;
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!dbSuccess) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg.isNotEmpty ? '❌ $errorMsg' : '❌ Invalid email or password.',
              style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text('Welcome Educator! Login successful.',
              style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
          ]),
          backgroundColor: AdyapanTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()));
      return;
    }

    // Student login — must verify against database
    bool loginSuccess = false;
    String errorMsg = '';
    try {
      loginSuccess = await state.loginUser(email, password);
    } catch (e) {
      loginSuccess = false;
      errorMsg = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (loginSuccess) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Welcome back Student! Login successful.',
                  style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AdyapanTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const AppLayout()));
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg.isNotEmpty ? '❌ $errorMsg' : '❌ Invalid Email or Password.',
            style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  void _handleGoogleLogin() async {
    // Google Sign-In is not yet integrated.
    // Show a message to use email/password login instead.
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Google Sign-In coming soon. Please use email & password.',
          style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  void _handleForgotPassword() {
    final emailResetController = TextEditingController(text: _emailController.text);
    final passwordResetController = TextEditingController();
    final confirmPasswordResetController = TextEditingController();
    bool obscureResetPassword = true;
    bool obscureResetConfirmPassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'Reset Password 🔑',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your registered email and a new password to reset it.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    Text(
                      'Email Address',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildModalField(
                      controller: emailResetController,
                      hint: 'your.email@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // New Password Field
                    Text(
                      'New Password',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildModalField(
                      controller: passwordResetController,
                      hint: 'New password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscureResetPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureResetPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF64748B),
                          size: 18,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureResetPassword = !obscureResetPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm New Password Field
                    Text(
                      'Confirm New Password',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildModalField(
                      controller: confirmPasswordResetController,
                      hint: 'Confirm password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscureResetConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureResetConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF64748B),
                          size: 18,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureResetConfirmPassword = !obscureResetConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final email = emailResetController.text.trim().toLowerCase();
                              final pass = passwordResetController.text;
                              final confirmPass = confirmPasswordResetController.text;

                              if (email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('⚠️ Please fill in all fields.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.orange[800],
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              if (pass != confirmPass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('⚠️ Passwords do not match.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final state = Provider.of<AppState>(context, listen: false);
                              try {
                                final success = await state.resetPassword(email, pass);
                                if (success) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🎉 Password updated successfully! Try logging in.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                        backgroundColor: AdyapanTheme.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('❌ Email not found in our database.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Reset failed: $e', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                      backgroundColor: Colors.red[900],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _userRole == 'student' 
                                      ? [const Color(0xFF2563EB), const Color(0xFF3B82F6)]
                                      : [const Color(0xFFFF3B70), const Color(0xFFFF5D7E)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Reset',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final state = Provider.of<AppState>(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: state.translate(hint),
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return WillPopScope(
          onWillPop: () async {
            final now = DateTime.now();
            if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
              _lastBackPressed = now;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Press back again to exit', style: AdyapanTheme.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: const Color(0xFF1E293B),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              return false;
            }
            return true;
          },
          child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFFFFDF8),
          body: Stack(
        children: [
          // 1. HIGH-FIDELITY GRADIENTS & WAVY BACKGROUND PAINTER
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundDoodlesPainter(
                airplaneAnimValue: _animationController.value,
              ),
            ),
          ),

          // 2. MAIN SCROLLABLE CONTENT BODY
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Bouncily scrolls up and down!
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // Top Brand Header Logo Widget
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Real App Icon logo
                        Image.asset(
                          'assets/images/app_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        // Title Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adyapan',
                              style: GoogleFonts.fredoka(
                                fontSize: 28, 
                                fontWeight: FontWeight.bold, 
                                color: const Color(0xFF1B2A4A),
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              'SCHOOL',
                              style: GoogleFonts.outfit(
                                fontSize: 10, 
                                fontWeight: FontWeight.w900, 
                                color: const Color(0xFF3B82F6),
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 28),

                    // CENTRAL PREMIUM GLASS CARD
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withOpacity(0.06),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Glow gradient padlock container box
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, math.sin(_animationController.value * math.pi * 2) * 2),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFECF3FF),
                                    const Color(0xFFFCEEFA),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFD946EF), width: 2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD946EF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Custom Painted Lock icon inside container
                          const SizedBox(height: 16),
                          Text(
                            'Welcome back',
                            style: GoogleFonts.fredoka(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: const Color(0xFF1B2A4A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userRole == 'student'
                                ? 'Continue learning with your future skills dashboard.'
                                : 'Manage your students, assignments, and class standings.',
                            style: GoogleFonts.outfit(
                              fontSize: 12, 
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // ROLE SELECTOR TOGGLE (Student vs Teacher)
                          Container(
                            height: 40,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _userRole = 'student';
                                        // Clear all fields when switching role
                                        _emailController.clear();
                                        _passwordController.clear();
                                        _nameController.clear();
                                        _phoneController.clear();
                                        _schoolController.clear();
                                        _teacherKeyController.clear();
                                        _teacherIdController.clear();
                                        _saveCredentials = false;
                                      });
                                      // Load student-specific saved email
                                      _loadSavedCredentials();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _userRole == 'student' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _userRole == 'student'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${state.translate('Student')} 🎓',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _userRole == 'student' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _userRole = 'teacher';
                                        // Clear all fields when switching role
                                        _emailController.clear();
                                        _passwordController.clear();
                                        _nameController.clear();
                                        _phoneController.clear();
                                        _schoolController.clear();
                                        _teacherKeyController.clear();
                                        _teacherIdController.clear();
                                        _saveCredentials = false;
                                      });
                                      // Load teacher-specific saved email
                                      _loadSavedCredentials();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _userRole == 'teacher' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _userRole == 'teacher'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${state.translate('Teacher')} 🏫',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _userRole == 'teacher' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                                  // Form fields with layout switching based on role
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                _userRole == 'student' ? 'Student Email / ID' : 'Teacher Email / ID',
                                style: GoogleFonts.outfit(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.bold, 
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          _buildField(
                            controller: _emailController,
                            hint: _userRole == 'student' ? 'student@example.com' : 'teacher@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),

                          // PASSWORD input field (Common for both)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                'Password',
                                style: GoogleFonts.outfit(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.bold, 
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          _buildField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: const Color(0xFF64748B),
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4, top: 4),
                              child: GestureDetector(
                                onTap: _handleForgotPassword,
                                child: Text(
                                  state.translate('Forgot Password?'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _userRole == 'student' ? const Color(0xFF2563EB) : const Color(0xFFFF3B70),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ACCESS KEY field (Teacher only)
                          if (_userRole == 'teacher') ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'Access Key',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            _buildField(
                              controller: _teacherKeyController,
                              hint: 'Enter school access key',
                              icon: Icons.vpn_key_outlined,
                              obscureText: _obscureKey,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureKey = !_obscureKey;
                                  });
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // SAVE CREDENTIALS CHECKBOX
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _saveCredentials,
                                  onChanged: (val) {
                                    setState(() {
                                      _saveCredentials = val ?? false;
                                    });
                                  },
                                  activeColor: _userRole == 'student'
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFFF3B70),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Save email for next login',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // LOGIN GRADIENT BUTTON (Blue to Pink/Magenta)
                          AnimatedScale(
                            scale: _isLoading ? 0.98 : (_isPressed ? 0.95 : 1.0),
                            duration: const Duration(milliseconds: 100),
                            child: GestureDetector(
                              onTapDown: (_) {
                                if (!_isLoading) {
                                  setState(() => _isPressed = true);
                                }
                              },
                              onTapUp: (_) {
                                if (!_isLoading) {
                                  setState(() => _isPressed = false);
                                }
                              },
                              onTapCancel: () {
                                if (!_isLoading) {
                                  setState(() => _isPressed = false);
                                }
                              },
                              onTap: _isLoading ? null : _handleLogin,
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB), // Vibrant blue
                                      Color(0xFFEC4899), // Hot pink
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        state.translate('Log In'),
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold, 
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Sign up page has been removed as per administration guidelines.
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // MAGIC WAND SPARKLE FLOATING BUTTON IN BOTTOM RIGHT
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {
                // Instantly trigger a fun lofi custom toast!
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Premium Focus Mode active. Get ready to learn like a superhero!',
                            style: GoogleFonts.fredoka(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1B2A4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )
                );
              },
              backgroundColor: const Color(0xFF475569).withOpacity(0.85),
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
        ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final state = Provider.of<AppState>(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Ultra-premium soft slate background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enableSuggestions: false, // <-- Disable Gboard suggestions to fix backspace deleting issues!
        autocorrect: false, // <-- Disable autocorrect to let user delete exactly 1 character at a time!
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: state.translate(hint),
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _userRole == 'student' ? const Color(0xFF3B82F6) : const Color(0xFFFF3B70), width: 1.8), // Dynamic primary color!
          ),
        ),
      ),
    );
  }

  // Gorgeous 3D Cartoon Desk Illustration: Books, Succulent, Backpack with ady circular logo, and Globe on loop stand
  Widget _buildLowerDeskDecoration() {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Floor base shadow/floor wavy line
          Positioned(
            bottom: -20,
            left: -20,
            right: -20,
            child: SizedBox(
              height: 60,
              child: CustomPaint(
                painter: WavyFloorPainter(),
              ),
            ),
          ),

          // 1. Stacked Books (Left)
          Positioned(
            left: 10,
            bottom: 0,
            child: CustomPaint(
              size: const Size(90, 50),
              painter: BooksStackPainter(),
            ),
          ),

          // 2. Green Succulent plant (resting on top of books)
          Positioned(
            left: 32,
            bottom: 45,
            child: CustomPaint(
              size: const Size(40, 45),
              painter: SucculentPlantPainter(),
            ),
          ),

          // 3. Yellow and Blue School Backpack (Center)
          Positioned(
            bottom: -8,
            child: CustomPaint(
              size: const Size(120, 130),
              painter: BackpackPainter(),
            ),
          ),

          // 4. Globe on Golden loop Stand (Right)
          Positioned(
            right: 12,
            bottom: 0,
            child: CustomPaint(
              size: const Size(80, 85),
              painter: GlobeStandPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// CUSTOM PAINTERS & DRAWING CODE
// ----------------------------------------------------

class BackgroundDoodlesPainter extends CustomPainter {
  final double airplaneAnimValue;
  BackgroundDoodlesPainter({required this.airplaneAnimValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // A. CORNER GRADIENT ORGANIC BLOBS
    // 1. Top-Left Blob (Soft Lavender/Purple wave)
    paint.shader = const LinearGradient(
      colors: [Color(0xFFE2D6FF), Color(0xFFF1EAFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width * 0.45, size.height * 0.25));
    final pathTL = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.45, 0)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.08, size.width * 0.25, size.height * 0.12)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.16, 0, size.height * 0.22)
      ..close();
    canvas.drawPath(pathTL, paint);

    // 2. Top-Right Blob (Pink/Peach wave)
    paint.shader = const LinearGradient(
      colors: [Color(0xFFFDE8E2), Color(0xFFFFF0EC)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ).createShader(Rect.fromLTWH(size.width * 0.55, 0, size.width * 0.45, size.height * 0.2));
    final pathTR = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.55, 0)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.06, size.width * 0.75, size.height * 0.09)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.12, size.width, size.height * 0.18)
      ..close();
    canvas.drawPath(pathTR, paint);

    // 3. Bottom-Left Blob (Lavender purple wave)
    paint.shader = const LinearGradient(
      colors: [Color(0xFFEFE8FF), Color(0xFFF5EFFF)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width * 0.35, size.height * 0.2));
    final pathBL = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.08, size.height * 0.88, size.width * 0.15, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.92, size.width * 0.3, size.height)
      ..close();
    canvas.drawPath(pathBL, paint);

    // 4. Bottom-Right Blob (Peach pink wave)
    paint.shader = const LinearGradient(
      colors: [Color(0xFFFDE2EC), Color(0xFFFFF0F5)],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).createShader(Rect.fromLTWH(size.width * 0.65, size.height * 0.8, size.width * 0.35, size.height * 0.2));
    final pathBR = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.88, size.width * 0.85, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.94, size.width * 0.68, size.height)
      ..close();
    canvas.drawPath(pathBR, paint);

    // B. FLOATING DOODLES & PATH LINES
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // 1. Dash-trail and flying paper airplane in Top Right area
    strokePaint.color = Colors.purple.withOpacity(0.35);
    final airplaneTrail = Path()
      ..moveTo(size.width * 0.9, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.82, size.height * 0.1,
        size.width * 0.75, size.height * 0.14,
      )
      ..quadraticBezierTo(
        size.width * 0.66, size.height * 0.18,
        size.width * 0.65, size.height * 0.08,
      );
    // Draw dashed line
    _drawDashedPath(canvas, airplaneTrail, strokePaint);

    // Draw the folded paper airplane
    final planeCenter = Offset(
      size.width * 0.65 + math.sin(airplaneAnimValue * 0.1) * 10,
      size.height * 0.08 + math.cos(airplaneAnimValue * 0.1) * 8,
    );
    final airplanePaint = Paint()
      ..color = const Color(0xFFD946EF).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final airplanePath = Path()
      ..moveTo(planeCenter.dx, planeCenter.dy)
      ..lineTo(planeCenter.dx + 25, planeCenter.dy - 10)
      ..lineTo(planeCenter.dx + 12, planeCenter.dy + 15)
      ..close()
      ..moveTo(planeCenter.dx + 12, planeCenter.dy + 15)
      ..lineTo(planeCenter.dx + 7, planeCenter.dy + 5)
      ..lineTo(planeCenter.dx, planeCenter.dy);
    canvas.drawPath(airplanePath, airplanePaint);

    // 2. Yellow outlines of scattered stars
    final starPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFFFB000).withOpacity(0.7);

    _drawStarDoodle(canvas, Offset(size.width * 0.2, size.height * 0.12), 12, starPaint);
    _drawStarDoodle(canvas, Offset(size.width * 0.1, size.height * 0.48), 10, starPaint);
    _drawStarDoodle(canvas, Offset(size.width * 0.9, size.height * 0.48), 9, starPaint);
    _drawStarDoodle(canvas, Offset(size.width * 0.62, size.height * 0.72), 11, starPaint);

    // 3. Hand-drawn blue pencil/pen (Left margin)
    final pencilPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF3B82F6).withOpacity(0.7);
    final pencilPath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.24)
      ..lineTo(size.width * 0.08, size.height * 0.29)
      ..lineTo(size.width * 0.09, size.height * 0.3)
      ..lineTo(size.width * 0.13, size.height * 0.25)
      ..close()
      // Tip
      ..moveTo(size.width * 0.08, size.height * 0.29)
      ..lineTo(size.width * 0.06, size.height * 0.3) // Pointy lead
      ..lineTo(size.width * 0.09, size.height * 0.3)
      // Pencil cap stripes
      ..moveTo(size.width * 0.11, size.height * 0.255)
      ..lineTo(size.width * 0.075, size.height * 0.295);
    canvas.drawPath(pencilPath, pencilPaint);

    // 5. Glowing lightbulb (Right margin)
    final bulbPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFFFB000).withOpacity(0.85);
    final bulbPath = Path()
      ..moveTo(size.width * 0.92, size.height * 0.18)
      ..cubicTo(size.width * 0.88, size.height * 0.16, size.width * 0.86, size.height * 0.2, size.width * 0.89, size.height * 0.22)
      ..lineTo(size.width * 0.89, size.height * 0.24)
      ..lineTo(size.width * 0.93, size.height * 0.24)
      ..lineTo(size.width * 0.93, size.height * 0.22)
      ..cubicTo(size.width * 0.96, size.height * 0.2, size.width * 0.95, size.height * 0.16, size.width * 0.92, size.height * 0.18)
      // Screw threads base
      ..moveTo(size.width * 0.89, size.height * 0.24)
      ..lineTo(size.width * 0.91, size.height * 0.25)
      ..lineTo(size.width * 0.93, size.height * 0.24);
    canvas.drawPath(bulbPath, bulbPaint);
    // Draw lofi rays
    canvas.drawLine(Offset(size.width * 0.91, size.height * 0.15), Offset(size.width * 0.91, size.height * 0.13), bulbPaint);
    canvas.drawLine(Offset(size.width * 0.85, size.height * 0.18), Offset(size.width * 0.83, size.height * 0.17), bulbPaint);
    canvas.drawLine(Offset(size.width * 0.97, size.height * 0.18), Offset(size.width * 0.99, size.height * 0.17), bulbPaint);

    // 6. Circled "A+" grade mark (Right margin)
    final gradePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFEF4444).withOpacity(0.7);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.35), 14, gradePaint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'A+',
        style: GoogleFonts.fredoka(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFEF4444).withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width * 0.88 - 8, size.height * 0.35 - 8));

    // 7. Blue/Purple Atom Orbital (Right margin)
    final atomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF3B82F6).withOpacity(0.6);
    canvas.save();
    canvas.translate(size.width * 0.88, size.height * 0.46);
    // Draw 3 ellipses rotated
    for (int i = 0; i < 3; i++) {
      canvas.rotate(math.pi / 3);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 32, height: 10), atomPaint);
    }
    // Nucleus
    atomPaint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 3, atomPaint);
    canvas.restore();

    // 8. Golden Music Note (Right margin)
    final notePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFEAB308).withOpacity(0.7);
    final notePath = Path()
      ..moveTo(size.width * 0.88, size.height * 0.56)
      ..lineTo(size.width * 0.91, size.height * 0.54)
      ..lineTo(size.width * 0.91, size.height * 0.6)
      ..moveTo(size.width * 0.88, size.height * 0.56)
      ..lineTo(size.width * 0.88, size.height * 0.62);
    canvas.drawPath(notePath, notePaint);
    // Draw note heads
    notePaint.style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(size.width * 0.85, size.height * 0.61, 7, 5), notePaint);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.88, size.height * 0.59, 7, 5), notePaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  void _drawStarDoodle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const spikes = 5;
    double rot = math.pi / 2 * 3;
    final double step = math.pi / spikes;
    final innerRadius = radius * 0.45;

    path.moveTo(center.dx, center.dy - radius);
    for (int i = 0; i < spikes; i++) {
      double x = center.dx + math.cos(rot) * radius;
      double y = center.dy + math.sin(rot) * radius;
      path.lineTo(x, y);
      rot += step;

      x = center.dx + math.cos(rot) * innerRadius;
      y = center.dy + math.sin(rot) * innerRadius;
      path.lineTo(x, y);
      rot += step;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ----------------------------------------------------
// FLOOR AND DESK ELEMENT PAINTERS
// ----------------------------------------------------

class WavyFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF0EC), Color(0xFFFBE6F3)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.45)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BooksStackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1B2A4A).withOpacity(0.3)
      ..strokeWidth = 1.2;

    // 1. Bottom Pink/Red Book
    fillPaint.color = const Color(0xFFFF527B); // Vibrant pinkish red
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height - 20, size.width * 0.95, 18), const Radius.circular(3)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height - 20, size.width * 0.95, 18), const Radius.circular(3)), strokePaint);
    // Draw white pages side block
    fillPaint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.8, size.height - 18, size.width * 0.12, 14), fillPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.8, size.height - 18, size.width * 0.12, 14), strokePaint);

    // 2. Top Blue Book
    fillPaint.color = const Color(0xFF3B82F6); // Soft blue book
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height - 35, size.width * 0.82, 16), const Radius.circular(3)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height - 35, size.width * 0.82, 16), const Radius.circular(3)), strokePaint);
    // Draw white pages
    fillPaint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.76, size.height - 33, size.width * 0.1, 12), fillPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.76, size.height - 33, size.width * 0.1, 12), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SucculentPlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1B2A4A).withOpacity(0.3)
      ..strokeWidth = 1.0;

    // 1. Purple lavender Pot
    fillPaint.color = const Color(0xFFD8B4FE); // Soft pastel purple
    final potPath = Path()
      ..moveTo(size.width * 0.25, size.height)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.82, size.height * 0.6)
      ..lineTo(size.width * 0.18, size.height * 0.6)
      ..close();
    canvas.drawPath(potPath, fillPaint);
    canvas.drawPath(potPath, strokePaint);

    // 2. Green leaves
    fillPaint.color = const Color(0xFF10B981); // Bright green leaves
    // Central leaf
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.38), width: 14, height: 26), fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.38), width: 14, height: 26), strokePaint);
    // Left leaf tilted
    canvas.save();
    canvas.translate(size.width * 0.36, size.height * 0.42);
    canvas.rotate(-math.pi / 5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 22), fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 22), strokePaint);
    canvas.restore();
    // Right leaf tilted
    canvas.save();
    canvas.translate(size.width * 0.64, size.height * 0.42);
    canvas.rotate(math.pi / 5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 22), fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 22), strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BackpackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1B2A4A).withOpacity(0.3)
      ..strokeWidth = 1.5;

    // 0. Stationary item peaks (Ruler & Pencils sticking out from back)
    fillPaint.color = const Color(0xFFC084FC); // Purple ruler
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, 5, 10, 50), fillPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, 5, 10, 50), strokePaint);
    fillPaint.color = const Color(0xFFFACC15); // Yellow pencil
    canvas.save();
    canvas.translate(size.width * 0.35, 12);
    canvas.rotate(-math.pi / 12);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 40), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 40), strokePaint);
    canvas.restore();

    // 1. Handle Strap Loop (Top yellow strap)
    fillPaint.color = const Color(0xFFFFC000);
    final strapPath = Path()
      ..moveTo(size.width * 0.42, 28)
      ..quadraticBezierTo(size.width * 0.5, 12, size.width * 0.58, 28)
      ..quadraticBezierTo(size.width * 0.5, 20, size.width * 0.42, 28);
    canvas.drawPath(strapPath, fillPaint);
    canvas.drawPath(strapPath, strokePaint);

    // 2. Main Blue Backpack Body
    fillPaint.color = const Color(0xFF1B3A4B); // Deep ocean blue
    final mainBody = Path()
      ..moveTo(size.width * 0.2, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.16, size.height * 0.28, size.width * 0.5, size.height * 0.24)
      ..quadraticBezierTo(size.width * 0.84, size.height * 0.28, size.width * 0.8, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.94, size.width * 0.5, size.height * 0.94)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.94, size.width * 0.2, size.height * 0.88)
      ..close();
    canvas.drawPath(mainBody, fillPaint);
    canvas.drawPath(mainBody, strokePaint);

    // 3. Golden Yellow Outer Pocket
    fillPaint.color = const Color(0xFFFFC000); // Golden yellow
    final outerPocket = Path()
      ..moveTo(size.width * 0.26, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.24, size.height * 0.54, size.width * 0.5, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.76, size.height * 0.54, size.width * 0.74, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.92, size.width * 0.5, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.92, size.width * 0.26, size.height * 0.86)
      ..close();
    canvas.drawPath(outerPocket, fillPaint);
    canvas.drawPath(outerPocket, strokePaint);

    // 4. Circular Yellow Badge on Pocket with "ady."
    fillPaint.color = const Color(0xFFFFFBEB); // Creamy white circle
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.72), 16, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.72), 16, strokePaint);
    final badgeText = TextPainter(
      text: TextSpan(
        text: 'ady.',
        style: GoogleFonts.fredoka(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1B3A4B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    badgeText.paint(canvas, Offset(size.width * 0.5 - 8, size.height * 0.72 - 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlobeStandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1B2A4A).withOpacity(0.3)
      ..strokeWidth = 1.5;

    // 1. Golden curved stand loop arc
    strokePaint.color = const Color(0xFFFFB000); // Golden stand
    strokePaint.strokeWidth = 3.5;
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.1, size.width * 0.84, size.height * 0.75),
      math.pi * 0.15,
      math.pi * 1.05,
      false,
      strokePaint,
    );
    // Reset stroke paint properties
    strokePaint.color = const Color(0xFF1B2A4A).withOpacity(0.3);
    strokePaint.strokeWidth = 1.2;

    // 2. Golden Loop Stand base
    fillPaint.color = const Color(0xFFFFB000);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.25, size.height - 10, size.width * 0.5, 8), const Radius.circular(4)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.25, size.height - 10, size.width * 0.5, 8), const Radius.circular(4)), strokePaint);
    // Vertical neck joint
    canvas.drawRect(Rect.fromLTWH(size.width * 0.46, size.height * 0.72, size.width * 0.08, size.height * 0.2), fillPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.46, size.height * 0.72, size.width * 0.08, size.height * 0.2), strokePaint);

    // 3. Globe Sphere (Deep blue ocean)
    fillPaint.color = const Color(0xFF3B82F6); // Ocean blue
    final globeCenter = Offset(size.width * 0.5, size.height * 0.44);
    canvas.drawCircle(globeCenter, 24, fillPaint);
    canvas.drawCircle(globeCenter, 24, strokePaint);

    // 4. Green continents overlay inside circle boundary
    fillPaint.color = const Color(0xFF10B981); // Emerald Green continents
    canvas.save();
    // Clip path to only draw continents inside sphere
    final clipPath = Path()..addOval(Rect.fromCircle(center: globeCenter, radius: 24));
    canvas.clipPath(clipPath);
    // Draw simple geometric shapes representing continents
    final continentPath = Path()
      ..moveTo(globeCenter.dx - 18, globeCenter.dy - 6)
      ..quadraticBezierTo(globeCenter.dx - 10, globeCenter.dy - 12, globeCenter.dx - 5, globeCenter.dy - 8)
      ..quadraticBezierTo(globeCenter.dx, globeCenter.dy - 2, globeCenter.dx - 12, globeCenter.dy + 8)
      ..close()
      ..moveTo(globeCenter.dx + 4, globeCenter.dy - 16)
      ..quadraticBezierTo(globeCenter.dx + 16, globeCenter.dy - 10, globeCenter.dx + 12, globeCenter.dy + 2)
      ..quadraticBezierTo(globeCenter.dx + 2, globeCenter.dy + 6, globeCenter.dx + 4, globeCenter.dy - 16)
      ..close()
      ..moveTo(globeCenter.dx - 4, globeCenter.dy + 10)
      ..addOval(Rect.fromLTWH(globeCenter.dx - 4, globeCenter.dy + 8, 12, 8));
    canvas.drawPath(continentPath, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter to draw the official Google multicoloured icon cleanly
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final r = size.width / 2;

    // 1. Red portion (top arc)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(r, r)
      ..lineTo(r - r * 0.707, r - r * 0.707)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height), -math.pi * 0.75, math.pi * 0.5, false)
      ..close();
    canvas.drawPath(redPath, paint);

    // 2. Yellow portion (left arc)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(r, r)
      ..lineTo(r - r * 0.707, r + r * 0.707)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height), -math.pi * 1.25, math.pi * 0.5, false)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 3. Green portion (bottom arc)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(r, r)
      ..lineTo(r + r * 0.707, r + r * 0.707)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height), -math.pi * 1.75, math.pi * 0.5, false)
      ..close();
    canvas.drawPath(greenPath, paint);

    // 4. Blue portion (right arc + horizontal bar)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(r, r)
      ..lineTo(r, r - r * 0.3)
      ..lineTo(size.width, r - r * 0.3)
      ..lineTo(size.width, r)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height), 0, math.pi * 0.25, false)
      ..lineTo(r, r)
      ..close();
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

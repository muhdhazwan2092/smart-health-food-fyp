import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../themes/app_theme.dart';
import '../main.dart' show MainApp;

// ---------------------------------------------------------------------------
// Login Page
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true;

  /// Turns a raw auth exception into a friendly message, and tells the
  /// caller whether a "resend confirmation email" action should be offered.
  ({String message, bool showResend}) _describeAuthError(Object e) {
    if (e is AuthException) {
      final code = e.code;
      final msg = e.message.toLowerCase();

      if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
        return (
          message:
              'Please confirm your email before logging in. Check your inbox for the verification link.',
          showResend: true,
        );
      }
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials')) {
        return (
          message: 'Incorrect email or password. Please try again.',
          showResend: false,
        );
      }
      if (code == 'user_already_exists' || msg.contains('already registered')) {
        return (
          message:
              'An account with this email already exists. Try logging in instead.',
          showResend: false,
        );
      }
      if (code == 'weak_password' || msg.contains('password')) {
        return (
          message: 'Password is too weak. Use at least 6 characters.',
          showResend: false,
        );
      }
      return (message: e.message, showResend: false);
    }
    return (
      message: 'Something went wrong. Please try again.',
      showResend: false
    );
  }

  Future<void> _resendConfirmationEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (mounted) {
        _showSnack('Confirmation email resent. Please check your inbox.',
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Could not resend email. Please try again shortly.',
            isError: true);
      }
    }
  }

  void _showSnack(String message,
      {required bool isError, SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFC0453A) : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: tagRadius(r: 14, sharp: 6)),
        action: action,
      ),
    );
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        // Login
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Sign Up
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          _showSnack(
            'Account created! Please check your email for verification.',
            isError: false,
          );
          setState(() => _isLogin = true);
          _emailController.clear();
          _passwordController.clear();
          setState(() => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainApp()),
        );
      }
    } catch (e) {
      if (mounted) {
        final info = _describeAuthError(e);
        _showSnack(
          info.message,
          isError: true,
          action: info.showResend
              ? SnackBarAction(
                  label: 'RESEND',
                  textColor: Colors.white,
                  onPressed: () => _resendConfirmationEmail(email),
                )
              : null,
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Soft organic blobs instead of the usual generic gradient wash —
          // evokes produce silhouettes without being literal.
          Positioned(
            top: -70,
            right: -50,
            child: _blob(200, AppColors.primary.withOpacity(0.10)),
          ),
          Positioned(
            top: 140,
            left: -80,
            child: _blob(160, AppColors.accent.withOpacity(0.16)),
          ),
          Positioned(
            bottom: -90,
            right: -40,
            child: _blob(240, AppColors.primary.withOpacity(0.08)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo — the "clipped tag corner" motif in its most
                      // literal form, filled with the brand gradient.
                      Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primaryDark
                              ],
                            ),
                            borderRadius: tagRadius(r: 30, sharp: 10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.28),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Title
                      Text(
                        'SmartHealthFood',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? "Welcome back — let's fuel your day."
                            : 'A few taps and your kitchen gets smarter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card with the form
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: tagRadius(r: 32, sharp: 10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mode indicator
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: _modeTab('Login', true)),
                                    Expanded(child: _modeTab('Sign Up', false)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.ink),
                                decoration: _fieldDecoration(
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: AppColors.ink),
                                decoration: _fieldDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Login/Signup Button — brand gradient fill,
                              // same clipped-corner family as the logo/card.
                              SizedBox(
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: tagRadius(r: 16, sharp: 7),
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryLight
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.30),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: tagRadius(r: 16, sharp: 7),
                                      onTap: _isLoading ? null : _authenticate,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _isLogin ? 'Login' : 'Sign Up',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Toggle Login/Signup
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLogin
                                        ? "Don't have an account?"
                                        : 'Already have an account?',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                        _formKey.currentState?.reset();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryDark,
                                    ),
                                    child: Text(
                                      _isLogin ? 'Sign Up' : 'Login',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                              ),

                              // Guest Login Option
                              OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await Supabase.instance.client.auth
                                              .signInAnonymously();
                                          if (mounted) {
                                            Navigator.of(context)
                                                .pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const MainApp()),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            final info = _describeAuthError(e);
                                            _showSnack(info.message,
                                                isError: true);
                                          }
                                        }
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                icon: const Icon(Icons.person_outline_rounded,
                                    size: 20),
                                label: const Text('Continue as Guest'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryDark,
                                  side: BorderSide(
                                      color:
                                          AppColors.primary.withOpacity(0.3)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: tagRadius(r: 16, sharp: 7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool forLogin) {
    final selected = _isLogin == forLogin;
    return GestureDetector(
      onTap: () => setState(() {
        _isLogin = forLogin;
        _formKey.currentState?.reset();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.ink.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: selected ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bg.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.42),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

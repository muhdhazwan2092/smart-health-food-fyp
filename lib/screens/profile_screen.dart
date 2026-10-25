import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../themes/app_theme.dart';
import '../services/goal_state.dart';
import '../widgets/calorie_goal_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String _name = '';
  String? _avatarUrl;
  int _dailyGoal = dailyGoalNotifier.value;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isLoadingProfile = true;
  bool _isChangingPassword = false;
  bool _showPasswordSection = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  static const int _minPasswordLength = 8;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------
  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      if (data != null) {
        setState(() {
          _name = data['name'] ?? '';
          _avatarUrl = (data['avatar_url'] as String?)?.trim();
          if (_avatarUrl != null && _avatarUrl!.isEmpty) _avatarUrl = null;

          final goal = (data['daily_calorie_goal'] as num?)?.toInt();
          if (goal != null && goal > 0) {
            _dailyGoal = goal;
            dailyGoalNotifier.value = goal;
          }
        });
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
      if (mounted) {
        _showSnack('Could not load your profile. Pull back and try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _openEditDialog() async {
    final saved = await showGeneralDialog<bool>(
      context: context,
      // Tapping outside no longer throws away edits silently; the user must
      // use Cancel or Save.
      barrierDismissible: false,
      barrierLabel: 'Edit profile',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) => _EditProfileDialog(
        initialName: _name,
        initialAvatarUrl: _avatarUrl,
        isDarkMode: widget.isDarkMode,
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 24),
            child: Transform.scale(
              scale: 0.92 + (curved.value.clamp(0.0, 1.2) * 0.08),
              child: child,
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      _loadProfile();
    }
  }

  // ---------------------------------------------------------------------
  // Email helpers
  // ---------------------------------------------------------------------
  Future<void> _openGoalDialog() async {
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CalorieGoalDialog(
        currentGoal: _dailyGoal,
        isDarkMode: widget.isDarkMode,
      ),
    );
    if (result == null || !mounted) return;
    await _saveGoal(result);
  }

  Future<void> _saveGoal(int goal) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'daily_calorie_goal': goal,
      });
      if (!mounted) return;
      setState(() => _dailyGoal = goal);
      dailyGoalNotifier.value = goal; // dashboard updates immediately
      _showSnack('Daily goal set to $goal cal.', isError: false);
    } catch (e) {
      debugPrint('Save goal error: $e');
      _showSnack('Could not save your goal. Please try again.', isError: true);
    }
  }

  Future<void> _resendVerification(String email) async {
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email);
      _showSnack('Verification email sent to $email.', isError: false);
    } catch (e) {
      debugPrint('Resend verification error: $e');
      _showSnack('Could not send the email. Please try again later.',
          isError: true);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      _showSnack('Password reset email sent to $email.', isError: false);
    } catch (e) {
      debugPrint('Password reset error: $e');
      _showSnack('Could not send the reset email. Please try again later.',
          isError: true);
    }
  }

  // ---------------------------------------------------------------------
  // Security: change password (re-authenticates with current password
  // first, so a stolen/left-open session alone isn't enough to change it)
  // ---------------------------------------------------------------------
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      _showSnack(
        'Password changes aren\'t available for guest accounts.',
        isError: true,
      );
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: _currentPasswordController.text,
      );

      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        _showSnack('Password updated successfully!', isError: false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordSection = false);
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final friendly = msg.contains('invalid login credentials')
          ? 'Current password is incorrect.'
          : 'Could not update your password. Please try again.';
      debugPrint('Change password auth error: ${e.message}');
      if (mounted) _showSnack(friendly, isError: true);
    } catch (e) {
      debugPrint('Change password error: $e');
      if (mounted) {
        _showSnack('Something went wrong. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  // ---------------------------------------------------------------------
  // Logout / delete
  // ---------------------------------------------------------------------
  Future<void> _confirmLogout() async {
    final confirmed = await _showConfirmDialog(
      title: 'Log out?',
      message: 'You\'ll need to sign in again to access your account.',
      confirmLabel: 'Log out',
      isDestructive: false,
    );
    if (confirmed == true) await _logout();
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      // Clear the whole back stack so Back can't return to the main app.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title: 'Request account deletion?',
      message:
          'You will be signed out and a request to permanently delete your account and data will be sent. This cannot be undone.',
      confirmLabel: 'Request deletion',
      isDestructive: true,
    );
    if (confirmed != true) return;

    // Client apps can't fully delete a Supabase auth user without a
    // privileged service-role key (which must never live in the app).
    // The safe pattern is to flag the account for deletion here and let a
    // server-side function (Edge Function / cron job) do the actual
    // auth.admin.deleteUser call.
    final user = supabase.auth.currentUser;
    try {
      if (user != null) {
        await supabase.from('profiles').update({
          'deletion_requested_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
      await supabase.auth.signOut();
      if (mounted) {
        _showSnack('Deletion requested. You have been signed out.',
            isError: false);
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Delete request error: $e');
      if (mounted) {
        _showSnack(
          'Could not send the deletion request. Please try again.',
          isError: true,
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: tagRadius(r: 20, sharp: 8)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructive ? Colors.red.shade600 : AppColors.primary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: tagRadius(r: 14, sharp: 6)),
      ),
    );
  }

  // Same title style for both the loading and loaded states, in both themes.
  Widget _appBarTitle(bool isDark) {
    return Text(
      'Your Profile',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
    );
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final user = supabase.auth.currentUser;

    final String? rawEmail = user?.email;
    final bool hasEmail = rawEmail != null && rawEmail.isNotEmpty;
    final bool isGuest = !hasEmail;
    final String displayEmail = hasEmail ? rawEmail : 'Guest User';
    final String avatarLetter = hasEmail ? rawEmail[0].toUpperCase() : 'G';
    final bool isEmailVerified = !isGuest && user?.emailConfirmedAt != null;

    final cardColor = isDark ? const Color(0xFF1B3B2B) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    // Higher-contrast secondary text (grey on white was too faint).
    final mutedText = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final primaryText =
        isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.ink;

    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: _appBarTitle(isDark)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final headerLetter =
        _name.isNotEmpty ? _name[0].toUpperCase() : avatarLetter;

    return Scaffold(
      appBar: AppBar(
        title: _appBarTitle(isDark),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your account and personal info.',
              style: TextStyle(color: mutedText, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // ── One merged identity card (photo, name, email, status) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: tagRadius(r: 20, sharp: 8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatar(isDark, headerLetter, radius: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name.isEmpty ? 'Add your name' : _name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontStyle: _name.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: _name.isEmpty ? mutedText : primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: mutedText, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            if (!isGuest)
                              _buildBadge(
                                icon: isEmailVerified
                                    ? Icons.verified_rounded
                                    : Icons.error_outline_rounded,
                                label: isEmailVerified
                                    ? 'Email verified'
                                    : 'Email not verified',
                                color: isEmailVerified
                                    ? (isDark
                                        ? const Color.fromARGB(
                                            255, 196, 184, 184)
                                        : AppColors.primary)
                                    : Colors.orange.shade700,
                              )
                            else
                              _buildBadge(
                                icon: Icons.info_outline_rounded,
                                label: 'Guest account — limited features',
                                color: AppColors.inkSoft,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isGuest && !isEmailVerified)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _resendVerification(rawEmail),
                        child: const Text('Resend verification email'),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openEditDialog,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFF81C784)
                            : AppColors.primary,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF81C784)
                              : AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: tagRadius(r: 16, sharp: 7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Security section ───────────────────────────
            // ── Nutrition goal ─────────────────────────────
            Text(
              'Nutrition goal',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: tagRadius(r: 20, sharp: 8),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                minVerticalPadding: 14,
                leading: Icon(Icons.local_fire_department_rounded,
                    color:
                        isDark ? const Color(0xFF81C784) : AppColors.primary),
                title: Text(
                  'Daily calorie goal',
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$_dailyGoal cal per day · tap to change or calculate',
                  style: TextStyle(color: mutedText),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white70 : AppColors.inkSoft),
                onTap: _openGoalDialog,
              ),
            ),

            const SizedBox(height: 32),

            // ── Security section ───────────────────────────
            Text(
              'Security',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: tagRadius(r: 20, sharp: 8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline_rounded,
                        color: isDark ? Colors.white70 : AppColors.ink),
                    title: Text(
                      'Change password',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: isGuest
                        ? const Text('Not available for guest accounts')
                        : null,
                    trailing: Icon(
                      _showPasswordSection
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: isDark ? Colors.white70 : AppColors.inkSoft,
                    ),
                    enabled: !isGuest,
                    onTap: isGuest
                        ? null
                        : () => setState(
                            () => _showPasswordSection = !_showPasswordSection),
                  ),
                  if (_showPasswordSection && !isGuest)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrent,
                              autofillHints: const [AutofillHints.password],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.87)
                                    : Colors.black87,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Current password',
                                icon: Icons.lock_open_rounded,
                                isDark: isDark,
                                suffix: IconButton(
                                  tooltip: _obscureCurrent
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(_obscureCurrent
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter your current password'
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _sendPasswordReset(rawEmail!),
                                child: const Text('Forgot current password?'),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              autofillHints: const [AutofillHints.newPassword],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.87)
                                    : Colors.black87,
                              ),
                              decoration: _fieldDecoration(
                                label: 'New password',
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                helper:
                                    'At least $_minPasswordLength characters',
                                suffix: IconButton(
                                  tooltip: _obscureNew
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(_obscureNew
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter a new password';
                                }
                                if (v.length < _minPasswordLength) {
                                  return 'Must be at least $_minPasswordLength characters';
                                }
                                if (v == _currentPasswordController.text) {
                                  return 'New password must differ from current';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureNew,
                              autofillHints: const [AutofillHints.newPassword],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.87)
                                    : Colors.black87,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Confirm new password',
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                              ),
                              validator: (v) {
                                if (v != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isChangingPassword
                                    ? null
                                    : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: tagRadius(r: 14, sharp: 6),
                                  ),
                                ),
                                child: _isChangingPassword
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Update Password'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Account / danger zone ───────────────────────
            Text(
              'Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: tagRadius(r: 20, sharp: 8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.logout_rounded,
                        color: isDark ? Colors.white70 : AppColors.ink),
                    title: Text(
                      'Log out',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _confirmLogout,
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    enabled: !isGuest,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: isGuest ? Colors.grey : Colors.red.shade400,
                    ),
                    title: Text(
                      'Request account deletion',
                      style: TextStyle(
                        color: isGuest ? Colors.grey : Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isGuest
                          ? 'Not available for guest accounts'
                          : 'Permanently remove your account and data',
                    ),
                    onTap: isGuest ? null : _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, String fallbackLetter,
      {double radius = 26}) {
    final hasUrl = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: isDark
          ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
          : AppColors.accentSoft,
      backgroundImage: hasUrl ? NetworkImage(_avatarUrl!) : null,
      onBackgroundImageError: hasUrl ? (_, __) {} : null,
      child: hasUrl
          ? null
          : Text(
              fallbackLetter,
              style: TextStyle(
                color: isDark ? const Color(0xFF81C784) : AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.6,
              ),
            ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: tagRadius(r: 12, sharp: 5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    Widget? suffix,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? const Color(0xFF1B3B2B) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
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
}

// ---------------------------------------------------------------------------
// Floating edit dialog — its own StatefulWidget so picking an image and
// editing the name doesn't touch the parent screen's state until the user
// actually taps Save. The photo is kept in memory and only uploaded on Save,
// so Cancel never leaves stray files in storage. Uses bytes (not dart:io
// File), so it works on Android, iOS and web.
// ---------------------------------------------------------------------------
class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String? initialAvatarUrl;
  final bool isDarkMode;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialAvatarUrl,
    required this.isDarkMode,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final supabase = Supabase.instance.client;
  late final TextEditingController _nameController;

  Uint8List? _pickedBytes;
  String? _pickedMime;
  String? _remoteAvatarUrl;
  String? _nameError;
  bool _isSaving = false;

  static const int _maxNameLength = 30;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _remoteAvatarUrl = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return; // user cancelled

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedMime = picked.mimeType ?? 'image/jpeg';
      });
    } catch (e) {
      debugPrint('Pick image error: $e');
      if (mounted) {
        _showLocalSnack('Could not open your gallery. Please try again.',
            isError: true);
      }
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    final bytes = _pickedBytes;
    if (bytes == null) return _remoteAvatarUrl;

    // One fixed file per user: replaces the old photo instead of piling up
    // files with different extensions.
    final path = '$userId/avatar';

    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _pickedMime ?? 'image/jpeg',
          ),
        );

    // Bust cache so the new image shows immediately instead of a stale
    // cached copy at the same URL.
    final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
    return '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _save() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a display name');
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    try {
      final avatarUrl = await _uploadAvatar(user.id);

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'avatar_url': avatarUrl ?? '',
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Save profile error: $e');
      if (mounted) {
        _showLocalSnack('Could not save your profile. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showLocalSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: tagRadius(r: 14, sharp: 6)),
      ),
    );
  }

  ImageProvider? _avatarImage() {
    if (_pickedBytes != null) return MemoryImage(_pickedBytes!);
    if (_remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty) {
      return NetworkImage(_remoteAvatarUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1B3B2B) : Colors.white;
    final mutedText = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final image = _avatarImage();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: tagRadius(r: 28, sharp: 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Scrollable so the keyboard never causes an overflow on small phones.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // ── Tappable avatar with camera badge ──
              Center(
                child: Semantics(
                  button: true,
                  label: 'Change profile photo',
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickFromGallery,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: isDark
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
                              : AppColors.accentSoft,
                          backgroundImage: image,
                          child: image == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: isDark
                                      ? const Color(0xFF81C784)
                                      : AppColors.primaryDark,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 2.5),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to choose from gallery',
                  style: TextStyle(fontSize: 12, color: mutedText),
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.87)
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Display name',
                  errorText: _nameError,
                  prefixIcon:
                      Icon(Icons.badge_outlined, color: Colors.grey.shade500),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF16241C) : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white70 : AppColors.inkSoft,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: tagRadius(r: 16, sharp: 7),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: tagRadius(r: 16, sharp: 7),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/otp_password_reset_dialog.dart';
import '../../../main.dart';

class AdminLoginScreen extends StatefulWidget {
  final VoidCallback onAdminAuthenticated;
  /// Called only on mobile to go back to the user app. Pass null on web.
  final VoidCallback? onCancel;

  const AdminLoginScreen({
    super.key,
    required this.onAdminAuthenticated,
    this.onCancel,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1 — Sign in with Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Authentication failed.');

      // Step 2 — Verify is_admin flag in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final isAdmin = userDoc.data()?['is_admin'] == true;

      if (!isAdmin) {
        // Sign out immediately — not an admin
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() => _errorMessage =
              'Access denied. This account does not have administrator privileges.');
        }
        return;
      }

      // Step 3 — Admin verified ✓
      if (mounted) widget.onAdminAuthenticated();
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email address.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          msg = 'Too many failed attempts. Account temporarily locked.';
          break;
        case 'user-disabled':
          msg = 'This admin account has been disabled.';
          break;
        default:
          msg = 'Sign-in failed: ${e.message ?? e.code}';
      }
      if (mounted) setState(() => _errorMessage = msg);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final resetEmail = await OtpPasswordResetDialog.show(
      context,
      initialEmail: _emailController.text.trim(),
      isAdminPortal: true,
    );
    if (resetEmail != null && resetEmail.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = resetEmail;
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    final isSmall = screenWidth < 400;

    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.emeraldDeep, AppColors.primaryEmerald, Color(0xFF1A6B3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            height: isWide ? 320 : (isSmall ? 180 : 220),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : (isSmall ? 12 : 20),
                  vertical: isSmall ? 16 : 32,
                ),
                child: Column(
                  children: [
                    // Branding header
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          Container(
                            width: isSmall ? 52 : 64,
                            height: isSmall ? 52 : 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              size: isSmall ? 28 : 34,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          SizedBox(height: isSmall ? 8 : 14),
                          Text(
                            lp.tr('admin_portal_access'),
                            style: (isSmall
                                    ? AppTypography.headingSmall
                                    : AppTypography.headingLarge)
                                .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lp.tr('app_title'),
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmall ? 16 : 28),

                    // Login Card
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: EdgeInsets.all(isSmall ? 18 : 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emeraldDeep.withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lp.tr('sign_in_as_admin'),
                                style: (isSmall
                                        ? AppTypography.headingSmall
                                        : AppTypography.headingMedium)
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter your administrative credentials',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Error Banner
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Color(0xFFDC2626), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email field
                              Text(
                                lp.tr('email'),
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return lp.tr('please_enter_email');
                                  }
                                  if (!value.contains('@')) {
                                    return lp.tr('please_enter_email');
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: lp.tr('admin_email_hint'),
                                  hintStyle: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      size: 20, color: AppColors.primaryEmerald),
                                  filled: true,
                                  fillColor: AppColors.bgOffWhite,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryEmerald,
                                        width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red.shade400),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              Text(
                                lp.tr('password'),
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleAdminLogin(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return lp.tr('please_enter_password');
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: lp.tr('admin_pass_hint'),
                                  hintStyle: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      size: 20, color: AppColors.primaryEmerald),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.bgOffWhite,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryEmerald,
                                        width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red.shade400),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _handleForgotPassword,
                                  child: const Text(
                                    'Forgot Password / Reset Link?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryEmerald,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleAdminLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryEmerald,
                                    disabledBackgroundColor:
                                        AppColors.primaryEmerald.withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Text(
                                          lp.tr('sign_in_as_admin'),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Info note
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primaryEmerald.withValues(alpha: 0.25)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 15, color: AppColors.primaryEmerald),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Access is restricted to authorized administrators only.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryEmerald,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Back to app (mobile only)
                              if (widget.onCancel != null) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: widget.onCancel,
                                  icon: const Icon(Icons.arrow_back,
                                      size: 16, color: AppColors.primaryEmerald),
                                  label: Text(
                                    lp.tr('return_to_user_app'),
                                    style: const TextStyle(
                                      color: AppColors.primaryEmerald,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

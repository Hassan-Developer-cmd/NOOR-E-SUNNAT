import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/email_otp_service.dart';
import '../../../core/widgets/otp_password_reset_dialog.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback? onOpenWebAdmin;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onOpenWebAdmin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showWelcomeSnackbar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF34D399),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    globalLanguageProvider.tr('welcome_email_toast_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    globalLanguageProvider.tr('welcome_email_toast_body'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF064E3B),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        final email = _emailController.text.trim();
        final name = _nameController.text.trim();
        final user = await AuthService.signUpWithEmailAndPassword(
          email,
          _passwordController.text,
          username: name,
        );
        if (user != null) {
          // 1. Dispatch Spam-Proof Welcome Email via EmailJS
          EmailOtpService.sendWelcomeEmail(
            email: email,
            name: name,
          );
          // 2. Trigger instant native status-bar heads-up notification
          NotificationService.showWelcomeNotification();
          // 3. Show stylish bottom Snackbar
          if (mounted) _showWelcomeSnackbar();
        }
      } else {
        await AuthService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      }
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('] ')) msg = msg.split('] ').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final authResult = await AuthService.signInWithGoogle();
      if (authResult.user != null) {
        if (authResult.isNewUser && authResult.user!.email != null) {
          final email = authResult.user!.email!;
          final name = authResult.user!.displayName ?? '';
          // 1. Dispatch Spam-Proof Welcome Email via EmailJS
          EmailOtpService.sendWelcomeEmail(
            email: email,
            name: name,
          );
          // 2. Trigger instant native status-bar heads-up notification
          NotificationService.showWelcomeNotification();
          // 3. Show stylish bottom Snackbar
          if (mounted) _showWelcomeSnackbar();
        }
        if (mounted) widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final resetEmail = await OtpPasswordResetDialog.show(
      context,
      initialEmail: _emailController.text.trim(),
      isAdminPortal: false,
    );
    if (resetEmail != null && resetEmail.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = resetEmail;
        _passwordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Color(0xFF34D399), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isUrdu
                      ? "پاس ورڈ ری سیٹ کا لنک آپ کی ای میل پر بھیج دیا گیا ہے"
                      : "Password reset link has been sent to your email.",
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF064E3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Hero Banner Header ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 44, 28, 36),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0A3A2A),
                              Color(0xFF064E3B),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Language Toggle
                            Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: GestureDetector(
                                onTap: () => lp.toggleLanguage(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.language_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        lp.isUrdu ? 'EN' : 'اردو',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Logo Emblem
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.goldBright.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldBright.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      Icons.shield_moon_rounded,
                                      size: 38,
                                      color: AppColors.goldBright,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              lp.tr('app_title'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lp.tr('greeting_banner'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Form Body Card ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isSignUp ? lp.tr('sign_up') : lp.tr('sign_in'),
                              style: AppTypography.headingLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? lp.tr('login_subtitle_signup')
                                  : lp.tr('login_subtitle_signin'),
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: 24),

                            // ── Form Fields ──
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_isSignUp) ...[
                                    _buildField(
                                      controller: _nameController,
                                      hint: lp.tr('full_name'),
                                      icon: Icons.person_outline_rounded,
                                      validator: (v) => (_isSignUp && (v == null || v.trim().isEmpty))
                                          ? lp.tr('please_enter_name')
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _buildField(
                                    controller: _emailController,
                                    hint: lp.tr('email'),
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty || !v.contains('@'))
                                            ? lp.tr('please_enter_email')
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _passwordController,
                                    hint: lp.tr('password'),
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePassword,
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().length < 6)
                                        ? lp.tr('please_enter_password')
                                        : null,
                                  ),
                                  if (!_isSignUp) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: TextButton(
                                        onPressed: _handleForgotPassword,
                                        child: Text(
                                          lp.isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot Password?',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryEmerald,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ] else
                                    const SizedBox(height: 22),

                                  // Email Auth Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: (_loading || _googleLoading) ? null : _handleEmailAuth,
                                      child: _loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(_isSignUp ? lp.tr('sign_up') : lp.tr('sign_in')),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Toggle Sign In / Sign Up
                            Center(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _formKey.currentState?.reset();
                                }),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTypography.bodySmall,
                                    children: [
                                      TextSpan(
                                        text: _isSignUp
                                            ? lp.tr('already_have_account_prefix')
                                            : lp.tr('dont_have_account_prefix'),
                                      ),
                                      TextSpan(
                                        text: _isSignUp ? lp.tr('sign_in') : lp.tr('sign_up'),
                                        style: const TextStyle(
                                          color: AppColors.primaryEmerald,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.borderLight)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    lp.tr('or_divider'),
                                    style: AppTypography.caption,
                                  ),
                                ),
                                const Expanded(child: Divider(color: AppColors.borderLight)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── Official Premium Google Sign-In Button ──
                            _buildGoogleSignInButton(lp),

                            const SizedBox(height: 24),

                            // Terms & Privacy Footer
                            Center(
                              child: Text(
                                lp.tr('terms_privacy'),
                                textAlign: TextAlign.center,
                                style: AppTypography.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleSignInButton(LanguageProvider lp) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF4285F4).withValues(alpha: 0.1),
          highlightColor: Colors.black.withValues(alpha: 0.04),
          onTap: (_googleLoading || _loading) ? null : _handleGoogleSignIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_googleLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  )
                else ...[
                  Image.asset(
                    'assets/icons/google.png',
                    width: 22,
                    height: 22,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: _GoogleGLogoPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    lp.tr('continue_with_google'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTypography.titleMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

/// CustomPainter rendering Google's official 4-color 'G' logo
class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double strokeWidth = size.width * 0.22;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red: Top arc
    canvas.drawArc(rect, -2.35, 1.7, false, paintRed);
    // Yellow: Left arc
    canvas.drawArc(rect, -3.8, 1.45, false, paintYellow);
    // Green: Bottom arc
    canvas.drawArc(rect, 0.6, 1.55, false, paintGreen);
    // Blue: Right arc & bar
    canvas.drawArc(rect, -0.65, 1.25, false, paintBlue);

    // Crossbar for G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center - strokeWidth * 0.1, center - strokeWidth / 2, center * 0.8, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

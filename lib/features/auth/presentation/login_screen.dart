import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/email_otp_service.dart';
import '../../../core/widgets/app_exit_confirmation_dialog.dart';
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

  Future<void> _handlePopScope(bool didPop, dynamic result) async {
    if (didPop) return;
    if (_isSignUp) {
      setState(() => _isSignUp = false);
      return;
    }
    final shouldExit = await AppExitConfirmationDialog.show(context);
    if (shouldExit && mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => _handlePopScope(didPop, result),
          child: Scaffold(
            backgroundColor: AppColors.bgPrimary,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Hero Banner Header (Compact & Elegant) ──
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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
                                      bottomLeft: Radius.circular(28),
                                      bottomRight: Radius.circular(28),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Language Toggle
                                      Align(
                                        alignment: AlignmentDirectional.topEnd,
                                        child: GestureDetector(
                                          onTap: () => lp.toggleLanguage(),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.language_rounded, size: 13, color: Colors.white),
                                                const SizedBox(width: 5),
                                                Text(
                                                  lp.isUrdu ? 'EN' : 'اردو',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Logo Emblem
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.goldBright.withValues(alpha: 0.7),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.goldBright.withValues(alpha: 0.2),
                                              blurRadius: 12,
                                              spreadRadius: 1,
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
                                                size: 28,
                                                color: AppColors.goldBright,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        lp.tr('app_title'),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        lp.tr('greeting_banner'),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.white.withValues(alpha: 0.82),
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Form Body Card ──
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _isSignUp ? lp.tr('signup_button') : lp.tr('login_button'),
                                              style: TextStyle(
                                                fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                letterSpacing: 0.0,
                                                height: lp.isUrdu ? 1.3 : 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _isSignUp
                                                  ? lp.tr('login_subtitle_signup')
                                                  : lp.tr('login_subtitle_signin'),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // ── Form Fields ──
                                            Form(
                                              key: _formKey,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
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
                                                    const SizedBox(height: 10),
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
                                                  const SizedBox(height: 10),
                                                  _buildField(
                                                    controller: _passwordController,
                                                    hint: lp.tr('password'),
                                                    icon: Icons.lock_outline_rounded,
                                                    obscure: _obscurePassword,
                                                    suffixIcon: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                      icon: Icon(
                                                        _obscurePassword
                                                            ? Icons.visibility_off_outlined
                                                            : Icons.visibility_outlined,
                                                        size: 19,
                                                        color: AppColors.textMuted,
                                                      ),
                                                    ),
                                                    validator: (v) => (v == null || v.trim().length < 6)
                                                        ? lp.tr('please_enter_password')
                                                        : null,
                                                  ),
                                                  if (!_isSignUp) ...[
                                                    Align(
                                                      alignment: AlignmentDirectional.centerEnd,
                                                      child: InkWell(
                                                        onTap: _handleForgotPassword,
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(top: 6, bottom: 4),
                                                          child: Text(
                                                            lp.isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot Password?',
                                                            style: const TextStyle(
                                                              fontSize: 11.5,
                                                              color: AppColors.primaryEmerald,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ] else
                                                   const SizedBox(height: 12),

                                                   // Email Auth Button
                                                   SizedBox(
                                                     width: double.infinity,
                                                     height: 50,
                                                     child: ElevatedButton(
                                                       style: ElevatedButton.styleFrom(
                                                         backgroundColor: AppColors.primaryEmerald,
                                                         foregroundColor: Colors.white,
                                                         alignment: Alignment.center,
                                                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                         shape: RoundedRectangleBorder(
                                                           borderRadius: BorderRadius.circular(12),
                                                         ),
                                                         elevation: 1.5,
                                                       ),
                                                       onPressed: (_loading || _googleLoading) ? null : _handleEmailAuth,
                                                       child: _loading
                                                           ? const SizedBox(
                                                               width: 20,
                                                               height: 20,
                                                               child: CircularProgressIndicator(
                                                                 strokeWidth: 2.2,
                                                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                               ),
                                                             )
                                                           : Text(
                                                               _isSignUp ? lp.tr('signup_button') : lp.tr('login_button'),
                                                               textAlign: TextAlign.center,
                                                               style: TextStyle(
                                                                 fontFamily: lp.isUrdu
                                                                     ? AppTypography.urduFontFamily
                                                                     : AppTypography.englishFontFamily,
                                                                 fontSize: lp.isUrdu ? 16 : 15,
                                                                 fontWeight: FontWeight.bold,
                                                                 letterSpacing: 0.0,
                                                                 height: lp.isUrdu ? 1.25 : 1.2,
                                                                 color: Colors.white,
                                                               ),
                                                             ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                             ),

                                             const SizedBox(height: 10),

                                             // Toggle Sign In / Sign Up
                                             Center(
                                               child: GestureDetector(
                                                 onTap: () => setState(() {
                                                   _isSignUp = !_isSignUp;
                                                   _formKey.currentState?.reset();
                                                 }),
                                                 child: Padding(
                                                   padding: const EdgeInsets.symmetric(vertical: 2),
                                                   child: RichText(
                                                     text: TextSpan(
                                                       style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                       children: [
                                                         TextSpan(
                                                           text: _isSignUp
                                                               ? lp.tr('already_have_account_prefix')
                                                               : lp.tr('dont_have_account_prefix'),
                                                         ),
                                                         TextSpan(
                                                           text: _isSignUp ? lp.tr('login_button') : lp.tr('signup_button'),
                                                           style: TextStyle(
                                                             fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                                                             color: AppColors.primaryEmerald,
                                                             fontWeight: FontWeight.w700,
                                                             fontSize: 12,
                                                             letterSpacing: 0.0,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                             ),

                                            const SizedBox(height: 10),

                                            // Divider
                                            Row(
                                              children: [
                                                const Expanded(child: Divider(color: AppColors.borderLight)),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text(
                                                    lp.tr('or_divider'),
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                const Expanded(child: Divider(color: AppColors.borderLight)),
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            // ── Official Premium Google Sign-In Button ──
                                            _buildGoogleSignInButton(lp),
                                          ],
                                        ),

                                        // Terms & Privacy Footer
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Center(
                                            child: Text(
                                              lp.tr('terms_privacy'),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF4285F4).withValues(alpha: 0.1),
          highlightColor: Colors.black.withValues(alpha: 0.04),
          onTap: (_googleLoading || _loading) ? null : _handleGoogleSignIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_googleLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  )
                else ...[
                  Image.asset(
                    'assets/icons/google.png',
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomPaint(
                        painter: _GoogleGLogoPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    lp.tr('continue_with_google'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3C4043),
                      letterSpacing: lp.isUrdu ? 0.0 : 0.1,
                      height: lp.isUrdu ? 1.25 : 1.2,
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
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
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

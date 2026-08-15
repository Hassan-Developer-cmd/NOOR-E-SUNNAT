import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/language_provider.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';

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

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          username: _nameController.text,
        );
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
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) widget.onLoginSuccess();
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

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
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
                    // Language Toggle (mobile only)
                    if (!kIsWeb) ...[
                      Align(
                        alignment: Alignment.topRight,
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
                    ],

                    // Logo Emblem
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldBright.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldBright.withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_moon_rounded,
                        size: 38,
                        color: AppColors.goldBright,
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
                          ? 'Create your account to get started'
                          : 'Welcome back — sign in to continue',
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
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
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
    );
  }

  Widget _buildGoogleSignInButton(LanguageProvider lp) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (_googleLoading || _loading) ? null : _handleGoogleSignIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_googleLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  )
                else ...[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(
                      painter: _GoogleGLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    lp.tr('continue_with_google'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.2,
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

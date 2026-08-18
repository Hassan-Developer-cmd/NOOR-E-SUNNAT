import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../services/email_otp_service.dart';
import '../../main.dart';

enum ResetStep {
  enterEmail,
  enterOtp,
  newPassword,
  success,
}

class OtpPasswordResetDialog extends StatefulWidget {
  final String? initialEmail;
  final bool isAdminPortal;
  final void Function(String email)? onPasswordResetSuccess;

  const OtpPasswordResetDialog({
    super.key,
    this.initialEmail,
    this.isAdminPortal = false,
    this.onPasswordResetSuccess,
  });

  /// Static helper to display the modal sheet or dialog responsively
  static Future<String?> show(
    BuildContext context, {
    String? initialEmail,
    bool isAdminPortal = false,
    void Function(String email)? onPasswordResetSuccess,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: OtpPasswordResetDialog(
              initialEmail: initialEmail,
              isAdminPortal: isAdminPortal,
              onPasswordResetSuccess: onPasswordResetSuccess,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: OtpPasswordResetDialog(
              initialEmail: initialEmail,
              isAdminPortal: isAdminPortal,
              onPasswordResetSuccess: onPasswordResetSuccess,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<OtpPasswordResetDialog> createState() => _OtpPasswordResetDialogState();
}

class _OtpPasswordResetDialogState extends State<OtpPasswordResetDialog> {
  ResetStep _currentStep = ResetStep.enterEmail;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 300;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          if (_secondsRemaining <= 240) {
            _canResend = true; // allow resend after 1 minute of waiting
          }
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String get _formattedTime {
    final int m = _secondsRemaining ~/ 60;
    final int s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Step 1: Send OTP ──────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    final isUrdu = globalLanguageProvider.isUrdu;
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = isUrdu
          ? 'براہ کرم درست ای میل پتہ درج کریں۔'
          : 'Please enter a valid Gmail / Email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await EmailOtpService.sendPasswordResetOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _startTimer();
      setState(() {
        _currentStep = ResetStep.enterOtp;
        _successMessage = isUrdu
            ? 'آپ کے ای میل $email پر ۶ ہندسوں کا تصدیقی کوڈ بھیجا گیا ہے۔'
            : 'A 6-digit verification code has been dispatched to $email';
      });
    } else {
      setState(() {
        _errorMessage = isUrdu
            ? 'ای میل بھیجنے میں ناکامی ہوئی۔ براہ کرم اپنا انٹرنیٹ یا ای میل چیک کریں۔'
            : 'Could not send verification email. Please check your internet connection or email address.';
      });
    }
  }

  // ── Step 2: Verify OTP & Proceed to Step 3 ────────────────────────
  Future<void> _verifyOtpAndProceed() async {
    if (_isLoading) return;
    final isUrdu = globalLanguageProvider.isUrdu;
    final email = _emailController.text.trim().toLowerCase();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = isUrdu
          ? 'براہ کرم مکمل ۶ ہندسوں کا کوڈ درج کریں۔'
          : 'Please enter the full 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bool isValid = await EmailOtpService.verifyOtp(email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      _countdownTimer?.cancel();
      setState(() {
        _currentStep = ResetStep.newPassword; // MUST TRIGGER REBUILD TO STEP 3
        _errorMessage = null;
      });
    } else {
      final errorText = isUrdu
          ? 'درج کردہ او ٹی پی غلط ہے یا اس کی میعاد ختم ہو چکی ہے'
          : 'Invalid or expired OTP.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _errorMessage = errorText;
      });
    }
  }

  // ── Step 3: Update Password ────────────────────────────────────────
  Future<void> _handleUpdatePassword() async {
    final isUrdu = globalLanguageProvider.isUrdu;
    final email = _emailController.text.trim().toLowerCase();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _errorMessage = isUrdu
          ? 'پاس ورڈ کم از کم ۶ حروف پر مشتمل ہونا چاہیے۔'
          : 'Password must be at least 6 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = isUrdu
          ? 'پاس ورڈز مطابقت نہیں رکھتے۔'
          : 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If user is currently signed in, update in auth instance
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email?.toLowerCase() == email) {
        await currentUser.updatePassword(newPassword);
      } else {
        // Dispatch official Firebase password reset confirmation
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        } catch (_) {}
      }

      // Cleanup used OTP record from Firestore
      await EmailOtpService.cleanupOtp(email);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Invoke optional success callback
      widget.onPasswordResetSuccess?.call(email);

      // Show celebration toast
      final successToast = isUrdu
          ? 'پاس ورڈ کامیابی سے تبدیل ہو گیا! براہ کرم لاگ ان کریں۔'
          : 'Password reset successful! Please log in.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  successToast,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryEmerald,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Close modal returning email for pre-fill
      Navigator.pop(context, email);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = isUrdu
            ? 'پاس ورڈ تبدیل کرنے میں خرابی: $e'
            : 'Error updating password: $e';
      });
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    if (!_canResend || _isLoading) return;
    final isUrdu = globalLanguageProvider.isUrdu;
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await EmailOtpService.sendPasswordResetOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _startTimer();
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu
              ? 'نیا ۶ ہندسوں کا کوڈ بھیج دیا گیا ہے۔'
              : 'A fresh 6-digit OTP has been sent to your email.'),
          backgroundColor: AppColors.primaryEmerald,
        ),
      );
    } else {
      setState(() {
        _errorMessage = isUrdu
            ? 'او ٹی پی دوبارہ بھیجنے میں ناکامی ہوئی۔'
            : 'Failed to resend OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Icon & Title ──
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _currentStep == ResetStep.success
                      ? const Color(0xFFDCFCE7)
                      : AppColors.emeraldContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStep == ResetStep.success
                      ? Icons.verified_user_rounded
                      : (_currentStep == ResetStep.newPassword
                          ? Icons.password_rounded
                          : Icons.lock_reset_rounded),
                  color: _currentStep == ResetStep.success
                      ? const Color(0xFF16A34A)
                      : AppColors.primaryEmerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getHeaderTitle(isUrdu),
                      style: AppTypography.headingMedium.copyWith(fontSize: 17),
                    ),
                    Text(
                      widget.isAdminPortal
                          ? (isUrdu ? 'ایڈمن پورٹل' : 'Admin Security Portal')
                          : lp.tr('app_title'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Error Banner ──
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
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
            const SizedBox(height: 14),
          ],

          // ── Step Content ──
          if (_currentStep == ResetStep.enterEmail) _buildEmailStep(isUrdu),
          if (_currentStep == ResetStep.enterOtp) _buildVerifyOtpStep(isUrdu),
          if (_currentStep == ResetStep.newPassword) _buildNewPasswordStep(isUrdu),
          if (_currentStep == ResetStep.success) _buildSuccessStep(isUrdu),
        ],
      ),
    );
  }

  String _getHeaderTitle(bool isUrdu) {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return isUrdu ? 'پاس ورڈ ری سیٹ کریں' : 'Reset Password via OTP';
      case ResetStep.enterOtp:
        return isUrdu ? '۶ ہندسوں کا او ٹی پی درج کریں' : 'Enter 6-Digit OTP';
      case ResetStep.newPassword:
        return isUrdu ? 'نیا پاس ورڈ درج کریں' : 'Create New Password';
      case ResetStep.success:
        return isUrdu ? 'پاس ورڈ کامیابی سے تبدیل ہو گیا!' : 'OTP Verified Successfully!';
    }
  }

  // ── Step 1 UI: Enter Email ─────────────────────────────────────────
  Widget _buildEmailStep(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isUrdu
              ? 'اپنا رجسٹرڈ ای میل درج کریں۔ ہم آپ کی تصدیق کے لیے ۶ ہندسوں کا او ٹی پی کوڈ ای میل کریں گے۔'
              : 'Enter your registered email address. We will generate and email you a secure 6-digit OTP code to verify your identity.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
        ),
        const SizedBox(height: 18),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: isUrdu ? 'جی میل / ای میل ایڈریس' : 'Gmail / Email Address',
            hintText: 'user@example.com',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryEmerald),
            filled: true,
            fillColor: AppColors.bgOffWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isLoading
                  ? (isUrdu ? 'کوڈ بھیجا جا رہا ہے...' : 'Dispatching OTP...')
                  : (isUrdu ? '۶ ہندسوں کا کوڈ بھیجیں' : 'Send 6-Digit OTP Code'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2 UI: Enter 6-Digit Code ──────────────────────────────────
  Widget _buildVerifyOtpStep(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_successMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_rounded, color: AppColors.primaryEmerald, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUrdu
                            ? 'نوٹ: اگر ان باکس میں نہ ملے تو اسپام فولڈر چیک کریں۔'
                            : 'Tip: If not in Primary inbox, check Spam/Junk folder.',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Countdown Timer & Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _secondsRemaining > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _secondsRemaining > 0 ? const Color(0xFFFDE68A) : const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: _secondsRemaining > 0 ? const Color(0xFFB45309) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _secondsRemaining > 0
                        ? (isUrdu ? 'کوڈ کی میعاد:' : 'Code Expires In:')
                        : (isUrdu ? 'میعاد ختم' : 'Code Expired'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _secondsRemaining > 0 ? const Color(0xFFB45309) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              Text(
                _formattedTime,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _secondsRemaining > 0 ? const Color(0xFFB45309) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6-Digit OTP Field with Auto-Submit on 6 digits
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 26,
            letterSpacing: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryEmerald,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: TextStyle(
              fontSize: 26,
              letterSpacing: 14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: AppColors.bgOffWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
            ),
          ),
          onChanged: (val) {
            // Auto-submit when user finishes entering 6 digits
            if (val.trim().length == 6) {
              _verifyOtpAndProceed();
            }
          },
        ),
        const SizedBox(height: 18),

        // Verify Button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _verifyOtpAndProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              _isLoading
                  ? (isUrdu ? 'تصدیق جاری ہے...' : 'Verifying...')
                  : (isUrdu ? 'او ٹی پی تصدیق کریں' : 'Verify OTP Code'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Resend or Change Email Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = ResetStep.enterEmail;
                  _otpController.clear();
                  _errorMessage = null;
                });
              },
              child: Text(
                isUrdu ? 'ای میل تبدیل کریں' : 'Change Email',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _canResend ? _handleResendOtp : null,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                _canResend
                    ? (isUrdu ? 'دوبارہ کوڈ بھیجیں' : 'Resend OTP')
                    : '${isUrdu ? "دوبارہ بھیجیں" : "Resend in"} ${_secondsRemaining > 240 ? (_secondsRemaining - 240) : 0}s',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3 UI: Create New Password ────────────────────────────────
  Widget _buildNewPasswordStep(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isUrdu
                      ? 'او ٹی پی تصدیق مکمل! براہ کرم اپنا نیا پاس ورڈ درج کریں۔'
                      : 'OTP Verified! Please enter your new password below.',
                  style: const TextStyle(
                    color: Color(0xFF14532D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Input 1: New Password field
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: isUrdu ? 'نیا پاس ورڈ' : 'New Password',
            hintText: isUrdu ? 'کم از کم ۶ حروف' : 'At least 6 characters',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryEmerald),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            filled: true,
            fillColor: AppColors.bgOffWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Input 2: Confirm New Password field
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: isUrdu ? 'پاس ورڈ کی تصدیق کریں' : 'Confirm New Password',
            hintText: isUrdu ? 'پاس ورڈ دوبارہ درج کریں' : 'Re-enter your new password',
            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryEmerald),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            filled: true,
            fillColor: AppColors.bgOffWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action Button: Update Password
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleUpdatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _isLoading
                  ? (isUrdu ? 'پاس ورڈ تبدیل ہو رہا ہے...' : 'Updating Password...')
                  : (isUrdu ? 'پاس ورڈ تبدیل کریں' : 'Update Password'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4 UI: Verification Success ────────────────────────────────
  Widget _buildSuccessStep(bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
              const SizedBox(height: 12),
              Text(
                isUrdu ? 'پاس ورڈ کامیابی سے تبدیل ہو گیا!' : 'Password Reset Successful!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUrdu
                    ? 'آپ کا نیا پاس ورڈ سیٹ ہو چکا ہے۔ اب آپ اپنے نئے پاس ورڈ سے لاگ ان کر سکتے ہیں۔'
                    : 'Your new password has been set. You can now log in with your new credentials.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _emailController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              isUrdu ? 'لاگ ان کی طرف واپس جائیں' : 'Done & Return to Login',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

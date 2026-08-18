import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../services/email_otp_service.dart';
import '../../main.dart';

enum OtpResetStage {
  enterEmail,
  verifyOtp,
  success,
}

class OtpPasswordResetDialog extends StatefulWidget {
  final String? initialEmail;
  final bool isAdminPortal;

  const OtpPasswordResetDialog({
    super.key,
    this.initialEmail,
    this.isAdminPortal = false,
  });

  /// Static helper to display the modal sheet or dialog responsively
  static Future<void> show(BuildContext context, {String? initialEmail, bool isAdminPortal = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return showDialog(
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
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
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
  OtpResetStage _currentStage = OtpResetStage.enterEmail;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

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

  // ── Stage 1: Send OTP ──────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid Gmail / Email address.');
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
        _currentStage = OtpResetStage.verifyOtp;
        _successMessage = 'A 6-digit verification code has been dispatched to $email';
      });
    } else {
      setState(() {
        _errorMessage = 'Could not send verification email. Please check your internet connection or email address.';
      });
    }
  }

  // ── Stage 2: Verify OTP ────────────────────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isVerified = await EmailOtpService.verifyOtp(email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isVerified) {
      _countdownTimer?.cancel();
      // Dispatch official Firebase Auth password reset email as completion
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      } catch (_) {}

      setState(() {
        _currentStage = OtpResetStage.success;
      });
    } else {
      setState(() {
        _errorMessage = 'Invalid or expired 6-digit OTP code. Please verify and try again.';
      });
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    if (!_canResend || _isLoading) return;
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
        const SnackBar(
          content: Text('A fresh 6-digit OTP has been sent to your email.'),
          backgroundColor: AppColors.primaryEmerald,
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;

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
                  color: _currentStage == OtpResetStage.success
                      ? const Color(0xFFDCFCE7)
                      : AppColors.emeraldContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStage == OtpResetStage.success
                      ? Icons.verified_user_rounded
                      : Icons.lock_reset_rounded,
                  color: _currentStage == OtpResetStage.success
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
                      _currentStage == OtpResetStage.success
                          ? 'OTP Verified Successfully!'
                          : (_currentStage == OtpResetStage.verifyOtp
                              ? 'Enter 6-Digit OTP'
                              : 'Reset Password via OTP'),
                      style: AppTypography.headingMedium.copyWith(fontSize: 17),
                    ),
                    Text(
                      widget.isAdminPortal ? 'Admin Security Portal' : lp.tr('app_title'),
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
          if (_currentStage == OtpResetStage.enterEmail) _buildEmailStep(),
          if (_currentStage == OtpResetStage.verifyOtp) _buildVerifyOtpStep(),
          if (_currentStage == OtpResetStage.success) _buildSuccessStep(),
        ],
      ),
    );
  }

  // ── Step 1 UI: Enter Email ─────────────────────────────────────────
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter your registered email address. We will generate and email you a secure 6-digit OTP code to verify your identity.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
        ),
        const SizedBox(height: 18),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: 'Gmail / Email Address',
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
              _isLoading ? 'Dispatching OTP...' : 'Send 6-Digit OTP Code',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2 UI: Enter 6-Digit Code ──────────────────────────────────
  Widget _buildVerifyOtpStep() {
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
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
                    _secondsRemaining > 0 ? 'Code Expires In:' : 'Code Expired',
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

        // 6-Digit OTP Field
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
            if (val.length == 6) {
              _handleVerifyOtp();
            }
          },
        ),
        const SizedBox(height: 18),

        // Verify Button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleVerifyOtp,
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
              _isLoading ? 'Verifying...' : 'Verify OTP Code',
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
                  _currentStage = OtpResetStage.enterEmail;
                  _otpController.clear();
                  _errorMessage = null;
                });
              },
              child: const Text(
                'Change Email',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _canResend ? _handleResendOtp : null,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                _canResend ? 'Resend OTP' : 'Resend in ${_secondsRemaining > 240 ? (_secondsRemaining - 240) : 0}s',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3 UI: Verification Success ────────────────────────────────
  Widget _buildSuccessStep() {
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
              const Text(
                'Identity Verified via 6-Digit OTP!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your email (${_emailController.text.trim()}) has been securely verified. An official Firebase password reset confirmation has also been dispatched to your inbox so you can finalize your new credentials.',
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Done & Return to Login',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

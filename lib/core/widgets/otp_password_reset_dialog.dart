import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../providers/language_provider.dart';
import '../services/email_otp_service.dart';
import '../../main.dart';

enum ResetDialogStage {
  inputEmail,
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
  ResetDialogStage _stage = ResetDialogStage.inputEmail;
  final TextEditingController _emailController = TextEditingController();

  // 6-digit OTP PIN controllers & focus nodes
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(6, (_) => FocusNode());
  final List<FocusNode> _keyboardFocusNodes =
      List.generate(6, (_) => FocusNode());

  // Password fields
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // State & timer
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    for (var k in _keyboardFocusNodes) {
      k.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredOtp =>
      _pinControllers.map((c) => c.text.trim()).join();

  Future<void> _handleSendOtp() async {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = isUrdu
            ? 'براہ کرم درست ای میل پتہ درج کریں۔'
            : 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await EmailOtpService.sendPasswordResetOtp(email);
      if (!mounted) return;

      if (success) {
        setState(() {
          _isLoading = false;
          _stage = ResetDialogStage.enterOtp;
        });
        _startResendTimer();
        for (var c in _pinControllers) {
          c.clear();
        }
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _pinFocusNodes.isNotEmpty) {
            _pinFocusNodes[0].requestFocus();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = isUrdu
              ? 'او ٹی پی کوڈ بھیجنے میں ناکامی ہوئی۔ براہ کرم دوبارہ کوشش کریں۔'
              : 'Failed to dispatch OTP code. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = isUrdu
            ? 'ایک غیر متوقع خرابی پیش آگئی: $e'
            : 'An unexpected error occurred: $e';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await EmailOtpService.sendPasswordResetOtp(email);
      if (!mounted) return;

      setState(() => _isLoading = false);
      if (success) {
        _startResendTimer();
        for (var c in _pinControllers) {
          c.clear();
        }
        if (_pinFocusNodes.isNotEmpty) {
          _pinFocusNodes[0].requestFocus();
        }
      } else {
        setState(() {
          _errorMessage = isUrdu
              ? 'دوبارہ کوڈ بھیجنے میں خرابی پیش آگئی۔'
              : 'Failed to resend verification code.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '$e';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final email = _emailController.text.trim().toLowerCase();
    final otp = _enteredOtp;

    if (otp.length < 6) {
      setState(() {
        _errorMessage = isUrdu
            ? 'براہ کرم مکمل 6 ہندسوں کا او ٹی پی کوڈ درج کریں۔'
            : 'Please enter the complete 6-digit OTP code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await EmailOtpService.verifyOtp(email, otp);
      if (!mounted) return;

      if (isValid) {
        setState(() {
          _isLoading = false;
          _stage = ResetDialogStage.newPassword;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = lp.tr('otp_invalid_or_expired');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = isUrdu
            ? 'تصدیق کے دوران خرابی پیش آگئی: $e'
            : 'Verification failed: $e';
      });
    }
  }

  Future<void> _handleUpdatePassword() async {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final email = _emailController.text.trim().toLowerCase();
    final otp = _enteredOtp;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = isUrdu
            ? 'پاس ورڈ کم از کم 6 ہندسوں کا ہونا چاہیے۔'
            : 'Password must be at least 6 characters long.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = lp.tr('passwords_dont_match');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await EmailOtpService.updateUserPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        widget.onPasswordResetSuccess?.call(email);
        setState(() {
          _isLoading = false;
          _stage = ResetDialogStage.success;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = isUrdu
            ? 'پاس ورڈ تبدیل کرنے میں خرابی: $e'
            : 'Failed to update password: $e';
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
          // ── Header Bar ──
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _stage == ResetDialogStage.success
                      ? const Color(0xFFDCFCE7)
                      : AppColors.emeraldContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _stage == ResetDialogStage.success
                      ? Icons.check_circle_rounded
                      : (_stage == ResetDialogStage.enterOtp
                          ? Icons.pin_rounded
                          : (_stage == ResetDialogStage.newPassword
                              ? Icons.lock_open_rounded
                              : Icons.lock_reset_rounded)),
                  color: _stage == ResetDialogStage.success
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
                      _stage == ResetDialogStage.success
                          ? (isUrdu ? 'پاس ورڈ تبدیل ہو گیا!' : 'Password Reset!')
                          : (_stage == ResetDialogStage.enterOtp
                              ? lp.tr('step2_verify_title')
                              : (_stage == ResetDialogStage.newPassword
                                  ? lp.tr('step3_new_password_title')
                                  : lp.tr('forgot_password_title'))),
                      style: AppTypography.headingMedium.copyWith(fontSize: 17),
                    ),
                    Text(
                      _stage == ResetDialogStage.enterOtp
                          ? (isUrdu ? 'مرحلہ 2 از 3' : 'Step 2 of 3: Verification')
                          : (_stage == ResetDialogStage.newPassword
                              ? (isUrdu ? 'مرحلہ 3 از 3' : 'Step 3 of 3: New Password')
                              : (widget.isAdminPortal
                                  ? (isUrdu ? 'ایڈمن سیکیورٹی پورٹل' : 'Admin Security Portal')
                                  : (isUrdu ? 'مرحلہ 1 از 3' : 'Step 1 of 3: Email OTP'))),
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
                onPressed: () => Navigator.pop(context, _emailController.text.trim()),
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
          if (_stage == ResetDialogStage.inputEmail) _buildStep1Email(lp, isUrdu),
          if (_stage == ResetDialogStage.enterOtp) _buildStep2Otp(lp, isUrdu),
          if (_stage == ResetDialogStage.newPassword) _buildStep3NewPassword(lp, isUrdu),
          if (_stage == ResetDialogStage.success) _buildStep4Success(lp, isUrdu),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 1: Email Input
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep1Email(LanguageProvider lp, bool isUrdu) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lp.tr('forgot_password_subtitle_step1'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _handleSendOtp(),
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
              _isLoading ? lp.tr('sending_otp') : lp.tr('send_otp_btn'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 2: 6-Digit OTP Entry & 60s Timer
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep2Otp(LanguageProvider lp, bool isUrdu) {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtitle info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${lp.tr('step2_verify_subtitle')} $email',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6 Discrete Styled PIN Input Boxes
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildSinglePinBox(index)),
          ),
        ),
        const SizedBox(height: 20),

        // Resend Timer & Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _stage = ResetDialogStage.inputEmail;
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryEmerald),
              label: Text(
                lp.tr('change_email'),
                style: const TextStyle(fontSize: 12, color: AppColors.primaryEmerald, fontWeight: FontWeight.w600),
              ),
            ),
            if (_resendCountdown > 0)
              Text(
                '${lp.tr('resend_code_in')} ${_resendCountdown}s',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              )
            else
              TextButton(
                onPressed: _isLoading ? null : _handleResendOtp,
                child: Text(
                  lp.tr('resend_otp_btn'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryEmerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

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
                : const Icon(Icons.verified_user_rounded, size: 18),
            label: Text(
              _isLoading ? lp.tr('verifying_otp') : lp.tr('verify_otp_btn'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePinBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: KeyboardListener(
        focusNode: _keyboardFocusNodes[index],
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _pinControllers[index].text.isEmpty &&
              index > 0) {
            _pinFocusNodes[index - 1].requestFocus();
            _pinControllers[index - 1].clear();
          }
        },
        child: TextFormField(
          controller: _pinControllers[index],
          focusNode: _pinFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            filled: true,
            fillColor: AppColors.bgOffWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
            ),
          ),
          onChanged: (val) {
            // Handle paste if multi-digit pasted
            if (val.length > 1) {
              final digits = val.replaceAll(RegExp(r'\D'), '');
              for (int i = 0; i < digits.length && (index + i) < 6; i++) {
                _pinControllers[index + i].text = digits[i];
              }
              final nextIndex = (index + digits.length < 6) ? index + digits.length : 5;
              _pinFocusNodes[nextIndex].requestFocus();
              if (_enteredOtp.length == 6) {
                _handleVerifyOtp();
              }
              return;
            }

            if (val.isNotEmpty) {
              if (index < 5) {
                _pinFocusNodes[index + 1].requestFocus();
              } else {
                _pinFocusNodes[index].unfocus();
                if (_enteredOtp.length == 6) {
                  _handleVerifyOtp();
                }
              }
            }
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 3: Create New Password & Real Auth Update
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep3NewPassword(LanguageProvider lp, bool isUrdu) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_clock_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lp.tr('step3_new_password_subtitle'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // New Password Field
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: lp.tr('new_password_label'),
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryEmerald),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
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

        // Confirm Password Field
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: lp.tr('confirm_password_label'),
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryEmerald),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
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

        // Update Password Action Button
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
                : const Icon(Icons.security_update_good_rounded, size: 18),
            label: Text(
              _isLoading ? lp.tr('updating_password') : lp.tr('update_password_btn'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 4: Success Stage
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep4Success(LanguageProvider lp, bool isUrdu) {
    final email = _emailController.text.trim();

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
                lp.tr('password_updated_success_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lp.tr('password_updated_success_msg'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, email),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              lp.tr('return_to_login'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

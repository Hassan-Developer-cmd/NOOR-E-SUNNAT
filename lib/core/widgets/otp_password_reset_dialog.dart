import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../providers/language_provider.dart';
import '../../main.dart';

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
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSent = false;

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
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
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
      // Official Google / Firebase Password Reset Link Dispatch
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSent = true;
      });

      widget.onPasswordResetSuccess?.call(email);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = isUrdu
              ? 'اس ای میل کے ساتھ کوئی اکاؤنٹ نہیں ملا۔'
              : 'No account found with this email address.';
          break;
        case 'invalid-email':
          msg = isUrdu
              ? 'ای میل کا فارمیٹ درست نہیں ہے۔'
              : 'The email address is badly formatted.';
          break;
        case 'too-many-requests':
          msg = isUrdu
              ? 'بہت زیادہ درخواستیں۔ براہ کرم کچھ دیر بعد کوشش کریں۔'
              : 'Too many requests. Please try again later.';
          break;
        default:
          msg = e.message ?? (isUrdu ? 'ری سیٹ لنک بھیجنے میں خرابی پیش آگئی۔' : 'Error sending reset email.');
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
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
                  color: _isSent ? const Color(0xFFDCFCE7) : AppColors.emeraldContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                  color: _isSent ? const Color(0xFF16A34A) : AppColors.primaryEmerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSent
                          ? (isUrdu ? 'لنک بھیج دیا گیا!' : 'Reset Link Sent!')
                          : (isUrdu ? 'پاس ورڈ ری سیٹ کریں' : 'Reset Password'),
                      style: AppTypography.headingMedium.copyWith(fontSize: 17),
                    ),
                    Text(
                      widget.isAdminPortal
                          ? (isUrdu ? 'ایڈمن سیکیورٹی پورٹل' : 'Admin Security Portal')
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

          // ── Stage Content ──
          if (!_isSent) _buildInputStage(lp, isUrdu),
          if (_isSent) _buildSuccessStage(lp, isUrdu),
        ],
      ),
    );
  }

  Widget _buildInputStage(LanguageProvider lp, bool isUrdu) {
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
              const Icon(Icons.security_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isUrdu
                      ? 'اپنا رجسٹرڈ ای میل درج کریں۔ ہم آپ کو گوگل کا آفیشل، محفوظ پاس ورڈ ری سیٹ لنک بھیجیں گے جس سے آپ نیا پاس ورڈ سیٹ کر سکیں گے۔'
                      : 'Enter your registered email address. We will send you an official secure Firebase password reset link to choose your new password.',
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
          onSubmitted: (_) => _handleSendResetEmail(),
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
            onPressed: _isLoading ? null : _handleSendResetEmail,
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
                  ? (isUrdu ? 'لنک بھیجا جا رہا ہے...' : 'Sending Reset Link...')
                  : (isUrdu ? 'پاس ورڈ ری سیٹ لنک بھیجیں' : 'Send Password Reset Link'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStage(LanguageProvider lp, bool isUrdu) {
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
              const Icon(Icons.mark_email_read_rounded, color: Color(0xFF16A34A), size: 48),
              const SizedBox(height: 12),
              Text(
                isUrdu ? 'ری سیٹ لنک بھیج دیا گیا!' : 'Official Reset Link Dispatched!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUrdu
                    ? 'ہم نے $email پر پاس ورڈ ری سیٹ لنک بھیج دیا ہے۔ براہ کرم اپنا ان باکس چیک کریں اور لنک پر کلک کر کے نیا پاس ورڈ سیٹ کریں۔'
                    : 'We have dispatched an official password reset link to $email. Please check your inbox and click the secure link to set your new credentials.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB45309)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isUrdu
                      ? 'نوٹ: اگر فوری طور پر ان باکس میں نہ ملے تو اسپام یا اپ ڈیٹس فولڈر بھی دیکھیں۔'
                      : 'Tip: If not in your primary inbox, please check your Spam or Updates tab.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
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
              isUrdu ? 'مکمل کریں اور لاگ ان پر جائیں' : 'Done & Return to Login',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

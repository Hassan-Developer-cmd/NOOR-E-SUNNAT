import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../main.dart';
import '../../services/terms_acceptance_service.dart';

class TermsAcceptanceDialog extends StatefulWidget {
  final VoidCallback? onAccepted;

  const TermsAcceptanceDialog({super.key, this.onAccepted});

  /// Displays the modal dialog blocking further interaction until terms are accepted.
  /// `barrierDismissible: false` and `PopScope(canPop: false)` ensure the user cannot bypass it.
  static Future<void> show(BuildContext context, {VoidCallback? onAccepted}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierLabel: 'Terms & Conditions Acceptance',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return PopScope(
          canPop: false,
          child: TermsAcceptanceDialog(onAccepted: onAccepted),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<TermsAcceptanceDialog> {
  int _activeTab = 0; // 0: Terms, 1: Privacy
  bool _isAccepting = false;
  late bool _dialogUrdu;

  @override
  void initState() {
    super.initState();
    _dialogUrdu = globalLanguageProvider.isUrdu;
  }

  Future<void> _handleAccept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      await TermsAcceptanceService.acceptTerms();
      widget.onAccepted?.call();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  void _toggleDialogLanguage() {
    setState(() => _dialogUrdu = !_dialogUrdu);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = _dialogUrdu;
    final textDirection = isUrdu ? TextDirection.rtl : TextDirection.ltr;
    final fontFamily = isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily;

    final mediaQuery = MediaQuery.of(context);
    final dialogHeight = (mediaQuery.size.height * 0.82).clamp(480.0, 680.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          height: dialogHeight,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Directionality(
            textDirection: textDirection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Branded Header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF064E3B), // Deep Islamic Emerald
                        Color(0xFF047857), // Forest Emerald
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    children: [
                      // Icon Emblem
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldBright, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.goldBright,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Notice
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isUrdu
                                  ? 'شرائط و پرائیویسی پالیسی'
                                  : 'Terms & Privacy Policy',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: isUrdu ? 0.0 : 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUrdu
                                  ? 'جاری رکھنے کے لیے شرائط ملاحظہ فرمائیں'
                                  : 'Please review and accept to continue',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Language Switcher Chip
                      InkWell(
                        onTap: _toggleDialogLanguage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                isUrdu ? 'English' : 'اردو',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Segment Tab Switcher ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeTab == 0 ? AppColors.primaryEmerald : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isUrdu ? 'استعمال کی شرائط' : 'Terms of Service',
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _activeTab == 0 ? Colors.white : const Color(0xFF475569),
                                  letterSpacing: isUrdu ? 0.0 : 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeTab == 1 ? AppColors.primaryEmerald : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isUrdu ? 'پرائیویسی پالیسی' : 'Privacy Policy',
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _activeTab == 1 ? Colors.white : const Color(0xFF475569),
                                  letterSpacing: isUrdu ? 0.0 : 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Scrollable Content Area ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    child: _activeTab == 0
                        ? _buildTermsContent(isUrdu, fontFamily)
                        : _buildPrivacyContent(isUrdu, fontFamily),
                  ),
                ),

                // ── Bottom Action Container (Non-Dismissible Gate) ──
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryEmerald,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isAccepting ? null : _handleAccept,
                          child: _isAccepting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        isUrdu
                                            ? 'قبول کریں اور جاری رکھیں'
                                            : 'Accept and Continue',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: isUrdu ? 0.0 : 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isUrdu
                          ? 'جاری رکھ کر آپ اسلامی اور اخلاقی ضوابط سے اتفاق کرتے ہیں'
                          : 'By continuing, you agree to our spiritual & community guidelines',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 10,
                          color: const Color(0xFF64748B),
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
    );
  }

  Widget _buildTermsContent(bool isUrdu, String fontFamily) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Text(
            isUrdu
                ? 'نورِ سنت کے استعمال پر آپ ان شرائط سے متفق ہوتے ہیں۔ تمام مواد خالصتاً دینی تعلیم و روحانی تربیت کے لیے ہے۔'
                : 'By using NOOR E SUNNAT, you agree to these spiritual usage terms. All content provided is for religious education and personal spiritual development.',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12.5,
              color: const Color(0xFF1E293B),
              height: isUrdu ? 1.5 : 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 1. Authenticity Clause (Updated Requirement)
        _buildPointCard(
          icon: Icons.verified_rounded,
          iconColor: AppColors.primaryEmerald,
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          title: isUrdu ? 'مستند کتب و علماء کی تصدیق:' : 'Authentic Sources & Scholarly Review:',
          body: isUrdu
              ? 'ہماری اسلامی ریسرچ ٹیم اسلامی مواد مستند اسلامی کتب اور ذرائع سے حاصل کرتی ہے اور اسے علماء کرام سے چیک کرواتی ہے۔'
              : 'Our Islamic research team takes Islamic content from authentic Islamic books and sources and has it reviewed by Islamic scholars.',
          isUrdu: isUrdu,
          fontFamily: fontFamily,
        ),
        const SizedBox(height: 10),

        // 2. Disclaimer / Content Accuracy Clause (Updated Requirement)
        _buildPointCard(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
          title: isUrdu ? 'مواد کی صحت اور وضاحتی نوٹ:' : 'Content Accuracy Disclaimer:',
          body: isUrdu
              ? 'ہماری بھرپور کوشش کے باوجود مواد میں کبھی کبھار متن یا معلومات کی معمولی غلطی ہو سکتی ہے۔'
              : 'Despite our efforts, there may be occasional errors in the content, such as text or data mistakes.',
          isUrdu: isUrdu,
          fontFamily: fontFamily,
        ),
        const SizedBox(height: 10),

        // 3. Respect & Etiquette
        _buildPointCard(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE11D48),
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          title: isUrdu ? 'اسلامی آداب و احترام:' : 'Respect & Etiquette:',
          body: isUrdu
              ? 'دینی سوالات پوچھتے وقت اور ایپ استعمال کرتے وقت اسلامی آداب کا خیال رکھنا لازم ہے۔'
              : 'Users must maintain Islamic respect and etiquette when submitting religious questions and engaging with content.',
          isUrdu: isUrdu,
          fontFamily: fontFamily,
        ),
      ],
    );
  }

  Widget _buildPrivacyContent(bool isUrdu, String fontFamily) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            isUrdu
                ? 'ہم آپ کے ذاتی ڈیٹا کے مکمل تحفظ کے پابند ہیں اور شفاف طریقے سے کام کرتے ہیں:'
                : 'Your privacy is of utmost importance to us. We adhere to transparent data practices:',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12.5,
              color: const Color(0xFF1E293B),
              height: isUrdu ? 1.5 : 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 1. Data Ownership
        _buildPointCard(
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          title: isUrdu ? 'ڈیٹا کی ملکیت:' : 'Data Ownership:',
          body: isUrdu
              ? 'آپ کا درود کاؤنٹ اور اسٹریک آپ کے اکاؤنٹ سے محفوظ منسلک رہتا ہے۔'
              : 'Your recitation counts and streak records are securely linked to your account.',
          isUrdu: isUrdu,
          fontFamily: fontFamily,
        ),
        const SizedBox(height: 10),

        // 2. No Third-Party Selling
        _buildPointCard(
          icon: Icons.block_rounded,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          title: isUrdu ? 'کوئی کمرشل فروخت نہیں:' : 'No Third-Party Selling:',
          body: isUrdu
              ? 'ہم آپ کا ڈیٹا کسی تیسرے فریق کو فروخت یا مارکیٹنگ کے لیے استعمال نہیں کرتے۔'
              : 'We never sell, monetize, or track your personal information for advertising.',
          isUrdu: isUrdu,
          fontFamily: fontFamily,
        ),
        const SizedBox(height: 10),

        // 3. Security & Encryption
        _buildPointCard(
          icon: Icons.lock_outline_rounded,
          iconColor: AppColors.primaryEmerald,
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          title: isUrdu ? 'سیکیورٹی اور انکرپشن:' : 'Security & Encryption:',
          body: isUrdu
              ? 'تمام ڈیٹا کلاؤڈ پر انکرپٹڈ محفوظ پروٹوکول کے ذریعے منتقل کیا جاتا ہے۔'
              : 'All communications with Firebase cloud services are encrypted via modern TLS/SSL protocols.',
          isUrdu: isUrdu,
          fontFamily: fontFamily,
        ),
      ],
    );
  }

  Widget _buildPointCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String body,
    required bool isUrdu,
    required String fontFamily,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: isUrdu ? 0.0 : 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12,
                    height: isUrdu ? 1.5 : 1.35,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

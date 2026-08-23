import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/campaign_popup_model.dart';
import '../../main.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/counter/presentation/counter_screen.dart';
import '../../features/knowledge_hub/presentation/aqaid_grid.dart';
import '../../features/knowledge_hub/presentation/masail_grid.dart';
import '../../features/knowledge_hub/presentation/qa_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../services/counter_service.dart';

class CampaignPopupDialog extends StatelessWidget {
  final CampaignPopupModel config;
  final bool isPreview;

  const CampaignPopupDialog({
    super.key,
    required this.config,
    this.isPreview = false,
  });

  /// Static helper to trigger the dialog with smooth scale and fade transition
  static Future<void> show(BuildContext context, CampaignPopupModel config) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Campaign Popup',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return CampaignPopupDialog(config: config);
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

  void _handleActionClick(BuildContext context) {
    if (isPreview) return;

    // First dismiss dialog
    Navigator.of(context, rootNavigator: true).pop();

    final target = config.targetRoute.toLowerCase().trim();

    if (target.contains('event')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpcomingEventsScreen()),
      );
    } else if (target.contains('counter') || target.contains('durood')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CounterScreen(counterService: CounterService()),
        ),
      );
    } else if (target.contains('aqaid')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AqaidGridScreen()),
      );
    } else if (target.contains('masail')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MasailGridScreen()),
      );
    } else if (target.contains('qa') || target.contains('question')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QAScreen()),
      );
    } else if (target.contains('profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(counterService: CounterService()),
        ),
      );
    } else if (target == '/home' || target == 'home') {
      // Already on home, no-op
    } else {
      // Attempt generic named route navigation if defined
      try {
        Navigator.of(context).pushNamed(config.targetRoute);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final isUrdu = globalLanguageProvider.isUrdu;
        final title = config.getTitle(isUrdu);
        final details = config.getDetails(isUrdu);
        final buttonText = config.getButtonText(isUrdu);

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isPreview ? double.infinity : 340,
              constraints: const BoxConstraints(maxWidth: 360),
              margin: EdgeInsets.symmetric(
                horizontal: isPreview ? 0 : 24,
                vertical: isPreview ? 0 : 20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF063B26), // Deep rich Islamic Green
                    Color(0xFF094E32), // Vibrant Emerald Green
                    Color(0xFF052B1B), // Dark Midnight Green base
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 28,
                    spreadRadius: 4,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Directionality(
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                child: Stack(
                  children: [
                    // Background Hanging Lanterns Ornaments
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LanternsDecorationPainter(),
                      ),
                    ),

                    // Main Content Column
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top Dismiss Button ('X' inside white circle)
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (!isPreview) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                  }
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF1E293B),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Campaign Title
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                fontFamily: isUrdu
                                    ? AppTypography.urduFontFamily
                                    : AppTypography.englishFontFamily,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campaign Details / Subtitle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                details,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: isUrdu ? 15 : 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                  fontFamily: isUrdu
                                      ? AppTypography.urduFontFamily
                                      : AppTypography.englishFontFamily,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Action CTA Button ("Get Started" / "شروع کریں")
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A017), // Rich Royal Gold
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: Colors.black45,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onPressed: () => _handleActionClick(context),
                                child: Text(
                                  buttonText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontFamily: isUrdu
                                        ? AppTypography.urduFontFamily
                                        : AppTypography.englishFontFamily,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bottom Image Artwork
                            _buildBottomGraphic(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomGraphic(BuildContext context) {
    final imageType = config.imageType;
    final imageUrl = config.imageUrl;
    final imageBase64 = config.imageBase64;

    // 1. Base64 Image
    if (imageType == CampaignPopupModel.imageTypeBase64 &&
        imageBase64 != null &&
        imageBase64.trim().isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64.trim());
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            bytes,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultGraphicBanner(),
          ),
        );
      } catch (_) {
        return _buildDefaultGraphicBanner();
      }
    }

    // 2. Network Image URL
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl.trim(),
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentGold,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildDefaultGraphicBanner(),
        ),
      );
    }

    // 3. High Quality Default Spiritual Graphic Banner
    return _buildDefaultGraphicBanner();
  }

  Widget _buildDefaultGraphicBanner() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Masjid Nabawi background asset
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/masjid_nabawi_header.jpeg',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          // Dark glass gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF063B26).withValues(alpha: 0.3),
                  const Color(0xFF094E32).withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Center Gumbad & Spiritual Embellishment
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFFFDE047),
                  size: 42,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'صلوات و سلام',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw decorative hanging Islamic lanterns on the card's top left & right
class _LanternsDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final stringPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    // Left Lantern
    _drawLantern(canvas, 32, 110, stringPaint, goldPaint, glowPaint);
    // Far Left Small Lantern
    _drawLantern(canvas, 10, 80, stringPaint, goldPaint, glowPaint, scale: 0.7);

    // Right Lantern
    _drawLantern(canvas, size.width - 32, 110, stringPaint, goldPaint, glowPaint);
    // Far Right Small Lantern
    _drawLantern(canvas, size.width - 10, 80, stringPaint, goldPaint, glowPaint, scale: 0.7);
  }

  void _drawLantern(
    Canvas canvas,
    double cx,
    double bottomY,
    Paint stringPaint,
    Paint goldPaint,
    Paint glowPaint, {
    double scale = 1.0,
  }) {
    final topY = 0.0;
    final lanternHeight = 36.0 * scale;
    final lanternWidth = 20.0 * scale;
    final startY = bottomY - lanternHeight;

    // Hanging string
    canvas.drawLine(Offset(cx, topY), Offset(cx, startY), stringPaint);

    // Top cap
    final capPath = Path();
    capPath.moveTo(cx - (lanternWidth * 0.4), startY + 4 * scale);
    capPath.lineTo(cx, startY);
    capPath.lineTo(cx + (lanternWidth * 0.4), startY + 4 * scale);
    capPath.close();
    canvas.drawPath(capPath, goldPaint);

    // Main body (hexagon lantern)
    final bodyPath = Path();
    bodyPath.moveTo(cx - (lanternWidth * 0.5), startY + 6 * scale);
    bodyPath.lineTo(cx + (lanternWidth * 0.5), startY + 6 * scale);
    bodyPath.lineTo(cx + (lanternWidth * 0.35), startY + lanternHeight - 6 * scale);
    bodyPath.lineTo(cx - (lanternWidth * 0.35), startY + lanternHeight - 6 * scale);
    bodyPath.close();

    canvas.drawPath(bodyPath, goldPaint);

    // Center glow
    final glowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, startY + (lanternHeight / 2)),
        width: lanternWidth * 0.5,
        height: lanternHeight * 0.45,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(glowRect, glowPaint);

    // Bottom finial / tassel
    final tasselPath = Path();
    tasselPath.moveTo(cx - 3 * scale, startY + lanternHeight - 4 * scale);
    tasselPath.lineTo(cx, startY + lanternHeight);
    tasselPath.lineTo(cx + 3 * scale, startY + lanternHeight - 4 * scale);
    tasselPath.close();
    canvas.drawPath(tasselPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

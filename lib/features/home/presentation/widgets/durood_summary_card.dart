import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../main.dart';
import '../../../../services/counter_service.dart';

class DuroodSummaryCard extends StatelessWidget {
  final CounterService counterService;
  final VoidCallback onSendSalawat;
  final CounterSnapshot? snapshot;
  final int? globalTotal;
  final int? todayTotal;
  final int? myToday;
  final int? myTotal;
  final bool isLoggedIn;

  const DuroodSummaryCard({
    super.key,
    required this.counterService,
    required this.onSendSalawat,
    this.snapshot,
    this.globalTotal,
    this.todayTotal,
    this.myToday,
    this.myTotal,
    this.isLoggedIn = true,
  });

  String _formatCount(int value) {
    if (value >= 100000000) {
      return NumberFormatter.formatCompact(value);
    }
    return NumberFormatter.formatWithCommas(value);
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final currentSnap = snapshot ?? counterService.snapshot;
    final effectiveGlobalTotal = globalTotal != null
        ? math.max(currentSnap.globalTotal, globalTotal!)
        : currentSnap.globalTotal;
    final effectiveTodayTotal = todayTotal != null
        ? math.max(currentSnap.globalToday, todayTotal!)
        : currentSnap.globalToday;
    final effectiveMyToday = isLoggedIn
        ? (myToday != null ? math.max(currentSnap.personalToday, myToday!) : currentSnap.personalToday)
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEF08A), // Light Sunshine Yellow
            Color(0xFFFDE047), // Vibrant Light Gold
            Color(0xFFEAB308), // Warm Honey Amber
          ],
          stops: [0.0, 0.50, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFCA8A04).withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.50),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSendSalawat,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 1. Authentic Islamic Geometric Light Yellow Pattern Background (Old 6-star pic removed)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.40,
                    child: Image.asset(
                      'assets/images/durood_pattern_bg.jpeg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // 2. Soft Vignette Overlay for High Typography Contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.16),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // 3. Card Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row: "Durood Count" + "Live Updates" badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              lp.tr('durood_count_summary'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: lp.isUrdu ? 0 : 0.2,
                                fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : null,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x55000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.40),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.0,
                                  height: 7.0,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF22C55E),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5.5),
                                Text(
                                  lp.tr('live_updates'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: lp.isUrdu ? 0 : 0.3,
                                    fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : null,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x40000000),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Two-column metrics row: GLOBAL TOTAL & MY TODAY (separated by vertical line)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Global Total
                          Expanded(
                            child: _buildMetricColumn(
                              icon: Icons.public_rounded,
                              label: lp.tr('global_total'),
                              value: _formatCount(effectiveGlobalTotal),
                              isUrdu: lp.isUrdu,
                            ),
                          ),

                          // Center Vertical Divider
                          Container(
                            width: 1,
                            height: 42,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),

                          // Right: My Today (or Global Today if guest)
                          Expanded(
                            child: _buildMetricColumn(
                              icon: Icons.calendar_today_rounded,
                              label: effectiveMyToday != null ? lp.tr('my_today') : lp.tr('global_today'),
                              value: _formatCount(effectiveMyToday ?? effectiveTodayTotal),
                              isUrdu: lp.isUrdu,
                            ),
                          ),
                        ],
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

  Widget _buildMetricColumn({
    required IconData icon,
    required String label,
    required String value,
    required bool isUrdu,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            const SizedBox(width: 5.5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: isUrdu ? 0 : 0.5,
                    fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
                    shadows: const [
                      Shadow(
                        color: Color(0x40000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: const TextStyle(
                fontSize: 27.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
                shadows: [
                  Shadow(
                    color: Color(0x45000000),
                    blurRadius: 5,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

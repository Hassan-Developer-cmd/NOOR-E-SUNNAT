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

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final currentSnap = snapshot ?? counterService.snapshot;
    final effectiveGlobalTotal = globalTotal != null ? math.max(currentSnap.globalTotal, globalTotal!) : currentSnap.globalTotal;
    final effectiveTodayTotal = todayTotal != null ? math.max(currentSnap.globalToday, todayTotal!) : currentSnap.globalToday;
    final effectiveMyToday = isLoggedIn
        ? (myToday != null ? math.max(currentSnap.personalToday, myToday!) : currentSnap.personalToday)
        : null;
    final effectiveMyTotal = isLoggedIn
        ? (myTotal != null ? math.max(currentSnap.personalTotal, myTotal!) : currentSnap.personalTotal)
        : null;

    // High-contrast typography palette tailored for rich golden background
    const Color brandTitleColor = Color(0xFF451A03); // Deep rich espresso / amber-brown
    const Color brandLabelColor = Color(0xFF78350F); // Warm deep bronze / amber
    const Color brandValueColor = Color(0xFF451A03); // Prominent bold neutral espresso
    const Color brandDividerColor = Color(0x3378350F); // 20% opacity warm divider

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEF08A), // Sunny Warm Golden Yellow
            Color(0xFFFACC15), // Vibrant Canary Gold
            Color(0xFFEAB308), // Rich Deep Golden Amber
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF78350F).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFEAB308).withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFB45309).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. Islamic Geometric Light Yellow Pattern Background (subtle watermark)
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/durood_pattern_bg.jpeg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // 2. Inner Vignette / Soft Shadow for Enhanced Contrast & Definition
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.transparent,
                      const Color(0xFF78350F).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lp.tr('durood_count_summary'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: brandTitleColor,
                            letterSpacing: lp.isUrdu ? 0 : 0.2,
                            fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF78350F).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF78350F).withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A), // Vibrant emerald green pulse dot
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF16A34A),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              lp.tr('live_updates'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF78350F),
                                letterSpacing: lp.isUrdu ? 0 : 0.4,
                                fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          label: lp.tr('global_total'),
                          value: NumberFormatter.formatCompact(effectiveGlobalTotal),
                          icon: Icons.public_rounded,
                          iconColor: brandLabelColor,
                          labelColor: brandLabelColor,
                          valueColor: brandValueColor,
                          isUrdu: lp.isUrdu,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: brandDividerColor,
                      ),
                      Expanded(
                        child: _buildStat(
                          label: lp.tr('global_today'),
                          value: NumberFormatter.formatCompact(effectiveTodayTotal),
                          icon: Icons.today_rounded,
                          iconColor: brandLabelColor,
                          labelColor: brandLabelColor,
                          valueColor: brandValueColor,
                          isUrdu: lp.isUrdu,
                        ),
                      ),
                      if (isLoggedIn && effectiveMyTotal != null) ...[
                        Container(
                          width: 1,
                          height: 32,
                          color: brandDividerColor,
                        ),
                        Expanded(
                          child: _buildStat(
                            label: lp.tr('my_total'),
                            value: NumberFormatter.formatCompact(effectiveMyTotal),
                            icon: Icons.all_inclusive_rounded,
                            iconColor: brandLabelColor,
                            labelColor: brandLabelColor,
                            valueColor: brandValueColor,
                            isUrdu: lp.isUrdu,
                          ),
                        ),
                      ],
                      if (isLoggedIn && effectiveMyToday != null) ...[
                        Container(
                          width: 1,
                          height: 32,
                          color: brandDividerColor,
                        ),
                        Expanded(
                          child: _buildStat(
                            label: lp.tr('my_today'),
                            value: NumberFormatter.formatCompact(effectiveMyToday),
                            icon: Icons.timer_rounded,
                            iconColor: brandLabelColor,
                            labelColor: brandLabelColor,
                            valueColor: brandValueColor,
                            isUrdu: lp.isUrdu,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color labelColor,
    required Color valueColor,
    bool isUrdu = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.5, color: iconColor),
            const SizedBox(width: 4.5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: isUrdu ? 0 : 0.3,
                    fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
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
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.4,
                shadows: const [
                  Shadow(
                    color: Color(0x1F000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
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

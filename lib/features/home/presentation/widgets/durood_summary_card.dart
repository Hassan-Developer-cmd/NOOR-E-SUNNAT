import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../main.dart';
import '../../../../services/counter_service.dart';

class DuroodSummaryCard extends StatelessWidget {
  final CounterService counterService;
  final VoidCallback onSendSalawat;
  final CounterSnapshot? snapshot;
  final int? globalTotal;
  final int? todayTotal;

  const DuroodSummaryCard({
    super.key,
    required this.counterService,
    required this.onSendSalawat,
    this.snapshot,
    this.globalTotal,
    this.todayTotal,
  });

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final currentSnap = snapshot ?? counterService.snapshot;
    final effectiveGlobalTotal = globalTotal ?? currentSnap.globalTotal;
    final effectiveTodayTotal = todayTotal ?? currentSnap.globalToday;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFDE047), // Sunny Light Yellow
            Color(0xFFFACC15), // Vibrant Canary Yellow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. Islamic Geometric Light Yellow Pattern Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/durood_pattern_bg.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),

            // 2. Gentle Overlay for Maximum Readability on Light Yellow
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lp.tr('durood_count_summary'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80), // Neon green pulse dot
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF4ADE80),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              lp.tr('live_updates'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          lp.tr('global_total'),
                          NumberFormatter.formatCompact(effectiveGlobalTotal),
                          Icons.public_rounded,
                          Colors.white,
                          Colors.white,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      Expanded(
                        child: _buildStat(
                          lp.tr('global_today'),
                          NumberFormatter.formatCompact(effectiveTodayTotal),
                          Icons.today_rounded,
                          const Color(0xFFFFFBEB),
                          Colors.white,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      Expanded(
                        child: _buildStat(
                          lp.tr('my_today'),
                          NumberFormatter.formatCompact(currentSnap.personalToday),
                          Icons.timer_rounded,
                          const Color(0xFFFFFBEB),
                          Colors.white,
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
    );
  }

  Widget _buildStat(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color valueColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFFBEB), // Soft warm cream white
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
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
        const SizedBox(height: 2),
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.3,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
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

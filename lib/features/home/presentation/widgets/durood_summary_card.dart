import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../main.dart';
import '../../../../services/counter_service.dart';

class DuroodSummaryCard extends StatelessWidget {
  final CounterService counterService;
  final VoidCallback onSendSalawat;

  const DuroodSummaryCard({
    super.key,
    required this.counterService,
    required this.onSendSalawat,
  });

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B), // Deep Emerald Green
            Color(0xFF0B5D44), // Rich Islamic Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. Islamic Geometric Pattern Background
            Positioned.fill(
              child: Opacity(
                opacity: 0.38,
                child: Image.asset(
                  'assets/images/durood_pattern_bg.jpeg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // 2. Subtle Dark Gradient Overlay for Maximum Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.38),
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
                                color: Colors.black54,
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
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentGold.withValues(alpha: 0.55),
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
                                color: AppColors.goldBright,
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
                          _fmt(counterService.snapshot.globalTotal),
                          Icons.public_rounded,
                          AppColors.goldBright,
                          Colors.white,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildStat(
                          lp.tr('my_today'),
                          _fmt(counterService.snapshot.personalToday),
                          Icons.today_rounded,
                          AppColors.goldBright,
                          AppColors.goldBright,
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
                    color: Color(0xFFD1FAE5), // Mint tinted soft white
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
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
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

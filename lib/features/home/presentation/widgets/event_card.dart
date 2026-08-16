import 'package:flutter/material.dart';
import '../../../../core/models/event_model.dart';
import '../../../../main.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final double? width;
  final VoidCallback? onNextTap;

  const EventCard({
    super.key,
    required this.event,
    this.width,
    this.onNextTap,
  });

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final title = isUrdu
        ? (event.titleUr.isNotEmpty ? event.titleUr : event.title)
        : event.title;

    final primaryColor = event.gradientColors.isNotEmpty
        ? event.gradientColors.first
        : const Color(0xFF0F766E);
    final secondaryColor = event.gradientColors.length > 1
        ? event.gradientColors[1]
        : primaryColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Status Badge & Next Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      event.getStatusLabel(isUrdu),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (onNextTap != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onNextTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isUrdu ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Constrained Event Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // DateTime & Location Row
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      text: event.dateTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.location_on_rounded,
                      text: event.getLocation(isUrdu),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

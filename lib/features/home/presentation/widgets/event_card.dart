import 'package:flutter/material.dart';
import '../../../../core/models/event_model.dart';
import '../../../../main.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;
        final title = event.getTitle(isUrdu);
        final location = event.getLocation(isUrdu);
        final statusLabel = event.getStatusLabel(isUrdu);

        final primaryColor = event.gradientColors.isNotEmpty
            ? event.gradientColors.first
            : const Color(0xFF0F766E);
        final secondaryColor = event.gradientColors.length > 1
            ? event.gradientColors[1]
            : primaryColor;

        final isLive = event.status.toLowerCase() == 'ongoing';

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: double.infinity,
                height: 175,
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
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Status badge & Action icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              key: ValueKey('status_${event.id}_${lp.locale.languageCode}'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUrdu
                                  ? Icons.arrow_back_ios_new_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ],
                      ),

                      // Middle row: Event Title
                      Text(
                        title,
                        key: ValueKey('title_${event.id}_${lp.locale.languageCode}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: isUrdu ? 'UrduFont' : null,
                          height: 1.25,
                        ),
                      ),

                      // Bottom row: Date/Time and Location / Live Stream info
                      Row(
                        children: [
                          // Date/Time
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.dateTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Location / Live Stream
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLive
                                      ? Icons.sensors_rounded
                                      : Icons.location_on_rounded,
                                  size: 15,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location,
                                    key: ValueKey('loc_${event.id}_${lp.locale.languageCode}'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

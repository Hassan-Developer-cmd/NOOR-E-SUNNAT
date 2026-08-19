import 'package:flutter/material.dart';
import '../../../../core/models/event_model.dart';
import '../../../../main.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final double? width;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.width,
  });

  /// Maps event keywords to themed high-resolution Islamic background assets
  static String getThemedEventImage(String title, [String description = '']) {
    final combined = '$title $description'.toLowerCase();

    // 1. Global Milad Gathering / Milad un Nabi Events
    if (combined.contains('milad') ||
        combined.contains('mawlid') ||
        combined.contains('prophet') ||
        combined.contains('gathering') ||
        combined.contains('میلاد') ||
        combined.contains('نبی') ||
        combined.contains('محفل')) {
      return 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?q=80&w=800&auto=format&fit=crop';
    }

    // 2. Ramadan / Ramzan / Fasting Events
    if (combined.contains('ramadan') ||
        combined.contains('ramzan') ||
        combined.contains('fasting') ||
        combined.contains('iftar') ||
        combined.contains('sehri') ||
        combined.contains('رمضان') ||
        combined.contains('افطار') ||
        combined.contains('سحری') ||
        combined.contains('روزہ')) {
      return 'https://images.unsplash.com/photo-1564769625905-50e93615e769?q=80&w=800&auto=format&fit=crop';
    }

    // 3. Weekly Jumu'ah Durood / Friday Events
    if (combined.contains('jumu') ||
        combined.contains('friday') ||
        combined.contains('durood') ||
        combined.contains('salawat') ||
        combined.contains('جمعہ') ||
        combined.contains('درود') ||
        combined.contains('صلوۃ')) {
      return 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?q=80&w=800&auto=format&fit=crop';
    }

    // 4. Default / Fallback Islamic Architecture
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=800&auto=format&fit=crop';
  }

  Widget _buildEventBadge(
    String label,
    bool isLive,
    String langCode,
    String eventId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? const Color(0xFFDC2626).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        label,
        key: ValueKey('status_${eventId}_$langCode'),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

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
        final isLive = event.status.toLowerCase() == 'ongoing';

        final cardWidth = width ??
            (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 340.0);

        final imageUrl = (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty)
            ? event.imageUrl!.trim()
            : getThemedEventImage(
                '${event.title} ${event.titleUr}',
                '${event.description} ${event.descriptionUr}',
              );

        return SizedBox(
          width: cardWidth,
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. High-Resolution Islamic / Custom Admin Background Image
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF064E3B),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.6),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Image.network(
                      getThemedEventImage(
                        '${event.title} ${event.titleUr}',
                        '${event.description} ${event.descriptionUr}',
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Premium Dual-Tone Gradient Overlay for Crisp Readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Card Content (Badges, Title, Date, Location)
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Badge & Arrow Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildEventBadge(
                            statusLabel,
                            isLive,
                            lp.locale.languageCode,
                            event.id,
                          ),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white.withValues(alpha: 0.24),
                            child: Icon(
                              isUrdu
                                  ? Icons.arrow_back_ios_new_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Title with Text Shadow for Maximum Contrast
                      Text(
                        title,
                        key: ValueKey('title_${event.id}_${lp.locale.languageCode}'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: isUrdu ? 'UrduFont' : null,
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 5,
                              offset: Offset(0, 1.5),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Footer Date & Location Info
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.dateTime,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLive
                                ? Icons.sensors_rounded
                                : Icons.location_on_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              key: ValueKey('loc_${event.id}_${lp.locale.languageCode}'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Ripple Action Layer
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withValues(alpha: 0.15),
                      highlightColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

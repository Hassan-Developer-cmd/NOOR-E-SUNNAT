import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/models/event_model.dart';
import '../../../../main.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.width,
    this.height,
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
        combined.contains('سیرت') ||
        combined.contains('محفل')) {
      return 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80';
    }

    // 2. Shab-e-Barat / Shab-e-Meraj Night Vigil Events
    if (combined.contains('night') ||
        combined.contains('vigil') ||
        combined.contains('shab') ||
        combined.contains('meraj') ||
        combined.contains('barat') ||
        combined.contains('معراج') ||
        combined.contains('برات')) {
      return 'https://images.unsplash.com/photo-1519817650390-64a93db51149?auto=format&fit=crop&w=800&q=80';
    }

    // 3. Ramadan / Itikaf / Khatam-ul-Quran
    if (combined.contains('ramadan') ||
        combined.contains('itikaf') ||
        combined.contains('quran') ||
        combined.contains('fasting') ||
        combined.contains('رمضان') ||
        combined.contains('اعتکاف') ||
        combined.contains('قرآن')) {
      return 'https://images.unsplash.com/photo-1564769625905-50e93615e769?auto=format&fit=crop&w=800&q=80';
    }

    // 4. Jumu'ah Mubarak / Weekly Gathering
    if (combined.contains('jummah') ||
        combined.contains('friday') ||
        combined.contains('weekly') ||
        combined.contains('جمعہ')) {
      return 'https://images.unsplash.com/photo-1564769625624-9195d82088f1?auto=format&fit=crop&w=800&q=80';
    }

    // 5. Durood Sharif / Salawat Mehfil
    if (combined.contains('durood') ||
        combined.contains('salawat') ||
        combined.contains('salat') ||
        combined.contains('درود') ||
        combined.contains('سلام')) {
      return 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=800&q=80';
    }

    // Default Atmospheric Green Islamic Lanterns Architecture
    return 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?auto=format&fit=crop&w=800&q=80';
  }

  static Widget _buildFallbackImage(EventModel event) {
    return Image.network(
      getThemedEventImage(
        '${event.title} ${event.titleUr}',
        '${event.description} ${event.descriptionUr}',
      ),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildEventBackground(EventModel event) {
    // 1. Local Device Uploaded Base64 Image
    if (event.imageBase64 != null && event.imageBase64!.trim().isNotEmpty) {
      try {
        final bytes = base64Decode(event.imageBase64!.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(event),
        );
      } catch (_) {
        return _buildFallbackImage(event);
      }
    }

    // 2. Direct Web Image URL
    if (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty) {
      return Image.network(
        event.imageUrl!.trim(),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF0F3E2E),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(event),
      );
    }

    // 3. Fallback Themed Image
    return _buildFallbackImage(event);
  }

  Widget _buildEventBadge(
    String label,
    bool isLive,
    String langCode,
    String eventId,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
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
            (MediaQuery.of(context).size.width * 0.88).clamp(280.0, 360.0);
        final cardHeight = height ?? 150.0;

        return Directionality(
          textDirection: lp.textDirection,
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // 1. High-Resolution Islamic / Custom Base64 / URL Background Image
                  Positioned.fill(
                    child: _buildEventBackground(event),
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
                            Colors.black.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Card Content (Badges, Title, Date, Location)
                  Padding(
                    padding: const EdgeInsetsDirectional.all(12.0),
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
                              radius: 12,
                              backgroundColor: Colors.white.withValues(alpha: 0.24),
                              child: Icon(
                                isUrdu
                                    ? Icons.arrow_back_ios_new_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                size: 10,
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: isUrdu ? 'UrduFont' : null,
                            height: 1.25,
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
                        const SizedBox(height: 6),

                        // Footer Date & Location Info
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11.5,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.dateTime,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
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
                              size: 11.5,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                key: ValueKey('loc_${event.id}_${lp.locale.languageCode}'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
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
          ),
        );
      },
    );
  }
}

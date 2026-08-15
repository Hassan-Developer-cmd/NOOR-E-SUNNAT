import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../main.dart';
import '../../../../services/notification_service.dart';
import '../../../events/presentation/events_screen.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    NotificationService.markAllAsRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primaryEmerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isUrdu ? 'اعلانات و اطلاعات' : 'Notifications',
                      style: AppTypography.headingMedium.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    await NotificationService.markAllAsRead();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isUrdu ? 'تمام پیغامات پڑھ لیے گئے ہیں' : 'All marked as read'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primaryEmerald),
                  label: Text(
                    isUrdu ? 'سب پڑھا ہوا نشان زد کریں' : 'Mark all read',
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryEmerald, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Notifications List
          Expanded(
            child: StreamBuilder<List<InAppNotificationItem>>(
              stream: NotificationService.notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldContainer.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 40,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isUrdu ? 'فی الحال کوئی نیا اعلان نہیں ہے' : 'No notifications yet',
                            style: AppTypography.headingMedium.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isUrdu ? 'ایونٹس اور اپ ڈیٹس کے اعلانات یہاں ظاہر ہوں گے۔' : 'Event announcements and updates will appear here.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {

                    final item = items[index];
                    return _NotificationTile(item: item, isUrdu: isUrdu);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final InAppNotificationItem item;
  final bool isUrdu;

  const _NotificationTile({required this.item, required this.isUrdu});

  IconData get _icon {
    switch (item.type) {
      case 'event_announcement':
        return Icons.campaign_rounded;
      case 'event_update':
        return Icons.star_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case 'event_announcement':
        return const Color(0xFF0284C7);
      case 'event_update':
        return AppColors.accentGold;
      default:
        return AppColors.primaryEmerald;
    }
  }

  Color get _iconBg {
    switch (item.type) {
      case 'event_announcement':
        return const Color(0xFFE0F2FE);
      case 'event_update':
        return AppColors.goldLight;
      default:
        return AppColors.emeraldContainer;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isUrdu ? 'ابھی' : 'Just now';
    if (diff.inMinutes < 60) return isUrdu ? '${diff.inMinutes} منٹ پہلے' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isUrdu ? '${diff.inHours} گھنٹے پہلے' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isUrdu ? '${diff.inDays} دن پہلے' : '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = item.getTitle(isUrdu);
    final body = item.getBody(isUrdu);
    final isEvent = item.eventId != null || item.type.startsWith('event_');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isEvent) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpcomingEventsScreen()),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.sentAt != null)
                            Text(
                              _formatTime(item.sentAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      if (isEvent) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              isUrdu ? 'ایونٹ کی تفصیلات دیکھیں ←' : 'View event details →',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

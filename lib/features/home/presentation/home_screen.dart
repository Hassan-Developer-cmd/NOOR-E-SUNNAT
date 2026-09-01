import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/hijri_date_model.dart';
import '../../../core/utils/islamic_date_helper.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';
import '../../../services/counter_service.dart';
import '../../../services/events_service.dart';
import '../../../services/campaign_popup_service.dart';
import '../../events/presentation/events_screen.dart';
import 'widgets/event_card.dart';
import 'widgets/durood_summary_card.dart';
import 'widgets/gamification_bar.dart';
import 'widgets/hadith_wisdom_card.dart';
import 'widgets/notifications_sheet.dart';
import '../../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final CounterService counterService;
  final VoidCallback onNavigateToCounter;

  const HomeScreen({
    super.key,
    required this.counterService,
    required this.onNavigateToCounter,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CampaignPopupService.checkAndShowStartupPopup(context, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final firebaseUser = FirebaseAuth.instance.currentUser;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: CustomScrollView(
            slivers: [
              // ── Premium App Bar / Header ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 142,
                pinned: true,
                backgroundColor: AppColors.primaryEmerald,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Deep Emerald Base Gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF064E3B), // Deep Emerald
                              Color(0xFF0B5D44), // Rich Islamic Green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // 2. Spiritual Masjid an-Nabawi Asset Background with Soft Light Overlay
                      Opacity(
                        opacity: 0.28,
                        child: Image.asset(
                          'assets/images/masjid_nabawi_header.jpeg',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),

                      // 3. Subtle Dark Gradient Overlay for Maximum Text & Icon Crispness
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // 3. User Welcome Greeting & Dynamic Hijri Date Badge
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 10,
                        child: StreamBuilder<AppUser?>(
                          stream: AuthService.currentUserStream,
                          builder: (context, userSnap) {
                            final appUser = userSnap.data;
                            final liveDisplayName = (appUser?.username != null && appUser!.username.isNotEmpty)
                                ? appUser.username
                                : (firebaseUser?.displayName ?? lp.tr('guest'));
                            final livePhotoUrl = (appUser?.photoUrl != null && appUser!.photoUrl.isNotEmpty)
                                ? appUser.photoUrl
                                : firebaseUser?.photoURL;
                            final liveBase64 = appUser?.profileImageBase64;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Dynamic Localized Hijri Date Badge
                                      StreamBuilder<int>(
                                        stream: IslamicDateHelper.hijriOffsetStream,
                                        builder: (context, offsetSnap) {
                                          final offset = offsetSnap.data ?? 0;
                                          return FutureBuilder<HijriDateModel>(
                                            future: IslamicDateHelper.getHijriDate(dayOffset: offset),
                                            initialData: IslamicDateHelper.calculateOfflineHijriDate(
                                              DateTime.now().add(Duration(days: offset)),
                                            ),
                                            builder: (context, dateSnap) {
                                              final hijriDate = dateSnap.data ??
                                                  IslamicDateHelper.calculateOfflineHijriDate(
                                                    DateTime.now().add(Duration(days: offset)),
                                                  );
                                              final dateText = hijriDate.getFormatted(lp.isUrdu);

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.28),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: AppColors.accentGold.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.25),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.nightlight_round,
                                                      color: AppColors.goldBright,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      dateText,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: lp.isUrdu ? 12 : 11,
                                                        fontWeight: FontWeight.w600,
                                                        fontFamily: lp.isUrdu
                                                            ? AppTypography.urduFontFamily
                                                            : AppTypography.englishFontFamily,
                                                        letterSpacing: lp.isUrdu ? 0 : 0.3,
                                                        shadows: const [
                                                          Shadow(
                                                            color: Colors.black54,
                                                            blurRadius: 4,
                                                            offset: Offset(0, 1),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Text(
                                        lp.tr('welcome_greeting'),
                                        style: TextStyle(
                                          color: AppColors.goldBright,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        liveDisplayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Avatar
                                UserAvatar(
                                  radius: 20,
                                  profileImageBase64: liveBase64,
                                  photoUrl: livePhotoUrl,
                                  displayName: liveDisplayName,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Notification Bell with live unread badge
                  Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: NotificationService.unreadCountNotifier,
                      builder: (context, unreadCount, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => NotificationsSheet.show(context),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Language toggle
                  Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: GestureDetector(
                        onTap: () => lp.toggleLanguage(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            lp.isUrdu ? 'EN' : 'اردو',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

              ),

              // ── Content ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Gamification Row & Durood Summary Card wrapped with StreamBuilder for live launch streaming
                    StreamBuilder<CounterSnapshot>(
                      stream: widget.counterService.snapshotStream,
                      initialData: widget.counterService.snapshot,
                      builder: (context, snapshot) {
                        final snap = snapshot.data ?? widget.counterService.snapshot;
                        return Column(
                          children: [
                            GamificationBar(
                              streakDays: snap.currentStreak,
                              duroodPoints: snap.duroodPoints,
                            ),
                            const SizedBox(height: 10),
                            DuroodSummaryCard(
                              counterService: widget.counterService,
                              onSendSalawat: widget.onNavigateToCounter,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Send Salawat CTA
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 44),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: widget.onNavigateToCounter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  lp.tr('send_salawat_now'),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: Colors.white,
                                    fontFamily: lp.isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                                  ),
                                  strutStyle: const StrutStyle(
                                    forceStrutHeight: true,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Upgraded Responsive PageView Events Section with Dynamic Dots & Arrow Nav
                    const _UpcomingEventsSection(),
                    const SizedBox(height: 14),

                    // Hadith Card
                    const HadithWisdomCard(),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection();

  Widget _buildDirectEventCard(BuildContext context, EventModel event, String languageCode) {
    return EventCard(
      key: ValueKey('event_card_${event.id}_$languageCode'),
      event: event,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UpcomingEventsScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final languageCode = lp.locale.languageCode;

        return StreamBuilder<List<EventModel>>(
          stream: EventsService.eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  lp.tr('no_upcoming_events'),
                  style: AppTypography.bodyMedium,
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryEmerald,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  lp.tr('no_upcoming_events'),
                  style: AppTypography.bodyMedium,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lp.tr('upcoming_events'),
                        key: ValueKey('upcoming_events_title_$languageCode'),
                        style: AppTypography.headingMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpcomingEventsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          lp.tr('view_all'),
                          key: ValueKey('view_all_link_$languageCode'),
                          style: const TextStyle(
                            color: AppColors.primaryEmerald,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bulletproof Horizontal Scrollable List
                SizedBox(
                  height: 165,
                  child: ListView.separated(
                    key: ValueKey('events_listview_$languageCode'),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemCount: events.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildDirectEventCard(context, event, languageCode);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

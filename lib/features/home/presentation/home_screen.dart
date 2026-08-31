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
        CampaignPopupService.checkAndShowStartupPopup(context);
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
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Compact Premium App Bar / Header ─────────────────────────
              SliverAppBar(
                expandedHeight: 132,
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
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // 4. Compact User Welcome Greeting & Dynamic Hijri Date Badge
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
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.28),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: AppColors.accentGold.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.nightlight_round,
                                                      color: AppColors.goldBright,
                                                      size: 11.5,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      dateText,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: lp.isUrdu ? 11.5 : 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        fontFamily: lp.isUrdu
                                                            ? AppTypography.urduFontFamily
                                                            : AppTypography.englishFontFamily,
                                                        letterSpacing: lp.isUrdu ? 0 : 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            lp.tr('welcome_greeting'),
                                            style: const TextStyle(
                                              color: AppColors.goldBright,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              liveDisplayName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.bold,
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
                                const SizedBox(width: 10),
                                // Avatar
                                UserAvatar(
                                  radius: 19,
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            lp.isUrdu ? 'EN' : 'اردو',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Main Content (Optimized Above-The-Fold Viewport) ──────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Compact Live Durood & Gamification Hero Card
                    _CompactDuroodHero(
                      counterService: widget.counterService,
                      onSendSalawat: widget.onNavigateToCounter,
                    ),
                    const SizedBox(height: 14),

                    // 2. Prominent Upcoming Events Section (Directly Above The Fold)
                    const _UpcomingEventsSection(),
                    const SizedBox(height: 14),

                    // 3. Compact Daily Wisdom Card (Hadith / Ayat / Topic Switcher)
                    const HadithWisdomCard(),
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

/// Compact Live Durood & Gamification Hero Bar
class _CompactDuroodHero extends StatelessWidget {
  final CounterService counterService;
  final VoidCallback onSendSalawat;

  const _CompactDuroodHero({
    required this.counterService,
    required this.onSendSalawat,
  });

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    return StreamBuilder<CounterSnapshot>(
      stream: counterService.snapshotStream,
      initialData: counterService.snapshot,
      builder: (context, snapshot) {
        final snap = snapshot.data ?? counterService.snapshot;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Streak Pill | Points Pill | Live Pulse Badge
              Row(
                children: [
                  // Streak Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 12.5, color: Color(0xFFEA580C)),
                        const SizedBox(width: 3.5),
                        Text(
                          '${snap.currentStreak} ${lp.tr('streak_days')}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Points Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF5D77E)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12.5, color: AppColors.accentGold),
                        const SizedBox(width: 3.5),
                        Text(
                          '${snap.duroodPoints} ${isUrdu ? 'پوائنٹس' : 'Pts'}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF854D0E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Live Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          lp.tr('live_updates'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryEmerald,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bottom Row: Today Stat | Global Stat | Send Salawat CTA
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Personal Today Stat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lp.tr('my_today'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _fmt(snap.personalToday),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 26,
                    color: AppColors.borderLight,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),

                  // Global Stat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lp.tr('global_total'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _fmt(snap.globalTotal),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Salawat CTA Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onSendSalawat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lp.tr('send_salawat_now'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

/// Upgraded Responsive Horizontal PageView Events Section with Dots Indicator
class _UpcomingEventsSection extends StatefulWidget {
  const _UpcomingEventsSection();

  @override
  State<_UpcomingEventsSection> createState() => _UpcomingEventsSectionState();
}

class _UpcomingEventsSectionState extends State<_UpcomingEventsSection> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;
        final languageCode = lp.locale.languageCode;

        return StreamBuilder<List<EventModel>>(
          stream: EventsService.eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SizedBox.shrink();
            }

            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return Container(
                height: 145,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Center(
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
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_available_rounded, size: 18, color: AppColors.primaryEmerald),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lp.tr('no_upcoming_events'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3.5,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lp.tr('upcoming_events'),
                          key: ValueKey('upcoming_events_title_$languageCode'),
                          style: TextStyle(
                            fontSize: isUrdu ? 14.5 : 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            letterSpacing: isUrdu ? 0 : 0.2,
                          ),
                        ),
                      ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lp.tr('view_all'),
                              key: ValueKey('view_all_link_$languageCode'),
                              style: const TextStyle(
                                color: AppColors.primaryEmerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              isUrdu ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                              size: 15,
                              color: AppColors.primaryEmerald,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Horizontal PageView Carousel
                SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: events.length,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                    },
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: index == events.length - 1 ? 0 : 8,
                        ),
                        child: EventCard(
                          key: ValueKey('event_card_${event.id}_$languageCode'),
                          event: event,
                          height: 150,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpcomingEventsScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Smooth Page Indicator Dots (rendered when multiple events exist)
                if (events.length > 1) ...[
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(events.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 16 : 5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryEmerald
                              : AppColors.primaryEmerald.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

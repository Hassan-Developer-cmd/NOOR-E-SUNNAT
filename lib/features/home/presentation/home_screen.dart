import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/islamic_date_helper.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';
import '../../../services/counter_service.dart';
import '../../../services/events_service.dart';
import '../../../services/campaign_popup_service.dart';
import '../../../services/terms_acceptance_service.dart';
import '../../events/presentation/events_screen.dart';
import 'widgets/event_card.dart';
import 'widgets/durood_summary_card.dart';
import 'widgets/gamification_bar.dart';
import 'widgets/hadith_wisdom_card.dart';
import 'widgets/notifications_sheet.dart';
import '../../../services/notification_service.dart';
import '../../../core/utils/streak_helper.dart';

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
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStartupModals());
  }

  Future<void> _initStartupModals() async {
    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;

    try {
      // 1. Check and display blocking Terms & Conditions modal if not yet accepted
      await TermsAcceptanceService.checkAndShowTerms(context);

      if (!mounted) return;

      // 2. Check and display Campaign / Announcement popup if active
      await CampaignPopupService.checkAndShowStartupPopup(context);
    } catch (_) {
    } finally {
      if (mounted) {
        _isDialogShowing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final firebaseUser = FirebaseAuth.instance.currentUser;

        // Dynamic Viewport Fold Calculation: ensures Daily Hadith starts completely below the fold
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final bottomBarTotalHeight = kBottomNavigationBarHeight + mediaQuery.padding.bottom;
        final visibleViewportHeight = screenHeight - bottomBarTotalHeight;

        // Base content budget with un-squeezed components:
        // AppBar: ~144, Gamification: ~50, Durood: ~124, CTA: ~48, Events Header: ~38, Carousel: ~185 = ~589px
        const double baseContentBudget = 589.0;
        final double excessHeight = math.max(0.0, visibleViewportHeight - baseContentBudget);

        // Dynamically scale vertical spacing and heights to eliminate awkward dead space above the bottom navigation bar
        final double headerToStreakSpacing = (14.0 + (excessHeight * 0.12)).clamp(14.0, 22.0);
        final double streakToDuroodSpacing = (12.0 + (excessHeight * 0.10)).clamp(12.0, 18.0);
        final double duroodToCtaSpacing = (12.0 + (excessHeight * 0.10)).clamp(12.0, 18.0);
        final double ctaToEventsSpacing = (14.0 + (excessHeight * 0.12)).clamp(14.0, 22.0);
        final double eventCarouselHeight = (185.0 + (excessHeight * 0.16)).clamp(185.0, 205.0);
        final double appBarExpandedHeight = (142.0 + (excessHeight * 0.10)).clamp(142.0, 154.0);

        // Calculate total content height above the fold (down to bottom edge of Upcoming Events)
        final double aboveFoldTotalHeight = appBarExpandedHeight +
            headerToStreakSpacing +
            50.0 + // GamificationBar approx height
            streakToDuroodSpacing +
            124.0 + // DuroodSummaryCard approx height
            duroodToCtaSpacing +
            48.0 + // CTA Button height
            ctaToEventsSpacing +
            38.0 + // Events Header & spacing
            eventCarouselHeight;

        // Dynamic Fold Gap: Ensures Daily Hadith sits cleanly right below Upcoming Events,
        // starting strictly below the bottom navigation bar so 0% peeks on initial launch
        final double remainingToBottomBar = visibleViewportHeight - aboveFoldTotalHeight;
        final double foldGap = remainingToBottomBar > 0
            ? math.max(20.0, remainingToBottomBar + 12.0)
            : 24.0;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── Premium App Bar / Header ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: appBarExpandedHeight,
                pinned: true,
                automaticallyImplyLeading: false,
                centerTitle: false,
                titleSpacing: 16,
                backgroundColor: AppColors.primaryEmerald,
                surfaceTintColor: Colors.transparent,
                title: StreamBuilder<int>(
                  stream: IslamicDateHelper.hijriOffsetStream,
                  builder: (context, offsetSnap) {
                    final offset = offsetSnap.data ?? 0;
                    final hijriDate = IslamicDateHelper.getHijriDateSync(dayOffset: offset);
                    final dateText = hijriDate.getFormatted(lp.isUrdu);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.0),
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
                ),
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

                      // 4. User Welcome Greeting
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
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
                                      Text(
                                        lp.tr('welcome_greeting'),
                                        style: TextStyle(
                                          color: AppColors.goldBright,
                                          fontSize: 11,
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
                                          fontSize: 16,
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
                padding: EdgeInsets.fromLTRB(16, headerToStreakSpacing, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Real-time StreamBuilder listening strictly to Firestore global counter document ('global_counter/main')
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: widget.counterService.globalCounterStream,
                      builder: (context, globalSnap) {
                        final data = globalSnap.data?.data();
                        final docDate = StreakHelper.toCalendarDateString(data?['date'] ?? data?['last_reset_date'] ?? data?['lastUpdatedDate']);
                        final todayDate = StreakHelper.toCalendarDateString(DateTime.now());
                        final utcTodayDate = StreakHelper.toCalendarDateString(DateTime.now().toUtc());

                        return StreamBuilder<CounterSnapshot>(
                          stream: widget.counterService.snapshotStream,
                          initialData: widget.counterService.snapshot,
                          builder: (context, snapshot) {
                            final snap = snapshot.data ?? widget.counterService.snapshot;

                            // Global Total: prioritize Firestore cloud document, with local optimistic buffer & corruption guard
                            int effectiveGlobalTotal;
                            if (data != null) {
                              final int rawFirestoreTotal = ((data['globalTotal'] ?? data['total_count']) as num?)?.toInt() ?? 0;
                              final int firestoreTotal = (rawFirestoreTotal > 1000000000 || rawFirestoreTotal < 0) ? 0 : rawFirestoreTotal;
                              final int sanitizedSnapTotal = (snap.globalTotal > 1000000000 || snap.globalTotal < 0) ? 0 : snap.globalTotal;

                              if (sanitizedSnapTotal == 0 || (sanitizedSnapTotal - firestoreTotal).abs() > 10000) {
                                effectiveGlobalTotal = firestoreTotal;
                              } else {
                                effectiveGlobalTotal = sanitizedSnapTotal >= firestoreTotal ? sanitizedSnapTotal : firestoreTotal;
                              }
                            } else {
                              effectiveGlobalTotal = (snap.globalTotal > 1000000000 || snap.globalTotal < 0) ? 0 : snap.globalTotal;
                            }

                            // Global Today: prioritize Firestore todayTotal, with local optimistic buffer & midnight rollover check
                            int effectiveTodayTotal;
                            if (data != null) {
                              if (docDate.isNotEmpty && docDate != todayDate && docDate != utcTodayDate) {
                                // Midnight rollover: if doc date is from a previous day, today's count resets to 0 in UI
                                effectiveTodayTotal = 0;
                              } else {
                                final int rawFirestoreToday = ((data['todayTotal'] ?? data['today_count'] ?? data['globalToday'] ?? 0) as num).toInt();
                                final int firestoreToday = (rawFirestoreToday > 1000000000 || rawFirestoreToday < 0) ? 0 : rawFirestoreToday;
                                final int sanitizedSnapToday = (snap.globalToday > 1000000000 || snap.globalToday < 0) ? 0 : snap.globalToday;

                                if (sanitizedSnapToday == 0 || (sanitizedSnapToday - firestoreToday).abs() > 10000) {
                                  effectiveTodayTotal = firestoreToday;
                                } else {
                                  effectiveTodayTotal = sanitizedSnapToday >= firestoreToday ? sanitizedSnapToday : firestoreToday;
                                }
                              }
                            } else {
                              effectiveTodayTotal = (snap.globalToday > 1000000000 || snap.globalToday < 0) ? 0 : snap.globalToday;
                            }

                            final currentUid = FirebaseAuth.instance.currentUser?.uid;
                            if (currentUid == null) {
                              // Unauthenticated / public view: hide personal metrics entirely
                              return Column(
                                children: [
                                  DuroodSummaryCard(
                                    counterService: widget.counterService,
                                    snapshot: snap,
                                    globalTotal: effectiveGlobalTotal,
                                    todayTotal: effectiveTodayTotal,
                                    myToday: null,
                                    myTotal: null,
                                    isLoggedIn: false,
                                    onSendSalawat: widget.onNavigateToCounter,
                                  ),
                                ],
                              );
                            }

                            // Authenticated user session: strictly isolate "My Total" (users/{currentUid})
                            // and "My Today" (users/{currentUid}/daily_stats/{todayDateString})
                            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                              stream: widget.counterService.userCounterStream,
                              builder: (context, userSnap) {
                                final userData = userSnap.data?.data();
                                final int? cloudMyTotal = (userData?['myTotal'] as num?)?.toInt();
                                final int effectiveMyTotal = (cloudMyTotal != null)
                                    ? math.max(snap.personalTotal, cloudMyTotal + widget.counterService.pendingBuffer)
                                    : snap.personalTotal;

                                // Durood Points: strictly bind to authenticated user's Firestore document
                                final int? cloudPoints = ((userData?['duroodPoints'] ??
                                    userData?['points'] ??
                                    userData?['total_durood_points']) as num?)?.toInt();
                                final int effectivePoints = (cloudPoints != null)
                                    ? math.max(snap.duroodPoints, cloudPoints + widget.counterService.pendingBuffer)
                                    : snap.duroodPoints;

                                // Streak: calculate Snapchat-style consecutive calendar streak
                                final int? cloudStreak = ((userData?['streak'] ?? userData?['current_streak']) as num?)?.toInt();
                                final String? lastStreakDate = (userData?['lastStreakDate'] ?? userData?['lastActiveDate']) as String?;
                                final int calculatedStreak = cloudStreak != null
                                    ? StreakHelper.calculateEffectiveStreak(
                                        storedStreak: cloudStreak,
                                        lastActiveDate: lastStreakDate,
                                      )
                                    : snap.currentStreak;

                                // Stream user daily stats subcollection for myToday
                                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                                  stream: widget.counterService.userDailyStatsStream,
                                  builder: (context, dailySnap) {
                                    final dailyData = dailySnap.data?.data();
                                    final int? cloudMyToday = ((dailyData?['myToday'] ?? dailyData?['todayCount']) as num?)?.toInt();
                                    final int effectiveMyToday = (cloudMyToday != null)
                                        ? math.max(snap.personalToday, cloudMyToday + widget.counterService.pendingBuffer)
                                        : snap.personalToday;

                                    final int effectiveStreak = calculatedStreak > 0
                                        ? calculatedStreak
                                        : (effectiveMyToday > 0 ? ((cloudStreak != null && cloudStreak > 0) ? cloudStreak : 1) : 0);

                                    return Column(
                                      children: [
                                        GamificationBar(
                                          streakDays: effectiveStreak,
                                          duroodPoints: effectivePoints,
                                        ),
                                        SizedBox(height: streakToDuroodSpacing),
                                        DuroodSummaryCard(
                                          counterService: widget.counterService,
                                          snapshot: snap,
                                          globalTotal: effectiveGlobalTotal,
                                          todayTotal: effectiveTodayTotal,
                                          myToday: effectiveMyToday,
                                          myTotal: effectiveMyTotal,
                                          isLoggedIn: true,
                                          onSendSalawat: widget.onNavigateToCounter,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: duroodToCtaSpacing),

                    // 4. Send Salawat CTA Button
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 48),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2.5,
                        ),
                        onPressed: widget.onNavigateToCounter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              size: 21,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  lp.tr('send_salawat_now'),
                                  style: TextStyle(
                                    fontSize: 15.5,
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

                    SizedBox(height: ctaToEventsSpacing),

                    // ── 5. UPCOMING EVENTS Section / Carousel (LAST VISIBLE ABOVE THE FOLD) ──
                    _UpcomingEventsSection(cardHeight: eventCarouselHeight),

                    // Dynamic Viewport Fold Inset: ensures Daily Hadith starts completely below the fold on load
                    SizedBox(height: foldGap),

                    // ── BELOW THE FOLD (Hidden on launch, ONLY visible when user scrolls down) ──
                    // 6. Daily Hadith
                    DailyHadithCard(isUrdu: lp.isUrdu),
                    const SizedBox(height: 12),

                    // 7. Daily Ayat
                    DailyAyatCard(isUrdu: lp.isUrdu),
                    const SizedBox(height: 12),

                    // 8. Topic of the Day
                    TopicOfTheDayCard(isUrdu: lp.isUrdu),
                    const SizedBox(height: 90),
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
  final double cardHeight;

  const _UpcomingEventsSection({
    this.cardHeight = 185.0,
  });

  Widget _buildDirectEventCard(BuildContext context, EventModel event, String languageCode) {
    return EventCard(
      key: ValueKey('event_card_${event.id}_$languageCode'),
      event: event,
      height: cardHeight,
      width: (cardHeight * 1.62).clamp(290.0, 330.0),
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
              return SizedBox(
                height: cardHeight,
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
                const SizedBox(height: 10),

                // Bulletproof Horizontal Scrollable List
                SizedBox(
                  height: cardHeight,
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

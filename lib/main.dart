import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/language_provider.dart';
import 'core/widgets/app_exit_confirmation_dialog.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/counter/presentation/counter_screen.dart';
import 'features/knowledge_hub/presentation/qa_screen.dart';
import 'features/knowledge_hub/presentation/masail_grid.dart';
import 'features/knowledge_hub/presentation/aqaid_grid.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/admin_panel/presentation/admin_dashboard_web.dart';
import 'features/admin_panel/presentation/admin_login_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'services/counter_service.dart';
import 'services/firebase_init_service.dart';
import 'services/notification_service.dart';

final LanguageProvider globalLanguageProvider = LanguageProvider();

/// Top-level background message handler invoked by native Android/iOS when the app is closed or in background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  if (kDebugMode) {
    print(
      'FCM Background message received: ${message.messageId}, data: ${message.data}',
    );
  }

  // If the background/terminated message is data-only (no top-level notification rendered by OS),
  // immediately render a native heads-up system tray notification using high_importance_channel
  if (message.notification == null && message.data.isNotEmpty) {
    try {
      final title =
          message.data['title'] ??
          message.data['title_en'] ??
          message.data['title_ur'] ??
          'NOOR E SUNNAT';
      final body =
          message.data['body'] ??
          message.data['body_en'] ??
          message.data['body_ur'] ??
          message.data['message'] ??
          '';

      if (title.toString().isNotEmpty || body.toString().isNotEmpty) {
        const androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'High priority broadcast notifications, event alerts & answers',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
        );
        await flutterLocalNotificationsPlugin.show(
          id: message.messageId.hashCode,
          title: title.toString(),
          body: body.toString(),
          notificationDetails: notificationDetails,
          payload:
              message.data['id'] ??
              message.data['questionId'] ??
              message.data['route'],
        );
      }
    } catch (e) {
      if (kDebugMode) print('Background local notification fallback error: $e');
    }
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // 1. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request Notification Permissions for Foreground/Background
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 3. Force Topic Subscription on startup
    try {
      await messaging.subscribeToTopic('all_users');
      if (kDebugMode) print('Subscribed to all_users topic on boot');
    } catch (e) {
      if (kDebugMode) print('Error subscribing to all_users topic: $e');
    }

    // 4. Setup Android Notification Channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highImportanceChannel);

    // 5. Foreground presentation options for iOS/Android
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  await globalLanguageProvider.init();
  await FirebaseInitService.seedInitialDatabase();
  await NotificationService.initialize();
  runApp(const NoorESunnatApp());
}

class NoorESunnatApp extends StatelessWidget {
  const NoorESunnatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        return MaterialApp(
          title: globalLanguageProvider.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(globalLanguageProvider.isUrdu),
          locale: globalLanguageProvider.locale,

          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: kIsWeb
                  ? TextDirection.ltr
                  : globalLanguageProvider.textDirection,
              child: child!,
            );
          },
          home: kIsWeb ? const _WebAdminEntryGate() : const _AppAuthGate(),
          routes: {
            '/login': (context) => LoginScreen(
                  onLoginSuccess: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainShell()),
                    );
                  },
                ),
            '/home': (context) => const MainShell(),
          },
        );
      },
    );
  }
}

/// Web-specific entry gate: shows ONLY Admin Email & Password login on website.
/// Admins must be authenticated via Firebase Auth AND have is_admin=true in Firestore.
class _WebAdminEntryGate extends StatefulWidget {
  const _WebAdminEntryGate();

  @override
  State<_WebAdminEntryGate> createState() => _WebAdminEntryGateState();
}

class _WebAdminEntryGateState extends State<_WebAdminEntryGate> {
  bool _isAuthenticated = false;
  bool _clearing = true; // sign out any stale session on start

  @override
  void initState() {
    super.initState();
    _clearStaleSession();
  }

  Future<void> _clearStaleSession() async {
    // Force sign-out any lingering Firebase Auth session before showing login.
    // This ensures the admin must always explicitly authenticate on web.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) setState(() => _clearing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_clearing) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D6B3E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isAuthenticated) {
      return AdminDashboardWeb(
        onSignOut: () => setState(() {
          _isAuthenticated = false;
          _clearing = true;
          _clearStaleSession();
        }),
      );
    }

    // No onCancel on web — admins must log in, no escape to user app
    return AdminLoginScreen(
      onAdminAuthenticated: () => setState(() => _isAuthenticated = true),
    );
  }
}

/// Mobile App Gate: displays branded animated SplashScreen first.
class _AppAuthGate extends StatelessWidget {
  const _AppAuthGate();

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

/// Main shell for mobile app users — contains bottom nav and page body.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTabIndex = 0;
  late final CounterService _counterService;

  @override
  void initState() {
    super.initState();
    _counterService = CounterService();
  }

  @override
  void dispose() {
    _counterService.dispose();
    super.dispose();
  }

  Future<void> _handlePopScope(bool didPop, dynamic result) async {
    if (didPop) return;
    if (_currentTabIndex != 0) {
      setState(() => _currentTabIndex = 0);
      return;
    }
    final shouldExit = await AppExitConfirmationDialog.show(context);
    if (shouldExit && mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktopWeb = kIsWeb && screenWidth > 900;

        final pages = [
          HomeScreen(
            counterService: _counterService,
            onNavigateToCounter: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CounterScreen(counterService: _counterService),
                ),
              );
            },
          ),
          const AqaidGridScreen(),
          const MasailGridScreen(),
          const QAScreen(),
          ProfileScreen(counterService: _counterService),
        ];

        final activeBody = pages[_currentTabIndex];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => _handlePopScope(didPop, result),
          child: Scaffold(
            body: isDesktopWeb
                ? Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0xFFE5E7EB)),
                          right: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: activeBody,
                    ),
                  )
                : activeBody,
            bottomNavigationBar: Directionality(
              textDirection: lp.textDirection,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Align(
                  heightFactor: 1,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktopWeb ? 800 : double.infinity,
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _currentTabIndex,
                      onTap: (index) => setState(() => _currentTabIndex = index),
                      backgroundColor: Colors.white,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppColors.primaryEmerald,
                      unselectedItemColor: const Color(0xFF64748B),
                      selectedFontSize: 11,
                      unselectedFontSize: 11,
                      elevation: 0,
                      items: [
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.home_outlined),
                          activeIcon: const Icon(Icons.home_rounded),
                          label: lp.tr('nav_home'),
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.auto_awesome_outlined),
                          activeIcon: const Icon(Icons.auto_awesome_rounded),
                          label: lp.tr('nav_aqaid'),
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.menu_book_outlined),
                          activeIcon: const Icon(Icons.menu_book_rounded),
                          label: lp.tr('nav_masail'),
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.question_answer_outlined),
                          activeIcon: const Icon(Icons.question_answer_rounded),
                          label: lp.tr('nav_qa'),
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.person_outline_rounded),
                          activeIcon: const Icon(Icons.person_rounded),
                          label: lp.tr('nav_profile'),
                        ),
                      ],
                    ),
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

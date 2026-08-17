import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';
import '../../auth/presentation/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _routeToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _routeToNext() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // Resolve authenticated user token from Firebase Auth & secure storage
    final user = await AuthService.resolveCurrentUser();
    final hasPersistedSession = await AuthService.isSessionPersisted();

    if (!mounted) return;

    if (user != null || (hasPersistedSession && AuthService.isLoggedIn)) {
      // User has active persistent login session — take directly into main app
      await AuthService.ensureUserDocExists(user);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    } else {
      // User is not logged in or explicitly signed out — route to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainShell()),
              );
            },
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A3A2A),
              Color(0xFF04271B),
              Color(0xFF021D14),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Subtle Glow Pattern
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Animated Center Content
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gold Islamic Crescent & Star Emblem Badge
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_moon_rounded,
                          size: 54,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App Title
                    const Text(
                      'NOOR E SUNNAT',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentGold,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Arabic / Urdu Subtitle
                    Text(
                      lp.isUrdu ? 'نورِ سنت و فیضانِ علم' : 'Sacred Sunnah, Salawat & Fiqh Hub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Pulsing Loading Status
            Positioned(
              bottom: 50,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentGold.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lp.isUrdu ? 'نورِ سنت کی برکات جاری ہیں...' : 'Loading NOOR E SUNNAT...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

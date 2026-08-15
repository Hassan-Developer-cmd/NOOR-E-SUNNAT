import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/counter_service.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final CounterService counterService;

  const ProfileScreen({super.key, required this.counterService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final status = await AdminService.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Beloved Guest';
    final email = user?.email ?? 'guest@islamicapp.org';
    final photoUrl = user?.photoURL;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        elevation: 0,
        backgroundColor: AppColors.primaryEmerald,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── User Header Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emeraldDeep, AppColors.primaryEmerald],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.goldBright,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldBright,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ADMINISTRATOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emeraldDeep,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stats Row ──
            StreamBuilder<CounterSnapshot>(
              stream: widget.counterService.snapshotStream,
              initialData: widget.counterService.snapshot,
              builder: (context, snapshot) {
                final snap = snapshot.data ?? widget.counterService.snapshot;
                return Row(
                  children: [
                    Expanded(
                      child: _ProfileStatCard(
                        title: 'Streak',
                        value: '${snap.currentStreak} Days',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileStatCard(
                        title: 'Points',
                        value: '${snap.duroodPoints}',
                        icon: Icons.star_rounded,
                        color: AppColors.accentGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileStatCard(
                        title: 'My Durood',
                        value: '${snap.personalTotal}',
                        icon: Icons.touch_app_rounded,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Settings List ──
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    // Language Setting
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: AppColors.primaryEmerald),
                      title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(lp.isUrdu ? 'اردو (Urdu)' : 'English'),
                      trailing: Switch(
                        value: lp.isUrdu,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (_) => lp.toggleLanguage(),
                      ),
                    ),
                    const Divider(height: 1),

                    // Sign Out
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                      onTap: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final lp = globalLanguageProvider;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lp.isUrdu ? 'سائن آؤٹ کریں؟' : 'Sign Out?'),
        content: Text(
          lp.isUrdu
              ? 'کیا آپ واقعی اپنے اکاؤنٹ سے سائن آؤٹ کرنا چاہتے ہیں؟'
              : 'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lp.isUrdu ? 'منسوخ کریں' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
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
                  (route) => false,
                );
              }
            },
            child: Text(lp.isUrdu ? 'سائن آؤٹ' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

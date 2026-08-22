import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/counter_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../knowledge_hub/presentation/my_questions_screen.dart';

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
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final user = FirebaseAuth.instance.currentUser;
        final displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : lp.tr('user_profile_guest');
        final email = user?.email ?? 'guest@nooresunnat.com';
        final photoUrl = user?.photoURL;
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              lp.tr('profile_settings'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
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
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showEditNameDialog(context, displayName),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.goldBright,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldBright,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lp.tr('admin_badge'),
                            style: const TextStyle(
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
                            title: lp.tr('current_streak'),
                            value: '${snap.currentStreak} ${lp.tr('streak_days')}',
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStatCard(
                            title: lp.tr('durood_points'),
                            value: '${snap.duroodPoints}',
                            icon: Icons.star_rounded,
                            color: AppColors.accentGold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStatCard(
                            title: lp.tr('my_total'),
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
                        // Edit Profile Name
                        ListTile(
                          leading: const Icon(Icons.badge_rounded,
                              color: AppColors.primaryEmerald),
                          title: Text(
                            lp.tr('edit_display_name'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colors.grey),
                          onTap: () => _showEditNameDialog(context, displayName),
                        ),
                        const Divider(height: 1),

                        // My Questions
                        ListTile(
                          leading: const Icon(Icons.question_answer_rounded,
                              color: AppColors.primaryEmerald),
                          title: Text(
                            lp.tr('my_questions_title'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            lp.tr('my_questions_sub'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyQuestionsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),

                        // Language Setting
                        ListTile(
                          leading: const Icon(Icons.language_rounded,
                              color: AppColors.primaryEmerald),
                          title: Text(lp.tr('app_language'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            lp.isUrdu ? 'اردو (Urdu)' : 'English (انگریزی)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Switch(
                            value: lp.isUrdu,
                            activeTrackColor: AppColors.primaryEmerald,
                            onChanged: (_) => lp.toggleLanguage(),
                          ),
                        ),
                        const Divider(height: 1),

                        // Sign Out
                        ListTile(
                          leading: const Icon(Icons.logout_rounded,
                              color: Color(0xFFE11D48)),
                          title: Text(
                            lp.tr('sign_out'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE11D48)),
                          ),
                          onTap: () => _confirmSignOut(context),
                        ),
                        const Divider(height: 1),

                        // Delete Account (Permanent Deletion)
                        ListTile(
                          leading: const Icon(Icons.delete_forever_rounded,
                              color: Color(0xFFDC2626)),
                          title: Text(
                            lp.tr('delete_account'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626)),
                          ),
                          subtitle: Text(
                            lp.isUrdu
                                ? 'تمام ڈیٹا مستقل طور پر ختم ہو جائے گا'
                                : 'Irreversible • Erases all Durood & account data',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFFDC2626).withValues(alpha: 0.8),
                            ),
                          ),
                          onTap: () => _confirmDeleteAccount(context),
                        ),
                      ],
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

  void _showEditNameDialog(BuildContext context, String currentDisplayName) {
    final lp = globalLanguageProvider;
    final guestLabel = lp.tr('user_profile_guest');
    final initialText = currentDisplayName == guestLabel ? '' : currentDisplayName;
    final textController = TextEditingController(text: initialText);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.primaryEmerald,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          lp.tr('edit_display_name'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: lp.tr('display_name_hint'),
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppColors.primaryEmerald),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primaryEmerald, width: 1.8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return lp.tr('name_empty_error');
                        }
                        if (value.trim().length < 2) {
                          return lp.tr('name_too_short_error');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(bottomSheetContext),
                            child: Text(lp.tr('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() => isSubmitting = true);
                                    try {
                                      final newName = textController.text.trim();
                                      await AuthService.updateUserProfileName(newName);
                                      if (bottomSheetContext.mounted) {
                                        Navigator.pop(bottomSheetContext);
                                      }
                                      if (mounted) {
                                        setState(() {});
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded,
                                                    color: Color(0xFF34D399), size: 20),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    lp.tr('name_updated_success'),
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF064E3B),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (bottomSheetContext.mounted) {
                                        setModalState(() => isSubmitting = false);
                                        ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: const Color(0xFFDC2626),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(lp.tr('save')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final lp = globalLanguageProvider;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lp.tr('delete_account_confirm_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          lp.tr('delete_account_confirm_msg'),
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              lp.tr('cancel'),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _executeAccountDeletion(context);
            },
            child: Text(lp.tr('delete_account_action')),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAccountDeletion(BuildContext context, {String? reauthPassword}) async {
    final lp = globalLanguageProvider;

    // Show loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  lp.tr('deleting_account'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await AuthService.deleteAccount(reauthPassword: reauthPassword);

      if (context.mounted) {
        // Dismiss loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Navigate cleanly to Login Screen
        _navigateToLogin(context);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lp.tr('account_deleted_success'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        // Dismiss loading dialog
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          _promptReauthentication(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deletion error: ${e.message ?? e.code}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Dismiss loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _promptReauthentication(BuildContext context) {
    final lp = globalLanguageProvider;
    final isGoogle = AuthService.isGoogleUser;

    if (isGoogle) {
      // Prompt Google re-authentication
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(lp.tr('reauth_required_title')),
          content: Text(lp.tr('reauth_google_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lp.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _executeAccountDeletion(context);
              },
              child: Text(lp.tr('continue_with_google')),
            ),
          ],
        ),
      );
    } else {
      // Prompt Password re-authentication
      final passwordController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      bool obscure = true;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(lp.tr('reauth_required_title')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lp.tr('reauth_required_msg'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      hintText: lp.tr('reauth_password_label'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.primaryEmerald),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setDlgState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? lp.tr('please_enter_password')
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lp.tr('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final password = passwordController.text;
                  Navigator.pop(ctx);
                  await _executeAccountDeletion(context, reauthPassword: password);
                },
                child: Text(lp.tr('reauthenticate')),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _navigateToLogin(BuildContext context) {
    try {
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (_) {
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
  }

  void _confirmSignOut(BuildContext context) {
    final lp = globalLanguageProvider;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lp.tr('sign_out_confirm_title')),
        content: Text(lp.tr('sign_out_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lp.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              if (context.mounted) {
                _navigateToLogin(context);
              }
            },
            child: Text(lp.tr('sign_out')),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

  }
}

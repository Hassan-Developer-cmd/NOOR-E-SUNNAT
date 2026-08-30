import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../main.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/counter_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../knowledge_hub/presentation/my_questions_screen.dart';
import 'widgets/profile_settings_sheets.dart';
import '../../../core/utils/image_compression_helper.dart';

class ProfileScreen extends StatefulWidget {
  final CounterService counterService;

  const ProfileScreen({super.key, required this.counterService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAdmin = false;
  bool _isUploadingImage = false;
  int _selectedTab = 0; // 0: Profile, 1: Settings

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

  void _showImagePickerSheet(BuildContext context, {bool hasCustomPhoto = false}) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_rounded, color: AppColors.primaryEmerald, size: 20),
                const SizedBox(width: 8),
                Text(
                  lp.tr('profile_picture_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Take Photo Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.emeraldContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_rounded, color: AppColors.primaryEmerald, size: 22),
              ),
              title: Text(
                lp.tr('take_photo'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              ),
              subtitle: Text(
                isUrdu ? 'کیمرہ سے نئی تصویر بنائیں' : 'Capture a new profile photo',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFFF8FAFC),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),

            // Gallery Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              title: Text(
                lp.tr('choose_from_gallery'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              ),
              subtitle: Text(
                isUrdu ? 'گیلری سے تصویر منتخب کریں' : 'Choose existing photo from device',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFFF8FAFC),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),

            if (hasCustomPhoto) ...[
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                title: Text(
                  lp.tr('remove_photo'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFFDC2626)),
                ),
                subtitle: Text(
                  isUrdu ? 'موجودہ تصویر ہٹا کر ابتدائی نام دکھائیں' : 'Remove custom photo and use initials',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFFFEF2F2),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _removeProfileImage();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final lp = globalLanguageProvider;
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      if (mounted) setState(() => _isUploadingImage = true);

      final rawBytes = await pickedFile.readAsBytes();
      final compResult = await ImageCompressionHelper.compressImageBytes(
        rawBytes,
        maxWidth: 512,
        maxHeight: 512,
        initialQuality: 70,
        maxSizeKb: 100,
      );

      await AuthService.updateProfileImageBase64(compResult.base64String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lp.tr('photo_updated_success'),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lp.tr('photo_update_failed')} ($e)'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _removeProfileImage() async {
    final lp = globalLanguageProvider;
    try {
      setState(() => _isUploadingImage = true);
      await AuthService.removeProfileImageBase64();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lp.isUrdu ? 'تصویر کامیابی سے ہٹا دی گئی' : 'Profile photo removed successfully',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final user = FirebaseAuth.instance.currentUser;

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
                StreamBuilder<AppUser?>(
                  stream: AuthService.currentUserStream,
                  builder: (context, userSnap) {
                    final appUser = userSnap.data;
                    final effectiveDisplayName = (appUser?.username != null && appUser!.username.isNotEmpty)
                        ? appUser.username
                        : ((user?.displayName != null && user!.displayName!.isNotEmpty)
                            ? user.displayName!
                            : lp.tr('user_profile_guest'));
                    final effectiveEmail = (appUser?.email != null && appUser!.email.isNotEmpty)
                        ? appUser.email
                        : (user?.email ?? 'guest@nooresunnat.com');
                    final effectivePhotoUrl = (appUser?.photoUrl != null && appUser!.photoUrl.isNotEmpty)
                        ? appUser.photoUrl
                        : user?.photoURL;
                    final profileBase64 = appUser?.profileImageBase64;

                    return Container(
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
                          UserAvatar(
                            radius: 38,
                            profileImageBase64: profileBase64,
                            photoUrl: effectivePhotoUrl,
                            displayName: effectiveDisplayName,
                            showEditButton: true,
                            isLoading: _isUploadingImage,
                            onEditPressed: () => _showImagePickerSheet(
                              context,
                              hasCustomPhoto: profileBase64 != null && profileBase64.isNotEmpty,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  effectiveDisplayName,
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
                                  onTap: () => _showEditNameDialog(context, effectiveDisplayName),
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
                            effectiveEmail,
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
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Segmented Tab Switcher (Profile vs Settings) ──
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          label: lp.tr('tab_profile'),
                          icon: Icons.person_rounded,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: lp.tr('tab_settings'),
                          icon: Icons.settings_rounded,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── TAB 0: PROFILE VIEW ──
                if (_selectedTab == 0) ...[
                  // Stats Row
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
                  const SizedBox(height: 18),

                  // Profile Actions Card
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

                // ── TAB 1: SETTINGS VIEW ──
                if (_selectedTab == 1) ...[
                  // Card 1: Language Preferences
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.language_rounded,
                            color: AppColors.primaryEmerald),
                        title: Text(lp.tr('app_language'),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Card 2: App & Community (About Us, Our Team, Share App, Rate App, Terms & Policy)
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
                          // 1. About Us
                          ListTile(
                            leading: const Icon(Icons.info_outline_rounded,
                                color: AppColors.primaryEmerald),
                            title: Text(
                              lp.tr('settings_about_us'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lp.tr('settings_about_us_sub'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey),
                            onTap: () => ProfileSettingsSheets.showAboutUsSheet(context),
                          ),
                          const Divider(height: 1),

                          // 2. Our Team
                          ListTile(
                            leading: const Icon(Icons.groups_rounded,
                                color: AppColors.primaryEmerald),
                            title: Text(
                              lp.tr('settings_our_team'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lp.tr('settings_our_team_sub'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey),
                            onTap: () => ProfileSettingsSheets.showOurTeamSheet(context),
                          ),
                          const Divider(height: 1),

                          // 3. Share App
                          ListTile(
                            leading: const Icon(Icons.share_rounded,
                                color: AppColors.primaryEmerald),
                            title: Text(
                              lp.tr('settings_share_app'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lp.tr('settings_share_app_sub'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey),
                            onTap: () => ProfileSettingsSheets.shareApp(context),
                          ),
                          const Divider(height: 1),

                          // 4. Rate App
                          ListTile(
                            leading: const Icon(Icons.star_rate_rounded,
                                color: Color(0xFFD97706)),
                            title: Text(
                              lp.tr('settings_rate_app'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lp.tr('settings_rate_app_sub'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey),
                            onTap: () => ProfileSettingsSheets.showRateAppDialog(context),
                          ),
                          const Divider(height: 1),

                          // 5. Terms and Policy
                          ListTile(
                            leading: const Icon(Icons.policy_rounded,
                                color: AppColors.primaryEmerald),
                            title: Text(
                              lp.tr('settings_terms_policy'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lp.tr('settings_terms_policy_sub'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey),
                            onTap: () => ProfileSettingsSheets.showTermsAndPolicySheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Card 3: Session (Sign Out)
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded,
                            color: Color(0xFFE11D48)),
                        title: Text(
                          lp.tr('sign_out'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE11D48)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Colors.grey),
                        onTap: () => _confirmSignOut(context),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
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

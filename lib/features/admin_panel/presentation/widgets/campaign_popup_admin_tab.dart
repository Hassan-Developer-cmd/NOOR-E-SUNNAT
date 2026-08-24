import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/campaign_popup_model.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/campaign_popup_dialog.dart';
import '../../../../services/campaign_popup_service.dart';
import '../../../../core/utils/image_compression_helper.dart';
import '../../../../main.dart';

class CampaignPopupAdminTab extends StatefulWidget {
  const CampaignPopupAdminTab({super.key});

  @override
  State<CampaignPopupAdminTab> createState() => _CampaignPopupAdminTabState();
}

class _CampaignPopupAdminTabState extends State<CampaignPopupAdminTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  bool _isActive = true;
  String _targetRoute = '/events';
  String _imageType = CampaignPopupModel.imageTypeUrl; // 'url' | 'base64'
  String? _imageBase64;
  String? _uploadedFileName;
  int? _uploadedFileSizeKb;

  bool _previewInUrdu = false;

  final TextEditingController _titleEnController = TextEditingController();
  final TextEditingController _titleUrController = TextEditingController();
  final TextEditingController _detailsEnController = TextEditingController();
  final TextEditingController _detailsUrController = TextEditingController();
  final TextEditingController _buttonTextEnController = TextEditingController();
  final TextEditingController _buttonTextUrController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final List<Map<String, String>> _availableRoutes = const [
    {'route': '/events', 'label': 'Upcoming Events & Campaigns', 'icon': 'event'},
    {'route': '/counter', 'label': 'Durood Counter Screen', 'icon': 'touch_app'},
    {'route': '/aqaid', 'label': 'Aqaid Hub Grid', 'icon': 'auto_awesome'},
    {'route': '/masail', 'label': 'Masail Hub Grid', 'icon': 'menu_book'},
    {'route': '/qa', 'label': 'Ask Questions / Q&A', 'icon': 'question_answer'},
    {'route': '/profile', 'label': 'User Profile & Settings', 'icon': 'person'},
    {'route': '/home', 'label': 'Home Screen (Dismiss only)', 'icon': 'home'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();

    // Listeners for real-time live preview update
    _titleEnController.addListener(_updatePreview);
    _titleUrController.addListener(_updatePreview);
    _detailsEnController.addListener(_updatePreview);
    _detailsUrController.addListener(_updatePreview);
    _buttonTextEnController.addListener(_updatePreview);
    _buttonTextUrController.addListener(_updatePreview);
    _imageUrlController.addListener(_updatePreview);
  }

  void _updatePreview() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialConfig() async {
    try {
      final config = await CampaignPopupService.getCampaignPopup();
      if (!mounted) return;

      setState(() {
        _isActive = config.isActive;
        _titleEnController.text = config.titleEnglish;
        _titleUrController.text = config.titleUrdu;
        _detailsEnController.text = config.detailsEnglish;
        _detailsUrController.text = config.detailsUrdu;
        _buttonTextEnController.text = config.buttonTextEnglish;
        _buttonTextUrController.text = config.buttonTextUrdu;
        _targetRoute = config.targetRoute.isNotEmpty ? config.targetRoute : '/events';
        _imageType = config.imageType;
        _imageUrlController.text = config.imageUrl ?? '';
        _imageBase64 = config.imageBase64;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleUrController.dispose();
    _detailsEnController.dispose();
    _detailsUrController.dispose();
    _buttonTextEnController.dispose();
    _buttonTextUrController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  CampaignPopupModel get _currentLiveConfig {
    return CampaignPopupModel(
      isActive: _isActive,
      titleEnglish: _titleEnController.text.trim().isNotEmpty
          ? _titleEnController.text.trim()
          : "Rabi'ul Awwal 2026",
      titleUrdu: _titleUrController.text.trim().isNotEmpty
          ? _titleUrController.text.trim()
          : 'ربیع الاول ۱۴۴۸ / ۲۰۲۶',
      detailsEnglish: _detailsEnController.text.trim().isNotEmpty
          ? _detailsEnController.text.trim()
          : 'Complete Durood, Shamail, Seerah, and courses to win prizes!',
      detailsUrdu: _detailsUrController.text.trim().isNotEmpty
          ? _detailsUrController.text.trim()
          : 'انعامات جیتنے کے لیے درود پاک، شمائل، سیرت اور کورسز مکمل کریں!',
      buttonTextEnglish: _buttonTextEnController.text.trim().isNotEmpty
          ? _buttonTextEnController.text.trim()
          : 'Get Started',
      buttonTextUrdu: _buttonTextUrController.text.trim().isNotEmpty
          ? _buttonTextUrController.text.trim()
          : 'شروع کریں',
      targetRoute: _targetRoute,
      imageType: _imageType,
      imageUrl: _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null,
      imageBase64: (_imageBase64 != null && _imageBase64!.trim().isNotEmpty)
          ? _imageBase64
          : null,
    );
  }

  Future<void> _pickImageFile() async {
    final lp = globalLanguageProvider;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      setState(() => _isUploadingImage = true);

      final rawBytes = await file.readAsBytes();
      final compResult = await ImageCompressionHelper.compressImageBytes(
        rawBytes,
        maxWidth: 1024,
        maxHeight: 1024,
        initialQuality: 70,
        maxSizeKb: 200,
      );

      setState(() {
        _imageBase64 = compResult.base64String;
        _imageType = CampaignPopupModel.imageTypeBase64;
        _uploadedFileName = file.name;
        _uploadedFileSizeKb = compResult.sizeKb;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${lp.tr('image_uploaded_success')} (${compResult.sizeKb} KB - ${compResult.width}x${compResult.height}px)',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveAndPublish() async {
    final lp = globalLanguageProvider;
    setState(() => _isSaving = true);

    try {
      final configToSave = _currentLiveConfig;
      await CampaignPopupService.saveCampaignPopup(configToSave);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Color(0xFF34D399), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lp.tr('popup_saved_success'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing popup: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 980;

        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: AppColors.primaryEmerald),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(screenWidth < 600 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Banner with Master Active Toggle
              _buildTopStatusHeader(lp, screenWidth),
              const SizedBox(height: 24),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 24),

              // Responsive Two-Column Layout (Form Controls on Left, Live Preview on Right)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Configuration Controls
                    Expanded(
                      flex: 3,
                      child: _buildConfigurationForm(lp),
                    ),
                    const SizedBox(width: 32),
                    // Right Column: Interactive Live Preview Card
                    Expanded(
                      flex: 2,
                      child: _buildLivePreviewSection(lp),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConfigurationForm(lp),
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 24),
                    _buildLivePreviewSection(lp),
                  ],
                ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 20),

              // Bottom Save & Publish Button
              _buildSaveButton(lp, screenWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatusHeader(LanguageProvider lp, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isActive
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isActive ? Icons.campaign_rounded : Icons.campaign_outlined,
            color: _isActive
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    lp.tr('campaign_popup'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isActive
                          ? const Color(0xFF059669).withValues(alpha: 0.12)
                          : const Color(0xFFDC2626).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _isActive
                          ? lp.tr('popup_status_active')
                          : lp.tr('popup_status_inactive'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Configure the modal announcement shown to all users on app launch',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Master Toggle Switch
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (screenWidth > 600)
              Text(
                _isActive ? lp.tr('enable_startup_popup') : lp.tr('disable_startup_popup'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isActive ? const Color(0xFF059669) : Colors.grey.shade600,
                ),
              ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: _isActive,
              activeTrackColor: AppColors.primaryEmerald,
              onChanged: (val) {
                setState(() => _isActive = val);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfigurationForm(LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: Content
        const Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primaryEmerald),
            SizedBox(width: 8),
            Text(
              'Campaign Details & Bilingual Content',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title English
        _buildTextField(
          controller: _titleEnController,
          label: lp.tr('popup_title_en'),
          hint: "e.g., Rabi'ul Awwal 2026",
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 14),

        // Title Urdu
        _buildTextField(
          controller: _titleUrController,
          label: lp.tr('popup_title_ur'),
          hint: 'مثال: ربیع الاول ۱۴۴۸ / ۲۰۲۶',
          icon: Icons.translate_rounded,
          isUrdu: true,
        ),
        const SizedBox(height: 18),

        // Details English
        _buildTextField(
          controller: _detailsEnController,
          label: lp.tr('popup_body_en'),
          hint: 'e.g., Complete Durood, Shamail, Seerah, and courses to win prizes!',
          icon: Icons.article_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 14),

        // Details Urdu
        _buildTextField(
          controller: _detailsUrController,
          label: lp.tr('popup_body_ur'),
          hint: 'مثال: انعامات جیتنے کے لیے درود پاک، شمائل، سیرت اور کورسز مکمل کریں!',
          icon: Icons.short_text_rounded,
          maxLines: 3,
          isUrdu: true,
        ),
        const SizedBox(height: 20),

        // Button Action Text (EN & UR)
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _buttonTextEnController,
                label: lp.tr('popup_btn_en'),
                hint: 'e.g., Get Started',
                icon: Icons.smart_button_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(
                controller: _buttonTextUrController,
                label: lp.tr('popup_btn_ur'),
                hint: 'مثال: شروع کریں',
                icon: Icons.touch_app_outlined,
                isUrdu: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Target Navigation Dropdown
        const Row(
          children: [
            Icon(Icons.alt_route_rounded, size: 20, color: AppColors.primaryEmerald),
            SizedBox(width: 8),
            Text(
              'Click Action Navigation Target',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgOffWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _targetRoute,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryEmerald),
              items: _availableRoutes.map((item) {
                return DropdownMenuItem<String>(
                  value: item['route'],
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_circle_right_outlined, size: 18, color: AppColors.primaryEmerald),
                      const SizedBox(width: 10),
                      Text(
                        item['label'] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        item['route'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _targetRoute = val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Image Selection Options
        const Row(
          children: [
            Icon(Icons.photo_library_rounded, size: 20, color: AppColors.primaryEmerald),
            SizedBox(width: 8),
            Text(
              'Campaign Artwork / Visual Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Image Mode Tabs (URL vs Base64)
        Row(
          children: [
            _buildModeTab(
              title: lp.tr('direct_image_url'),
              icon: Icons.link_rounded,
              isSelected: _imageType == CampaignPopupModel.imageTypeUrl,
              onTap: () => setState(() => _imageType = CampaignPopupModel.imageTypeUrl),
            ),
            const SizedBox(width: 12),
            _buildModeTab(
              title: lp.tr('upload_local_image'),
              icon: Icons.cloud_upload_outlined,
              isSelected: _imageType == CampaignPopupModel.imageTypeBase64,
              onTap: () => setState(() => _imageType = CampaignPopupModel.imageTypeBase64),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Image Mode Body
        if (_imageType == CampaignPopupModel.imageTypeUrl) ...[
          _buildTextField(
            controller: _imageUrlController,
            label: lp.tr('direct_image_url'),
            hint: 'https://example.com/banner.jpg (Leave blank for default spiritual artwork)',
            icon: Icons.image_search_rounded,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgOffWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickImageFile,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: Text(
                    _isUploadingImage ? 'Processing...' : lp.tr('choose_image_file'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _imageBase64 != null
                            ? '✓ Local image converted to Base64 (${_uploadedFileSizeKb ?? 0} KB)'
                            : 'No local file uploaded yet. Click to pick from disk.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _imageBase64 != null ? FontWeight.bold : FontWeight.normal,
                          color: _imageBase64 != null ? const Color(0xFF059669) : Colors.grey.shade700,
                        ),
                      ),
                      if (_uploadedFileName != null)
                        Text(
                          _uploadedFileName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (_imageBase64 != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    tooltip: lp.tr('clear_image'),
                    onPressed: () {
                      setState(() {
                        _imageBase64 = null;
                        _uploadedFileName = null;
                        _uploadedFileSizeKb = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryEmerald.withValues(alpha: 0.1)
              : AppColors.bgOffWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryEmerald : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewSection(LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.remove_red_eye_rounded, size: 20, color: AppColors.primaryEmerald),
                SizedBox(width: 8),
                Text(
                  'Live Mobile Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            // Preview language switcher
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgOffWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPreviewLangPill(
                    label: 'EN',
                    isSelected: !_previewInUrdu,
                    onTap: () => setState(() => _previewInUrdu = false),
                  ),
                  _buildPreviewLangPill(
                    label: 'اردو',
                    isSelected: _previewInUrdu,
                    onTap: () => setState(() => _previewInUrdu = true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Mobile Shell Container Mockup
        Center(
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF334155), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mockup Status Bar
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  color: Colors.black26,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('9:41', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.wifi, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full, size: 12, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mockup App Body with Modal Display
                Container(
                  height: 480,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    image: DecorationImage(
                      image: AssetImage('assets/images/masjid_nabawi_header.jpeg'),
                      fit: BoxFit.cover,
                      opacity: 0.15,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Backdrop Dim Overlay
                      Container(color: Colors.black54),

                      // Popup Dialog Preview
                      Directionality(
                        textDirection: _previewInUrdu ? TextDirection.rtl : TextDirection.ltr,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: CampaignPopupDialog(
                            config: _currentLiveConfig,
                            isPreview: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewLangPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(LanguageProvider lp, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _isLoading || _isSaving ? null : _loadInitialConfig,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reset Changes'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: const BorderSide(color: AppColors.borderLight),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAndPublish,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.cloud_upload_rounded, size: 18),
          label: Text(
            _isSaving ? 'Publishing...' : lp.tr('save_and_publish_popup'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryEmerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isUrdu = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            fontSize: 14,
            fontFamily: isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            prefixIcon: maxLines == 1 ? Icon(icon, size: 18, color: AppColors.primaryEmerald) : null,
            filled: true,
            fillColor: AppColors.bgOffWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

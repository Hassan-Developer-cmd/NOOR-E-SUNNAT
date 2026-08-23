import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignPopupModel {
  static const String defaultTargetRoute = '/events';
  static const String imageTypeUrl = 'url';
  static const String imageTypeBase64 = 'base64';

  final String id;
  final bool isActive;
  final String titleEnglish;
  final String titleUrdu;
  final String detailsEnglish;
  final String detailsUrdu;
  final String buttonTextEnglish;
  final String buttonTextUrdu;
  final String targetRoute;
  final String imageType; // 'url' | 'base64'
  final String? imageUrl;
  final String? imageBase64;
  final dynamic updatedAt;

  const CampaignPopupModel({
    this.id = 'launch_popup',
    this.isActive = true,
    this.titleEnglish = "Rabi'ul Awwal 2026",
    this.titleUrdu = 'ربیع الاول ۱۴۴۸ / ۲۰۲۶',
    this.detailsEnglish = 'Complete Durood, Shamail, Seerah, and courses to win prizes!',
    this.detailsUrdu = 'انعامات جیتنے کے لیے درود پاک، شمائل، سیرت اور کورسز مکمل کریں!',
    this.buttonTextEnglish = 'Get Started',
    this.buttonTextUrdu = 'شروع کریں',
    this.targetRoute = defaultTargetRoute,
    this.imageType = imageTypeUrl,
    this.imageUrl,
    this.imageBase64,
    this.updatedAt,
  });

  String getTitle(bool isUrdu) {
    if (isUrdu && titleUrdu.trim().isNotEmpty) {
      return titleUrdu;
    }
    return titleEnglish.isNotEmpty ? titleEnglish : "Rabi'ul Awwal 2026";
  }

  String getDetails(bool isUrdu) {
    if (isUrdu && detailsUrdu.trim().isNotEmpty) {
      return detailsUrdu;
    }
    return detailsEnglish.isNotEmpty
        ? detailsEnglish
        : 'Complete Durood, Shamail, Seerah, and courses to win prizes!';
  }

  String getButtonText(bool isUrdu) {
    if (isUrdu && buttonTextUrdu.trim().isNotEmpty) {
      return buttonTextUrdu;
    }
    return buttonTextEnglish.isNotEmpty ? buttonTextEnglish : 'Get Started';
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'titleEnglish': titleEnglish,
      'titleUrdu': titleUrdu,
      'detailsEnglish': detailsEnglish,
      'detailsUrdu': detailsUrdu,
      'buttonTextEnglish': buttonTextEnglish,
      'buttonTextUrdu': buttonTextUrdu,
      'targetRoute': targetRoute,
      'imageType': imageType,
      'imageUrl': imageUrl ?? '',
      'imageBase64': imageBase64 ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CampaignPopupModel.fromMap(String id, Map<String, dynamic>? map) {
    if (map == null) return CampaignPopupModel.defaultConfig(id: id);

    // Support both camelCase and snake_case keys for resilience
    final isActive = (map['isActive'] ?? map['is_active'] ?? map['active']) as bool? ?? true;
    final titleEn = (map['titleEnglish'] ?? map['title_en'] ?? map['title']) as String? ?? "Rabi'ul Awwal 2026";
    final titleUr = (map['titleUrdu'] ?? map['title_ur'] ?? '') as String? ?? 'ربیع الاول ۱۴۴۸ / ۲۰۲۶';
    final detailsEn = (map['detailsEnglish'] ?? map['details_en'] ?? map['details'] ?? map['body_en']) as String? ??
        'Complete Durood, Shamail, Seerah, and courses to win prizes!';
    final detailsUr = (map['detailsUrdu'] ?? map['details_ur'] ?? map['body_ur']) as String? ??
        'انعامات جیتنے کے لیے درود پاک، شمائل، سیرت اور کورسز مکمل کریں!';
    final btnEn = (map['buttonTextEnglish'] ?? map['button_text_en'] ?? map['buttonText'] ?? 'Get Started') as String;
    final btnUr = (map['buttonTextUrdu'] ?? map['button_text_ur'] ?? 'شروع کریں') as String;
    final targetRoute = (map['targetRoute'] ?? map['target_route'] ?? defaultTargetRoute) as String;
    final imageType = (map['imageType'] ?? map['image_type'] ?? imageTypeUrl) as String;
    final imageUrl = (map['imageUrl'] ?? map['image_url']) as String?;
    final imageBase64 = (map['imageBase64'] ?? map['image_base64']) as String?;
    final updatedAt = map['updatedAt'] ?? map['updated_at'];

    return CampaignPopupModel(
      id: id,
      isActive: isActive,
      titleEnglish: titleEn,
      titleUrdu: titleUr,
      detailsEnglish: detailsEn,
      detailsUrdu: detailsUr,
      buttonTextEnglish: btnEn,
      buttonTextUrdu: btnUr,
      targetRoute: targetRoute,
      imageType: imageType,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      imageBase64: (imageBase64 != null && imageBase64.isNotEmpty) ? imageBase64 : null,
      updatedAt: updatedAt,
    );
  }

  factory CampaignPopupModel.defaultConfig({String id = 'launch_popup'}) {
    return CampaignPopupModel(
      id: id,
      isActive: true,
      titleEnglish: "Rabi'ul Awwal 2026",
      titleUrdu: 'ربیع الاول ۱۴۴۸ / ۲۰۲۶',
      detailsEnglish: 'Complete Durood, Shamail, Seerah, and courses to win prizes!',
      detailsUrdu: 'انعامات جیتنے کے لیے درود پاک، شمائل، سیرت اور کورسز مکمل کریں!',
      buttonTextEnglish: 'Get Started',
      buttonTextUrdu: 'شروع کریں',
      targetRoute: defaultTargetRoute,
      imageType: imageTypeUrl,
      imageUrl: null,
      imageBase64: null,
      updatedAt: null,
    );
  }

  CampaignPopupModel copyWith({
    String? id,
    bool? isActive,
    String? titleEnglish,
    String? titleUrdu,
    String? detailsEnglish,
    String? detailsUrdu,
    String? buttonTextEnglish,
    String? buttonTextUrdu,
    String? targetRoute,
    String? imageType,
    String? imageUrl,
    String? imageBase64,
    dynamic updatedAt,
  }) {
    return CampaignPopupModel(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      titleUrdu: titleUrdu ?? this.titleUrdu,
      detailsEnglish: detailsEnglish ?? this.detailsEnglish,
      detailsUrdu: detailsUrdu ?? this.detailsUrdu,
      buttonTextEnglish: buttonTextEnglish ?? this.buttonTextEnglish,
      buttonTextUrdu: buttonTextUrdu ?? this.buttonTextUrdu,
      targetRoute: targetRoute ?? this.targetRoute,
      imageType: imageType ?? this.imageType,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

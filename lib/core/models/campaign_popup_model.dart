import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignPopupModel {
  static const String defaultTargetRoute = '/counter';
  static const String imageTypeUrl = 'url';
  static const String imageTypeBase64 = 'base64';

  final String id;
  final bool isActive;
  final bool showActionButton;
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
    this.showActionButton = true,
    this.titleEnglish = 'Global Durood Campaign',
    this.titleUrdu = 'خصوصی مہم برائے درود پاک',
    this.detailsEnglish =
        'Join thousands of believers worldwide in sending Salawat upon the Beloved Prophet ﷺ today.',
    this.detailsUrdu =
        'آج ہی حضور نبی اکرم ﷺ کی بارگاہِ اقدس میں صلوات و سلام کا نذرانہ پیش کریں اور عالمی مہم کا حصہ بنیں۔',
    this.buttonTextEnglish = 'Recite Now',
    this.buttonTextUrdu = 'شرکت کریں',
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
    return titleEnglish.isNotEmpty ? titleEnglish : 'Global Durood Campaign';
  }

  String getDetails(bool isUrdu) {
    if (isUrdu && detailsUrdu.trim().isNotEmpty) {
      return detailsUrdu;
    }
    return detailsEnglish.isNotEmpty
        ? detailsEnglish
        : 'Join thousands of believers worldwide in sending Salawat upon the Beloved Prophet ﷺ today.';
  }

  String getButtonText(bool isUrdu) {
    if (isUrdu && buttonTextUrdu.trim().isNotEmpty) {
      return buttonTextUrdu;
    }
    return buttonTextEnglish.isNotEmpty ? buttonTextEnglish : 'Recite Now';
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'showActionButton': showActionButton,
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
    final showActionButton = (map['showActionButton'] ?? map['show_action_button'] ?? true) as bool? ?? true;
    final titleEn = (map['titleEnglish'] ?? map['title_en'] ?? map['title'] ?? map['heading']) as String? ?? 'Global Durood Campaign';
    final titleUr = (map['titleUrdu'] ?? map['title_ur'] ?? map['heading_ur'] ?? '') as String? ?? 'خصوصی مہم برائے درود پاک';
    final detailsEn = (map['detailsEnglish'] ?? map['details_en'] ?? map['details'] ?? map['body_en'] ?? map['message'] ?? map['body'] ?? map['description']) as String? ??
        'Join thousands of believers worldwide in sending Salawat upon the Beloved Prophet ﷺ today.';
    final detailsUr = (map['detailsUrdu'] ?? map['details_ur'] ?? map['body_ur'] ?? map['message_ur'] ?? map['description_ur'] ?? '') as String? ??
        'آج ہی حضور نبی اکرم ﷺ کی بارگاہِ اقدس میں صلوات و سلام کا نذرانہ پیش کریں اور عالمی مہم کا حصہ بنیں۔';
    final btnEn = (map['buttonTextEnglish'] ?? map['button_text_en'] ?? map['buttonText'] ?? map['cta_text'] ?? 'Recite Now') as String;
    final btnUr = (map['buttonTextUrdu'] ?? map['button_text_ur'] ?? 'شرکت کریں') as String;
    final targetRoute = (map['targetRoute'] ?? map['target_route'] ?? defaultTargetRoute) as String;
    final imageType = (map['imageType'] ?? map['image_type'] ?? imageTypeUrl) as String;
    final imageUrl = (map['imageUrl'] ?? map['image_url']) as String?;
    final imageBase64 = (map['imageBase64'] ?? map['image_base64']) as String?;
    final updatedAt = map['updatedAt'] ?? map['updated_at'];

    return CampaignPopupModel(
      id: id,
      isActive: isActive,
      showActionButton: showActionButton,
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
      showActionButton: true,
      titleEnglish: 'Global Durood Campaign',
      titleUrdu: 'خصوصی مہم برائے درود پاک',
      detailsEnglish:
          'Join thousands of believers worldwide in sending Salawat upon the Beloved Prophet ﷺ today.',
      detailsUrdu:
          'آج ہی حضور نبی اکرم ﷺ کی بارگاہِ اقدس میں صلوات و سلام کا نذرانہ پیش کریں اور عالمی مہم کا حصہ بنیں۔',
      buttonTextEnglish: 'Recite Now',
      buttonTextUrdu: 'شرکت کریں',
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
    bool? showActionButton,
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
      showActionButton: showActionButton ?? this.showActionButton,
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

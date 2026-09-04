class TeamMember {
  final String name;
  final String nameUr;
  final String role;
  final String roleUr;
  final String category; // 'IT TEAM' or 'ISLAMIC RESEARCH TEAM'
  final String? imagePath;
  final String tag;
  final String tagUr;
  final String? description;
  final String? descriptionUr;

  const TeamMember({
    required this.name,
    required this.nameUr,
    required this.role,
    required this.roleUr,
    required this.category,
    this.imagePath,
    required this.tag,
    required this.tagUr,
    this.description,
    this.descriptionUr,
  });

  static const List<TeamMember> itTeam = [
    TeamMember(
      name: 'Dawood Ahmad',
      nameUr: 'داؤد احمد',
      role: 'Project Manager',
      roleUr: 'پروجیکٹ مینیجر',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/dawood.png',
      tag: 'MANAGEMENT',
      tagUr: 'انتظامیہ',
      description: 'Oversees engineering delivery, project milestones, and ensures strict quality standards across all modules.',
      descriptionUr: 'پروجیکٹ کے انتظام اور تکنیکی کاموں کی بروقت اور معیاری تکمیل کے نگران۔',
    ),
    TeamMember(
      name: 'Hassan Awan',
      nameUr: 'حسن اعوان',
      role: 'Developer',
      roleUr: 'ڈیولپمنٹ',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/hassan.png',
      tag: 'DEVELOPMENT',
      tagUr: 'ڈویلپر',
      description: 'Full-stack Flutter & Firebase engineer developing core features, cloud architecture, and real-time syncing.',
      descriptionUr: 'فلٹر اور فائر بیس ڈیولپر جو ایپ کے بنیادی فیچرز اور کلاؤڈ آرکیٹیکچر پر کام کرتے ہیں۔',
    ),
    TeamMember(
      name: 'Muhammad Asim',
      nameUr: 'محمد عاصم',
      role: 'Graphic Designer',
      roleUr: 'گرافک ڈیزائنر',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/asim.png',
      tag: ' DESIGN',
      tagUr: ' ڈیزائن',
      description: 'Creates brand identity, spiritual visual artwork, illustrations, and campaign visual aesthetics.',
      descriptionUr: 'روحانی بصری فن، گرافکس اور برانڈ ڈیزائن کی تخلیق۔',
    ),
    TeamMember(
      name: 'Ahtesham',
      nameUr: 'احتشام',
      role: 'UI/UX Designer',
      roleUr: 'یو آئی / یو ایکس ڈیزائنر',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/ahtesham.png',
      tag: 'PRODUCT DESIGN',
      tagUr: 'پراڈکٹ ڈیزائن',
      description: 'Lead UI/UX Designer dedicated to shaping seamless product architecture, engaging visual interfaces, and accessible spiritual journeys.',
      descriptionUr: 'پراڈکٹ ڈیزائنر جو بہترین یوزر انٹرفیس اور روحانی سفر کے لیے آسان اور پرکشش ڈیجیٹل تجربات تخلیق کرتے ہیں۔',
    ),
  ];

  static const List<TeamMember> islamicResearchTeam = [
    TeamMember(
      name: 'Muhammad Ibrahim',
      nameUr: 'محمد ابراہیم عطاری',
      role: 'Research Head',
      roleUr: 'نگرانِ تحقیق',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/ibrahim.png',
      tag: 'HEAD',
      tagUr: ' تحقیق',
      description: 'Supervises authenticity and scholarly verification of Hadith, Quranic references, and Aqaid & Masail content.',
      descriptionUr: 'احادیث، قرآنی حوالہ جات اور عقائد و مسائل کی تحقیق اور علمی تصدیق کے نگران۔',
    ),

    TeamMember(
      name: 'Haroon Qadri',
      nameUr: 'ہارون قادری',
      role: 'Content Researcher',
      roleUr: 'ریسرچر',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/haroon.png',
      tag: 'RESEARCHER',
      tagUr: 'تحقیق',
      description: 'Researches classical Islamic texts and curates daily spiritual wisdom, Duas, and authentic Salawat narrations.',
      descriptionUr: 'مستند اسلامی کتب کی تحقیق، روزانہ کے اذکار، دعائیں اور درود پاک کے فضائل کے محقق۔',
    ),

    TeamMember(
      name: 'Muhammad Awais',
      nameUr: 'محمد اویس',
      role: 'Content Researcher',
      roleUr: 'ریسرچر',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/awais.png',
      tag: 'RESEARCHER',
      tagUr: 'تحقیق',
      description: 'Specializes in verification of historical events, Seerah narratives, and scholarly answers to user inquiries.',
      descriptionUr: 'سیرت النبی، تاریخی واقعات اور صارفین کے سوالات کے علمی جوابات کی تصدیق۔',
    ),

    TeamMember(
      name: 'Dawood Ahmad',
      nameUr: 'داؤد احمد',
      role: 'Content Researcher',
      roleUr: 'ریسرچر',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/dawood.png',
      tag: 'RESEARCHER',
      tagUr: 'تحقیق',
      description: 'Coordinates research documentation, translation review, and Islamic literature quality assurance.',
      descriptionUr: 'تحقیقی مواد کی تدوین، ترجمے کی جانچ اور علمی ہم آہنگی کے معاون۔',
    ),
  ];

  static const List<TeamMember> allMembers = [
    ...itTeam,
    ...islamicResearchTeam,
  ];
}

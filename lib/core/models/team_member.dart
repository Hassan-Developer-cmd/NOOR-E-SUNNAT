class TeamMember {
  final String name;
  final String nameUr;
  final String role;
  final String roleUr;
  final String category; // 'IT TEAM' or 'ISLAMIC RESEARCH TEAM'
  final String? imagePath;
  final String tag;
  final String tagUr;

  const TeamMember({
    required this.name,
    required this.nameUr,
    required this.role,
    required this.roleUr,
    required this.category,
    this.imagePath,
    required this.tag,
    required this.tagUr,
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
    ),
  ];

  static const List<TeamMember> allMembers = [
    ...itTeam,
    ...islamicResearchTeam,
  ];
}

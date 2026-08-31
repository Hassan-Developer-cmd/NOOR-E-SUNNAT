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
      roleUr: 'سافٹ ویئر ڈویلپر',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/hassan.png',
      tag: 'DEVELOPER',
      tagUr: 'ڈویلپر',
    ),
    TeamMember(
      name: 'Muhammad Asim',
      nameUr: 'محمد عاصم',
      role: 'Graphic Designer',
      roleUr: 'گرافک ڈیزائنر',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/asim.png',
      tag: 'VISUAL DESIGN',
      tagUr: 'بصری ڈیزائن',
    ),
    TeamMember(
      name: 'Ahtesham',
      nameUr: 'احتشام',
      role: 'UI/UX Designer',
      roleUr: 'یو آئی / یو ایکس ڈیزائنر',
      category: 'IT TEAM',
      imagePath: 'assets/images/team/ahtesham.png',
      tag: 'PRODUCT DESIGNER',
      tagUr: 'پروڈکٹ ڈیزائنر',
    ),
  ];

  static const List<TeamMember> islamicResearchTeam = [
    TeamMember(
      name: 'Muhammad Ibrahim Attari',
      nameUr: 'محمد ابراہیم عطاری',
      role: 'Research Head',
      roleUr: 'ہیڈ آف ریسرچ',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/ibrahim.png',
      tag: 'HEAD SCHOLAR',
      tagUr: 'نگرانِ تحقیق',
    ),
    TeamMember(
      name: 'Muhammad Awais',
      nameUr: 'محمد اویس',
      role: 'Content Researcher',
      roleUr: 'ریسرچ اسکالر',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/awais.png',
      tag: 'RESEARCHER',
      tagUr: 'محقق',
    ),
    TeamMember(
      name: 'Haroon Qadri',
      nameUr: 'ہارون قادری',
      role: 'Content Researcher',
      roleUr: 'ریسرچ اسکالر',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/haroon.png',
      tag: 'RESEARCHER',
      tagUr: 'محقق',
    ),
    TeamMember(
      name: 'Dawood Ahmad',
      nameUr: 'داؤد احمد',
      role: 'Content Researcher',
      roleUr: 'ریسرچ اسکالر',
      category: 'ISLAMIC RESEARCH TEAM',
      imagePath: 'assets/images/team/dawood_research.png',
      tag: 'RESEARCHER',
      tagUr: 'محقق',
    ),
  ];

  static const List<TeamMember> allMembers = [
    ...itTeam,
    ...islamicResearchTeam,
  ];
}

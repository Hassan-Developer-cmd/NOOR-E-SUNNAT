import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/question_model.dart';
import '../../../main.dart';
import '../../../services/questions_service.dart';
import 'ask_question_sheet.dart';

/// Dedicated Q&A screen for exploring public Islamic answers & submitting inquiries.
class QAScreen extends StatefulWidget {
  final int initialTabIndex;
  const QAScreen({super.key, this.initialTabIndex = 0});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  String _myStatusFilter = 'all'; // 'all' | 'pending' | 'answered'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'en': 'All Categories', 'ur': 'تمام موضوعات'},
    {'id': 'namaz', 'en': 'Namaz (Prayer)', 'ur': 'نماز'},
    {'id': 'wuzu', 'en': 'Wuzu & Taharat', 'ur': 'وضو و طہارت'},
    {'id': 'roza', 'en': 'Roza (Fasting)', 'ur': 'روزہ'},
    {'id': 'zakat', 'en': 'Zakat & Charity', 'ur': 'زکوٰۃ'},
    {'id': 'hajj', 'en': 'Hajj & Umrah', 'ur': 'حج و عمرہ'},
    {'id': 'aqaid', 'en': 'Aqaid (Beliefs)', 'ur': 'عقائد'},
    {'id': 'nikah', 'en': 'Nikah & Family', 'ur': 'نکاح و خاندانی مسائل'},
    {'id': 'taharat', 'en': 'Taharat (Purity)', 'ur': 'طہارت'},
    {'id': 'general', 'en': 'General Inquiries', 'ur': 'متفرق مسائل'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 220,
              backgroundColor: AppColors.primaryEmerald,
              elevation: 0,
              title: Text(
                isUrdu ? 'شرعی سوال و جواب' : 'Islamic Q&A',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                // Ask Question Action
                IconButton(
                  tooltip: isUrdu ? 'نیا سوال پوچھیں' : 'Ask a Question',
                  icon: const Icon(Icons.add_comment_rounded),
                  onPressed: () => AskQuestionSheet.show(context),
                ),
                // Language Switcher
                IconButton(
                  tooltip: isUrdu ? 'Switch to English' : 'اردو میں دیکھیں',
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUrdu ? 'EN' : 'اردو',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  onPressed: () => lp.toggleLanguage(),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Decorative Gradient & Circle
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryEmerald, Color(0xFF0F5132)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu
                                ? 'مستند علمائے کرام سے شرعی رہنمائی حاصل کریں'
                                : 'Verified Islamic Inquiries & Fatwas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isUrdu
                                ? 'اپنا سوال جمع کروائیں یا تصدیق شدہ جوابات تلاش کریں'
                                : 'Ask questions or browse through community answered inquiries with 24-hour response SLA.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  height: 48,
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryEmerald,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryEmerald,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                    tabs: [
                      Tab(
                        height: 48,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(isUrdu ? 'عمومی سوالات' : 'Public Q&A'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mark_chat_unread_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text(isUrdu ? 'میرے سوالات' : 'My Inquiries'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ];
        },
        body: Column(
          children: [
            // Search Input Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: isUrdu
                          ? 'سوالات، فتاویٰ یا مسائل تلاش کریں...'
                          : 'Search questions, fatwas, or topics...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primaryEmerald),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.bgOffWhite,
                    ),
                  ),

                  // Category Filter Horizontal Row (for Public Tab)
                  if (_tabController.index == 0) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              selected: isSelected,
                              selectedColor: AppColors.primaryEmerald,
                              backgroundColor: AppColors.bgOffWhite,
                              label: Text(
                                isUrdu ? cat['ur']! : cat['en']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? cat['id']! : 'all';
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Status Filter Chips (for My Inquiries Tab)
                  if (_tabController.index == 1) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildStatusFilterChip('all', isUrdu ? 'تمام سوالات' : 'All'),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip('pending', isUrdu ? 'زیرِ غور (24h)' : 'Pending (24h)'),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip('answered', isUrdu ? 'جواب دیا گیا' : 'Answered'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tab View Body

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Public Answered Questions
                  _buildPublicQuestionsView(isUrdu),

                  // Tab 2: User's Own Inquiries
                  _buildMyInquiriesView(userId, isUrdu),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => AskQuestionSheet.show(context),
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(isUrdu ? 'سوال پوچھیں' : 'Ask Question'),
      ),
    );
  }

  Widget _buildStatusFilterChip(String value, String label) {
    final isSelected = _myStatusFilter == value;
    return FilterChip(
      selected: isSelected,
      selectedColor: AppColors.primaryEmerald,
      backgroundColor: AppColors.bgOffWhite,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _myStatusFilter = selected ? value : 'all';
        });
      },
    );
  }

  // ── Tab 1: Public Verified Islamic Inquiries ────────────────────

  Widget _buildPublicQuestionsView(bool isUrdu) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionsService.publicAnsweredQuestionsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
        }

        final allItems = snap.data ?? [];
        final query = _searchQuery.toLowerCase().trim();

        final filtered = allItems.where((q) {
          final matchesCategory = _selectedCategory == 'all' ||
              q.category.toLowerCase().contains(_selectedCategory.toLowerCase());

          final matchesSearch = query.isEmpty ||
              q.question.toLowerCase().contains(query) ||
              q.category.toLowerCase().contains(query) ||
              (q.answer != null && q.answer!.toLowerCase().contains(query));

          return matchesCategory && matchesSearch;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.quiz_outlined,
            title: isUrdu ? 'کوئی عمومی سوال نہیں ملا' : 'No Public Questions Found',
            subtitle: isUrdu
                ? 'براہ کرم سرچ کیورڈ تبدیل کریں یا دوسرا موضوع منتخب کریں۔'
                : 'Try adjusting your search query or choosing another category filter.',
            actionLabel: isUrdu ? 'نیا سوال پوچھیں' : 'Ask a Question',
            onAction: () => AskQuestionSheet.show(context),
            isUrdu: isUrdu,
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final q = filtered[index];
            return _QAAnswerCard(question: q, isUrdu: isUrdu);
          },
        );
      },
    );
  }

  // ── Tab 2: Personal Inquiries & 24h SLA ─────────────────────────

  Widget _buildMyInquiriesView(String userId, bool isUrdu) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionsService.getUserQuestionsStream(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
        }

        final allQuestions = snap.data ?? [];
        final query = _searchQuery.toLowerCase().trim();

        final filtered = allQuestions.where((q) {
          final matchesFilter = _myStatusFilter == 'all' ||
              (_myStatusFilter == 'pending' && q.isPending) ||
              (_myStatusFilter == 'answered' && q.isAnswered);

          final matchesSearch = query.isEmpty ||
              q.question.toLowerCase().contains(query) ||
              q.category.toLowerCase().contains(query) ||
              (q.answer != null && q.answer!.toLowerCase().contains(query));

          return matchesFilter && matchesSearch;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: isUrdu ? 'کوئی ذاتی سوال موجود نہیں ہے' : 'No Inquiries Submitted Yet',
            subtitle: isUrdu
                ? 'آپ کا جو بھی شرعی سوال ہو، بلا جھجھک پوچھیں۔ ایڈمن و علمائے کرام 24 گھنٹوں میں تصدیق شدہ جواب فراہم کریں گے۔'
                : 'Ask your religious inquiries directly. Our administration team will review and reply within 24 hours.',
            actionLabel: isUrdu ? 'نیا سوال پوچھیں' : 'Ask Your First Question',
            onAction: () => AskQuestionSheet.show(context),
            isUrdu: isUrdu,
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final q = filtered[index];
            return _QAAnswerCard(question: q, isUrdu: isUrdu, showStatusHeader: true);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isUrdu,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.emeraldContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primaryEmerald),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: onAction,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rich Question & Answer Card Widget ─────────────────────────────

class _QAAnswerCard extends StatelessWidget {
  final QuestionModel question;
  final bool isUrdu;
  final bool showStatusHeader;

  const _QAAnswerCard({
    required this.question,
    required this.isUrdu,
    this.showStatusHeader = false,
  });

  void _confirmDeleteQuestion(BuildContext context, String questionId, bool isUrdu) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              isUrdu ? 'سوال حذف کریں' : 'Delete Question',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          isUrdu
              ? 'کیا آپ واقعی اس سوال کو حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں لیا جا سکتا۔'
              : 'Are you sure you want to permanently delete this question? This action cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? 'منسوخ کریں' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await QuestionsService.deleteQuestion(questionId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isUrdu ? 'سوال کامیابی سے حذف ہو گیا' : 'Question deleted successfully'),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isUrdu ? 'حذف کرنے میں خرابی پیش آئی' : 'Failed to delete question'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isUrdu ? 'حذف کریں' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isPending = question.isPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppColors.goldDark.withValues(alpha: 0.3) : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pill & Status Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: isPending ? const Color(0xFFFEF9C3) : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                // Category Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.goldLight : AppColors.emeraldContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isUrdu
                        ? QuestionModel.getCategoryUrdu(question.category)
                        : question.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPending ? AppColors.goldDark : AppColors.primaryEmerald,
                    ),
                  ),

                ),
                const Spacer(),

                // Status Badge
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE047),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFF854D0E)),
                        const SizedBox(width: 4),
                        Text(
                          isUrdu ? 'زیرِ غور (24 گھنٹے)' : 'Pending (24h SLA)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF854D0E),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF166534)),
                        const SizedBox(width: 4),
                        Text(
                          isUrdu ? 'تصدیق شدہ جواب' : 'Verified Answer',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showStatusHeader) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    tooltip: isUrdu ? 'سوال حذف کریں' : 'Delete Question',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: () => _confirmDeleteQuestion(context, question.id, isUrdu),
                  ),
                ],
              ],
            ),
          ),


          // Question Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.primaryEmerald),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Answer Section or Pending Notice
                if (isPending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isUrdu
                                ? 'آپ کا سوال ایڈمن کے پاس زیرِ جائزہ ہے۔ 24 گھنٹے کے اندر جواب یہاں موصول ہو جائے گا۔'
                                : 'Your question is under review. Our scholars will provide a verified answer within 24 hours.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgOffWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 15, color: AppColors.primaryEmerald),
                            const SizedBox(width: 6),
                            Text(
                              isUrdu ? 'شرعی جواب:' : 'Scholarly Answer:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question.answer ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // Footer Row with date & copy action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      question.createdAt != null
                          ? '${question.createdAt!.day}/${question.createdAt!.month}/${question.createdAt!.year}'
                          : '',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (!isPending && question.answer != null)
                      InkWell(
                        onTap: () {
                          final text = 'Q: ${question.question}\n\nA: ${question.answer}';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isUrdu ? 'جواب کاپی ہو گیا!' : 'Q&A copied to clipboard!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.primaryEmerald,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.copy_rounded, size: 13, color: AppColors.primaryEmerald),
                              const SizedBox(width: 4),
                              Text(
                                isUrdu ? 'کاپی کریں' : 'Copy',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryEmerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/question_model.dart';
import '../../../main.dart';
import '../../../services/questions_service.dart';
import 'ask_question_sheet.dart';

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  String _selectedFilter = 'all'; // 'all' | 'pending' | 'answered'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      appBar: AppBar(
        title: Text(isUrdu ? 'میرے سوالات و استفسارات' : 'My Questions & Q&A'),
        backgroundColor: AppColors.primaryEmerald,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: isUrdu ? 'نیا سوال پوچھیں' : 'Ask a Question',
            onPressed: () => AskQuestionSheet.show(context),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        ],
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: QuestionsService.getUserQuestionsStream(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
          }

          final allQuestions = snap.data ?? [];
          final filtered = allQuestions.where((q) {
            final matchesFilter = _selectedFilter == 'all' ||
                (_selectedFilter == 'pending' && q.isPending) ||
                (_selectedFilter == 'answered' && q.isAnswered);

            final query = _searchQuery.toLowerCase();
            final matchesSearch = query.isEmpty ||
                q.question.toLowerCase().contains(query) ||
                q.category.toLowerCase().contains(query) ||
                (q.answer != null && q.answer!.toLowerCase().contains(query));

            return matchesFilter && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: isUrdu ? 'اپنے سوالات میں تلاش کریں...' : 'Search my questions...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryEmerald),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
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
                        filled: true,
                        fillColor: AppColors.bgOffWhite,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: isUrdu ? 'تمام سوالات (${allQuestions.length})' : 'All (${allQuestions.length})',
                            value: 'all',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: isUrdu
                                ? 'زیرِ غور (${allQuestions.where((q) => q.isPending).length})'
                                : 'Pending (${allQuestions.where((q) => q.isPending).length})',
                            value: 'pending',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: isUrdu
                                ? 'جواب شدہ (${allQuestions.where((q) => q.isAnswered).length})'
                                : 'Answered (${allQuestions.where((q) => q.isAnswered).length})',
                            value: 'answered',
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

              // Questions List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldContainer.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 40,
                                  color: AppColors.primaryEmerald,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isUrdu ? 'کوئی سوال موجود نہیں ہے' : 'No questions found',
                                style: AppTypography.headingMedium.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isUrdu
                                    ? 'آپ اپنا نیا سوال جمع کروا سکتے ہیں، 24 گھنٹے میں جواب مل جائے گا۔'
                                    : 'Ask your questions directly to the admin team and receive verified answers within 24 hours.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryEmerald,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () => AskQuestionSheet.show(context),
                                icon: const Icon(Icons.add_comment_rounded, size: 18),
                                label: Text(isUrdu ? 'نیا سوال پوچھیں' : 'Ask a Question'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final q = filtered[index];
                          return _QuestionCard(question: q, isUrdu: isUrdu);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        foregroundColor: Colors.white,
        onPressed: () => AskQuestionSheet.show(context),
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(isUrdu ? 'سوال پوچھیں' : 'Ask Question'),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      selectedColor: AppColors.primaryEmerald,
      backgroundColor: AppColors.bgOffWhite,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final bool isUrdu;

  const _QuestionCard({required this.question, required this.isUrdu});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _isExpanded = false;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isUrdu = widget.isUrdu;
    final isAnswered = q.isAnswered;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered ? AppColors.primaryEmerald.withValues(alpha: 0.3) : AppColors.borderLight,
          width: isAnswered ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUrdu ? QuestionModel.getCategoryUrdu(q.category) : q.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAnswered ? AppColors.emeraldContainer : AppColors.goldLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAnswered ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            size: 13,
                            color: isAnswered ? AppColors.primaryEmerald : AppColors.goldDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAnswered
                                ? (isUrdu ? 'جواب دیا گیا ✅' : 'Answered ✅')
                                : (isUrdu ? 'زیرِ غور (24 گھنٹے میں جواب)' : 'Pending (Within 24h)'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAnswered ? AppColors.primaryEmerald : AppColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question Text
                Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Footer Row: Date & Expand indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (q.createdAt != null)
                      Text(
                        isUrdu ? 'ارسال: ${_formatDate(q.createdAt)}' : 'Asked on ${_formatDate(q.createdAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    Row(
                      children: [
                        Text(
                          _isExpanded
                              ? (isUrdu ? 'کم دکھائیں' : 'Show less')
                              : (isAnswered
                                  ? (isUrdu ? 'جواب پڑھیں' : 'Read answer')
                                  : (isUrdu ? 'تفصیل دیکھیں' : 'View details')),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAnswered ? AppColors.primaryEmerald : Colors.grey.shade600,
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isAnswered ? AppColors.primaryEmerald : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                ),

                // Expanded Section
                if (_isExpanded) ...[
                  const Divider(height: 20),
                  if (isAnswered && q.answer != null && q.answer!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded, size: 16, color: AppColors.primaryEmerald),
                                  const SizedBox(width: 6),
                                  Text(
                                    isUrdu ? 'ایڈمن / مفتی کا تصدیق شدہ جواب' : 'Official Admin Answer',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              if (q.answeredAt != null)
                                Text(
                                  _formatDate(q.answeredAt),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q.answer!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (q.answeredBy != null && q.answeredBy!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              isUrdu ? 'جواب دہندہ: ${q.answeredBy}' : 'Answered by: ${q.answeredBy}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: AppColors.goldDark, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isUrdu
                                  ? 'آپ کا سوال موصول ہو چکا ہے۔ ایڈمن ٹیم 24 گھنٹوں کے اندر جواب فراہم کرے گی۔'
                                  : 'Your question has been received. Admin team will respond within 24 hours.',
                              style: const TextStyle(fontSize: 12, color: AppColors.goldDark, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/question_model.dart';
import '../../../main.dart';
import '../../../services/questions_service.dart';
import 'ask_question_sheet.dart';

/// Simplified Q&A screen displaying the user's questions & verified answers.
class QAScreen extends StatefulWidget {
  final int initialTabIndex;
  const QAScreen({super.key, this.initialTabIndex = 0});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  String _selectedFilter = 'all'; // 'all' | 'pending' | 'answered'
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openAskQuestionModal(BuildContext context) {
    AskQuestionSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;
        String userId = 'guest';
        try {
          userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
        } catch (_) {
          userId = 'guest';
        }

        return Directionality(
          textDirection: lp.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.bgOffWhite,
            appBar: AppBar(
              backgroundColor: AppColors.primaryEmerald,
              elevation: 0,
              centerTitle: false,
              title: Text(
                lp.tr('my_questions_title'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: lp.tr('ask_question'),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => AskQuestionSheet.show(context),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12, start: 4),
                    child: InkWell(
                      onTap: () => lp.toggleLanguage(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isUrdu ? 'EN' : 'اردو',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Search & Filter Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (v) {
                          setState(() {
                            _searchQuery = v.trim();
                          });
                        },
                        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: lp.tr('search_my_questions_hint'),
                          hintTextDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
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
                      const SizedBox(height: 10),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: lp.tr('filter_all'),
                              value: 'all',
                              isSelected: _selectedFilter == 'all',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: lp.tr('filter_pending'),
                              value: 'pending',
                              isSelected: _selectedFilter == 'pending',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: lp.tr('filter_answered'),
                              value: 'answered',
                              isSelected: _selectedFilter == 'answered',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Questions List Stream
                Expanded(
                  child: StreamBuilder<List<QuestionModel>>(
                    stream: QuestionsService.getUserQuestionsStream(userId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
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

                      if (filtered.isEmpty) {
                        return Center(
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
                                  lp.tr('no_questions_found'),
                                  style: AppTypography.headingMedium.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lp.tr('no_questions_desc'),
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
                                  label: Text(lp.tr('ask_question')),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final q = filtered[index];
                          return _QuestionCard(question: q, isUrdu: isUrdu);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openAskQuestionModal(context),
              backgroundColor: const Color(0xFF0F6848),
              elevation: 4,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
              label: Text(
                isUrdu ? 'سوال پوچھیں' : 'Ask Question',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return FilterChip(
      selected: isSelected,
      selectedColor: AppColors.primaryEmerald,
      backgroundColor: AppColors.bgOffWhite,
      checkmarkColor: Colors.white,
      showCheckmark: isSelected,
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

  void _confirmDeleteQuestion(BuildContext context, String questionId, bool isUrdu) {
    final lp = globalLanguageProvider;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: lp.textDirection,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Text(
                lp.tr('delete_question'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            lp.tr('delete_question_confirm'),
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lp.tr('cancel')),
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
                  await QuestionsService.deleteUserQuestion(questionId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lp.tr('question_deleted_success')),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete question: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(lp.tr('delete')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isUrdu = widget.isUrdu;
    final lp = globalLanguageProvider;
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
          onTap: isAnswered ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category, Status Badge & Delete Button
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

                    // Status Pill & Delete Button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                isAnswered ? lp.tr('status_answered') : lp.tr('status_pending_24h'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAnswered ? AppColors.primaryEmerald : AppColors.goldDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          tooltip: lp.tr('delete_question'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                          onPressed: () => _confirmDeleteQuestion(context, q.id, isUrdu),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question Text
                Text(
                  q.question,
                  style: TextStyle(
                    fontSize: isUrdu ? 15.5 : 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: isUrdu ? 1.5 : 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Footer Row: Date & Read Answer Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lp.tr('asked_on')} ${_formatDate(q.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (isAnswered) ...[
                      InkWell(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isExpanded ? lp.tr('hide_answer') : lp.tr('read_answer'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.primaryEmerald,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Expanded Answer Box
                if (_isExpanded && isAnswered && q.answer != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.primaryEmerald),
                            const SizedBox(width: 6),
                            Text(
                              lp.tr('official_answer'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.answer!,
                          style: TextStyle(
                            fontSize: isUrdu ? 15 : 13.5,
                            height: isUrdu ? 1.6 : 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (q.answeredBy != null && q.answeredBy!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '— ${q.answeredBy}',
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
